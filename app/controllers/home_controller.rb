class HomeController < ApplicationController

  def index
    @projects = Project.all.map do |p|
      {
        :title => p.title,
        :tech => p.tech,
        :decs => p.description,
        :thumb => p.images.first.data.thumb.url,
        :medium => p.images.first.data.medium.url,
        :small => p.images.first.data.small.url
      }
    end
  end

  def projects
  end

  def contact
    
  end


end
