class Users::SessionsController < Devise::SessionsController

  prepend_before_filter :_require_business_or_mfe, :only => [ :new, :create, :authorize, :google_oauth2, :destroy ]

  skip_before_filter :authenticate_user!, :only => [:new, :create, :authorize, :google_oauth2]
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :create, :authorize, :google_oauth2, :destroy]

  class NoopApp
    def call(env); end;
  end

  def authorize
    if current_user
      redirect_to after_sign_in_path_for(current_user)
      return
    end

    status, headers, response = middleware.call(request.env)

    response.status = status
    headers.each do |k,v|
      response.headers[k] = v
    end

    redirect_to headers["Location"]
  end

	def google_oauth2
    status, headers, response = middleware.call(request.env)

    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)

    if @user && @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_session_path
    end
	end

  def destroy
    sign_out(current_user)
    redirect_to business_path
  end

  protected

  def middleware
    key_obj = @current_mfe ? @current_mfe : @current_business
    OmniAuth::Strategies::GoogleOauth2.new(NoopApp.new, key_obj.send(:google_oauth2_client_id), key_obj.send(:google_oauth2_client_secret), {
                                                          :path_prefix => '/users/auth',
                                                          :scope => MikedllCrm::Configuration.get('google_oauth2_scope'),
                                                          :approval_prompt => "auto"
    })    
  end

  
end
