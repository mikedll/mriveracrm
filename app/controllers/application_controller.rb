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

  before_filter :authenticate_user!

  before_filter :require_business_and_current_user_belongs_to_it
  before_filter :configure_theme
  before_filter :_detect_business_via_mfe

  around_filter :business_keys

  def current_business
    @current_business ||= Business.find_by_domain (Rails.env.development? ? 'www.mikedll.com' : request.host )
  end

  def require_business_and_current_user_belongs_to_it
    if current_business.nil?
      head :forbidden
    else
      Business.current = current_business
      if user_signed_in? && !current_user.cb?
        head :forbidden      
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

  def _detect_business_via_mfe
    @business_via_mfe = true if @current_business && params[:business_handle]
  end


end
