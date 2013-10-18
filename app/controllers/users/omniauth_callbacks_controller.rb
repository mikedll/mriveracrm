class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # skip_before_filter :authenticate_user! # is this required?

  class NoopApp
    def call(env); end;
  end

  def authorize
    puts "*************** #{__FILE__} #{__LINE__} *************"
    puts "#{@current_business}"

    middleware = OmniAuth::Strategies::GoogleOAuth2.new(NoopApp, @current_business.google_oauth2_client_id, @current_business.google_oauth2_client_secret, {
      # :scope => 'userinfo.email,userinfo.profile,https://mail.google.com/mail/feed/atom,https://www.google.com/m8/feeds/',
      :scope => 'userinfo.email,userinfo.profile',
      :approval_prompt => "auto",
      :require => "omniauth-google-oauth2"
    })

    puts "*************** #{__FILE__} #{__LINE__} *************"
    puts "#{request.env["omniauth.auth"]}"

    middleware.call(request.env)

    puts "*************** #{__FILE__} #{__LINE__} *************"
    puts "#{request.env["omniauth.auth"]}"
  end

	def google_oauth2
    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)

    if @user && @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_session_path
    end
	end

end
