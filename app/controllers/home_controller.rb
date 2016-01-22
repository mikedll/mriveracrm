class HomeController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :calculate_public_navigation, :only => [:contact]
  before_filter :_calculate_title, :only => [:contact]

  def index
    @projects = current_business.projects_for_gallery
  end

  def projects
  end

  def contact
  end

  def _calculate_title
    @title = @link_orderings.select { |lo| lo.referenced_link.to_sym == :contact_home }.first.title
  end

end
