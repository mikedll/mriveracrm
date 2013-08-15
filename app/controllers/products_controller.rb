class ProductsController < ApplicationController

  make_resourceful do
    actions :index, :show

    response_for(:index) do |format|
      format.html
      format.json { render :json => rendered_current_objects }
    end

    response_for(:show) do |format|
      format.json  { render :json => rendered_current_object }
    end
  end

  def json_config
    {:include => { :primary_product_image => { :include => :image } }}
  end

  def rendered_current_objects
    current_objects.to_json(json_config)
  end

  def rendered_current_object
    current_object.to_json(json_config)
  end

  def search
    Product.search params[:query]
    response_for :index
  end

end
