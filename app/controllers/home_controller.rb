class HomeController < ApplicationController

  skip_before_filter :authenticate_user!

  def index
    @projects = Project.all.map do |p|
      {
        :title => p.title,
        :tech => p.tech,
        :desc => p.description,
        :images => p.images,
        :thumb => p.images.first.data.thumb.url,
        :medium => p.images.first.data.large.url,
        :small => p.images.first.data.small.url
      }
    end
  end

  def projects
  end

  def contact
    
  end


end
