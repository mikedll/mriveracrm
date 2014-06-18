class Users::RegistrationsController < Devise::RegistrationsController

  skip_before_filter :authenticate_user!
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :create]

  def new
    @business = Business.new
    super
  end

  #
  # Need to require a business at the same time,
  # else we can't map the user.
  #
  def create
    build_resource
    resource.become_owner_of_new_business(params[:business] ? params[:business][:handle] : nil)

    if resource.use_google_oauth_registration
      if resource.valid?
        # Doing a google oauth create
        Invitation.create!(:email => resource.email, :handle => params[:business] ? params[:business][:handle] : nil)
        redirect_to omniauth_authorize_path({:provider => :google_oauth2}.merge(params[:business] ? { 'business[handle]' => params[:business][:handle] } : {}))
        return
      else
        @business = (resource.employee && resource.employee.business) ? resource.employee.business : Business.new
        clean_up_passwords resource
        render "users/registrations/new"
        return
      end
    end

    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      @business = (resource.employee && resource.employee.business) ? resource.employee.business : Business.new
      clean_up_passwords resource
      render "users/registrations/new"
    end
  end

  def signed_in_root_path
    business_path
  end

end
