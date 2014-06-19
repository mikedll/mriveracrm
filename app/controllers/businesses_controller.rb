class BusinessesController < ApplicationController

  skip_before_filter :authenticate_user!
  skip_before_filter :require_business_and_current_user_belongs_to_it, :only => [:show]

  #
  # This is a marketing site, or something else?
  #
  def show
    if current_business
      @projects = current_business.projects_for_gallery
      render "home/index"
      return
    end

  end

end
