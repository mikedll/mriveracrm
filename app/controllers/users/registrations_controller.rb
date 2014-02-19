class Users::RegistrationsController < Devise::RegistrationsController

  skip_before_filter :authenticate_user!

  def new
    @business = Business.new
    super
  end

  #
  # Need to require a business at the same time,
  # else we can't map the user.
  #
  def create

    Business.transaction do |t|
      @business = Business.new(params[:business])
      if @business.save
        @employee = Employee.new(:business => @business, :role => Employee::Roles::OWNER)


        build_resource
        resource.employee = @employee
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
          clean_up_passwords resource
          respond_with resource
        end


        @user = User.new(params[:user].merge())
        if @employee.save && @user.save
          flash[:notice] = I18n.t('business.created')
          redirect_to after_sign_up_path(@user)
        else
          render "users/registrations/new"
        end
      else
        render "users/registrations/new"
      end
    end
  end
end
