class HomeController < ApplicationController

  def index
    @projects = Project.all.map do |p|
      {
        :title => p.title,
        :tech => p.tech,
        :decs => p.description,
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
