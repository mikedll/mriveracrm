# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  include ActionView::Helpers::TranslationHelper

  protect_from_forgery

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # filter_parameter_logging :password

  before_filter :force_www
  before_filter :_enforce_ssl
  before_filter :_require_business_or_mfe

  before_filter :authenticate_user!

  before_filter :require_business_and_current_user_belongs_to_it
  before_filter :configure_theme

  before_filter :_clear_sessions_business_handle

  around_filter :business_keys

  attr_accessor :current_business, :current_mfe

  def require_business_and_current_user_belongs_to_it
    if current_business.nil?
      if current_user
        # theyre in the wrong place, but a route trigger. raise
        # not found.
        # them somewhere useful.
        respond_to do |format|
          format.html do
            flash[:notice] = t('errors.not_found_redirect_home')
            redirect_to after_sign_in_path_for(current_user)
          end
          format.js { head :not_found }
        end
      else
        # not logged in and no business. nothing here.
        respond_to do |format|
          format.html { redirect_to root_path }
          format.js { head :not_found }
        end
      end
    else
      if user_signed_in? && !current_user.cb?

        # user trying to access a business that isnt theirs
        if @current_mfe
          flash[:notice] = t('errors.not_found_redirect_home')
          redirect_to business_path(:business_handle => current_user.business.handle)
        elsif @current_business
          # severe violation at wrong url for wrong business domain
          # redirect to user's actual business domain.
          # we show not_found to avoid showing what drive's
          # the violated user's domain.
          head :not_found
        else
          head :not_found
        end
      end
    end
  end

  def configure_theme
    # @theme = "standard" if !@current_business.nil?
  end


  # Supposed to be used for business key loading/unloading,
  # but we're doing that in the controllers now.
  def business_keys
    yield
  end


  def require_employee
    if current_user.employee.nil?
      flash[:error] = t('errors.no_access')
      redirect_to new_user_session_path
    end
  end

  def require_client
    if current_user.client.nil?
      flash[:error] = t('errors.no_access')
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      if resource.is_a?(User)
        if @current_mfe && @current_business.nil?
          @current_business = resource.business
          @business_via_mfe = true
        end

        if resource.employee
          manage_clients_path
        else
          client_invoices_path
        end
      else
        signed_in_root_path(resource)
      end
  end

  def url_options
    if @business_via_mfe && !@supress_business_handle
      { :business_handle => @current_business.handle }.merge(super)
    else
      super
    end
  end

  def after_omniauth_failure_path_for(scope)
    new_user_session_path
  end

  def authenticate_admin!
    redirect_to root_path unless current_user && current_user.is_admin?
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to business_path
  end

  protected

  def require_active_plan
    if @current_business.nil? || !@current_business.active_plan?
      flash[:error] = t('business.errors.inactive_plan_internal')
      redirect_to business_path
    end
  end

  def require_active_plan_public
    if @current_business.nil? || !@current_business.active_plan?
      flash[:error] = t('business.errors.inactive_plan_public')
      redirect_to business_path
    end
  end


  def force_www
    return if Rails.env.development? # Doesn't work with certain CRM addresses. Might not even keep this feature.

    if request.host !~ /^www\./
      s = request.protocol + 'www.' + request.host
      if Rails.env.development? # doesnt work with port 3000
        s += ":3000"
      end
      s += request.path
      redirect_to s
    end
  end

  def ssl_required?
    false
  end

  def _bsupports?(*names)
    if @current_business.nil? || !@current_business.supports?(*names)
      flash[:error] = t('business.errors.feature_not_supported')
      redirect_to business_path
      return
    end

    true
  end

  # Override in subclass as security precaution.
  def _require_business_support
    raise "Implement in subclasses."
  end

  def _enforce_ssl
    # This doesn't work in dev partially due to the port.
    if ssl_required? && !request.ssl?
      redirect_to "https://" + request.host + request.fullpath
      flash.keep
      return false
    end
  end

  def _require_business_or_mfe
    Business.current = nil
    RequestSettings.reset

    @current_business = Business.with_features.find_by_host request.host

    # Determine host
    if @current_business
      RequestSettings.host = @current_business.host
    else
      @current_mfe = MarketingFrontEnd.find_by_host request.host
      if @current_mfe
        RequestSettings.host = @current_mfe.host

        business_handle = params[:business_handle]
        if business_handle.nil? && session[:sessions_business_handle]
          # there is probably an omniauth callback action
          business_handle = session[:sessions_business_handle]
        end

        if business_handle
          @current_business = Business.find_by_handle business_handle
           if @current_business.nil?
             head :not_found
             return
           end

          @business_via_mfe = true
        end
      else
        RequestSettings.reset
        head :not_found
        return
      end
    end

    RequestSettings.port = 3000 if Rails.env.development? # yeek.

    if @current_business
      Business.current = @current_business
    end

    raise "Programmer error: neither mfe or business found." if (!current_business && !current_mfe)
  end

  def _clear_sessions_business_handle
    session.delete(:sessions_business_handle) if session[:sessions_business_handle]
  end

  def _require_mfe
    unless @current_mfe
      flash[:error] = t('path_not_found')
      redirect_to root_path
    end
  end


end
