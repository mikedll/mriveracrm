class Users::SessionsController < Devise::SessionsController

  prepend_before_filter :_require_business_or_mfe, :only => [ :new, :create, :authorize, :google_oauth2, :destroy ]

  skip_before_filter :authenticate_user!, :only => [:new, :create, :authorize, :google_oauth2]
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :create, :authorize, :google_oauth2, :destroy]

  skip_before_filter :_clear_sessions_business_handle, [:new, :authorize]

  class NoopApp
    def call(env); end;
  end

  def authorize
    @supress_business_handle = true
    authorize_path_without_handle = omniauth_authorize_path

    if current_user
      redirect_to after_sign_in_path_for(current_user)
      return
    end

    if @business_via_mfe && request.path != authorize_path_without_handle
      # came here via /b/myhandle/users/auth
      session[:sessions_business_handle] = @current_business.handle

      # now going to this action again, but via /users/auth to purify for google.
      # business_handle will be saved in session for retrieval on the callback.
      redirect_to authorize_path_without_handle
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
    @supress_business_handle = true

    begin
      status, headers, response = middleware.call(request.env)
    rescue OmniAuth::Strategies::OAuth2::CallbackError => e
      flash[:error] = I18n.t('user.errors.cancelled_oauth')
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_session_path
      return
    end

    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)

    if @user && @user.persisted? && @user.errors.empty?
      @supress_business_handle = false
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      @supress_business_handle = false
      if @user && !@user.errors.full_messages.empty?
        flash[:error] = @user.errors.full_messages.join(". ")
      end
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
    provider = :google_oauth2 # may become dynamic, later...
    key_obj = @current_mfe ? @current_mfe : @current_business
    OmniAuth::Strategies::GoogleOauth2.new(NoopApp.new, key_obj.send(:google_oauth2_client_id), key_obj.send(:google_oauth2_client_secret), {
                                             :path_prefix => omniauth_authorize_path(:provider => provider).chomp("/#{provider}"),
                                             :scope => AppConfiguration.get('google_oauth2_scope'),
                                             :approval_prompt => "auto"
    })
  end

  def ssl_required?; Rails.env.production?; end

end
