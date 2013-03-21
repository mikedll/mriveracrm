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

  skip_before_filter :authenticate_user!

  before_filter :require_business

  def current_business
    @current_business ||= Business.find_by_domain (Rails.env.development? ? 'www.mikedll.com' : request.host )
  end

  def require_business
    if current_business.nil?
      head :forbidden
    end
  end


end
