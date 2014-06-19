class Users::RegistrationsController < Devise::RegistrationsController

  skip_before_filter :authenticate_user!
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :create]
  before_filter :_require_mfe

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
        i = Invitation.new(:email => resource.email, :handle => params[:business] ? params[:business][:handle] : nil)
        if !i.save
          i.errors.full_messages.each { |m| resource.errors.add(:base, "#{I18n.t('activemodel.models.invitation')}: #{m}") }
          if resource.errors[:base].any? { |m| m.ends_with?(t('invitation.errors.email_conflict_handle')) }
            resource.conflicting_invitation = Invitation.open_for_handle_and_email(i.handle, i.email).first
          end
          _response_for_create_fails
          return
        end

        redirect_to omniauth_authorize_path({:provider => :google_oauth2}.merge(params[:business] ? { 'business[handle]' => params[:business][:handle] } : {}))
        return
      else
        _response_for_create_fails
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
      _response_for_create_fails
    end
  end

  def signed_in_root_path
    business_path
  end

  def _response_for_create_fails
    @business = (resource.employee && resource.employee.business) ? resource.employee.business : Business.new
    @business.handle = resource.conflicting_invitation.handle if resource.conflicting_invitation
    clean_up_passwords resource
    render "users/registrations/new"
  end


end
