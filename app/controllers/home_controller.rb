class HomeController < ApplicationController

  skip_before_filter :authenticate_user!

  def index
    @projects = current_business.projects_for_gallery
  end

  def projects
  end

  def contact
  end

end
