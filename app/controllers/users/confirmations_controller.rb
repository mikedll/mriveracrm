class Users::ConfirmationsController < Devise::ConfirmationsController

  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :show, :create]
  before_filter :_require_mfe

  def after_confirmation_path_for(resource_name, resource)
    after_sign_in_path_for(current_user)
  end

end
