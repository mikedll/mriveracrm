class Users::ConfirmationsController < Devise::ConfirmationsController
  
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:new, :show, :create]
end
