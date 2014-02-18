class Users::RegistrationsController < Devise::RegistrationsController

  skip_before_filter :authenticate_user!

  #
  # Need to require a business at the same time,
  # else we can't map the user.
  #
  def create
    @business = Business.new(:handle => params[:business])
    Business.transaction do |t|
      if @business.save
        @user = User.new(params[:user].merge(:business => @business))
        if @user.save
          redirect_to after_sign_up_path(@user)
        else
          render "registrations/new"
        end
      else
        render "registrations/new"
      end
    end
  end

end
