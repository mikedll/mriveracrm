class HomeController < ApplicationController

  def index
    @projects = Project.all.map do |p|
      {
        :title => p.title,
        :tech => p.tech,
        :decs => p.description,
        :thumb => p.images.first.data.thumb('160x133').remote_url,
        :medium => p.images.first.data.thumb('360x300').remote_url,
        :full => p.images.first.data.thumb('600x500').remote_url
      }
    end
  end

  def projects
  end

  def contact
    
  end


end
