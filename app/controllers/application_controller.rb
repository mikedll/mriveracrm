# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e174a43326b3dbe4f8bbf3975fc99b94'
  
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

  around_filter :business_keys

  attr_accessor :current_business, :current_mfe

  def require_business_and_current_user_belongs_to_it
    if current_business.nil?
      Business.current = nil

      if current_user
        # theyre in the wrong place, but a route trigger. raise
        # not found.
        # them somewhere useful.
        flash[:notice] = I18n.t('errors.not_found_redirect_home')
        redirect_to after_sign_in_path_for(current_user)
      else
        # not logged in and no business. nothing here.
        respond_to do |format|
          format.html { redirect_to root_path }
          format.js { head :not_found }        
        end
      end
    else
      Business.current = current_business
      if user_signed_in? && !current_user.cb?
        # user trying to access a business that isnt theirs
        # we dont redirect them because we dont
        # know their business' url form, or the mfe form.
        # we may handle this later.
        head :not_found
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
      flash[:error] = I18n.t('errors.no_access')
      redirect_to new_user_session_path
    end
  end

  def require_client
    if current_user.client.nil?
      flash[:error] = I18n.t('errors.no_access')
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
    if @business_via_mfe
      { :business_handle => @current_business.handle }.merge(super)
    else
      super
    end
  end

  protected 

  def force_www
    return if Rails.env.development? # doesnt work with port 3000
    redirect_to :host => 'www.' + request.host if request.host !~ /^www\./
  end

  def ssl_required?
    false
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

    @current_business = Business.find_by_host request.host

    if @current_business.nil?
      @current_mfe = MarketingFrontEnd.find_by_host request.host
      if @current_mfe
        RequestSettings.host = @current_mfe.host

        if params[:business_handle]
          @current_business = Business.find_by_handle params[:business_handle] 
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
    else
      RequestSettings.host = @current_business.host
    end

    RequestSettings.port = 3000 if Rails.env.development? # yeek.


    raise "Programmer error: neither mfe or business found." if (!current_business && !current_mfe)
  end


end
