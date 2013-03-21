class Users::SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, :only => [:new]

  def destroy
    sign_out(current_user)
    redirect_to root_path
  end

  
end
