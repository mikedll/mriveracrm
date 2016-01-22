class ProductsController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :require_active_plan_public
  before_filter :_require_business_support
  before_filter :calculate_public_navigation, :only => [:index]
  before_filter :_calculate_title, :only => [:index]

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

  def current_objects
    @current_objects ||= Product.cb.index_or_search(params.slice(:query, :max_price))
  end

  def _calculate_title
    @title = @link_orderings.select { |lo| lo.referenced_link.to_sym == :products }.first.title
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::PRODUCTS)
  end

end
