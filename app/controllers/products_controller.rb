class ProductsController < ApplicationController

  make_resourceful do
    actions :index, :show

    response_for(:index) do |format|
      format.html
      format.json { render :json => current_objects }
    end

    response_for(:show) do |format|
      format.js { render :json => current_object.public }
    end
  end

  def search
    Product.search params[:query]
    response_for :index
  end

end
