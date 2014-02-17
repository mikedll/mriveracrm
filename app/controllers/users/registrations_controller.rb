class Users::RegistrationsController < Devise::RegistrationsController

  #
  # Need to require a business at the same time,
  # else we can't map the user.
  #
  def create
    
  end

end
