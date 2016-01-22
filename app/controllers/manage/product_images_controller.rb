class Manage::ProductImagesController < Manage::BaseController

  refine_top_query_scope

  make_resourceful do
    actions :all
    belongs_to :product
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.json { render :json => current_objects }
    end

    response_for(:show, :update, :destroy) do |format|
      format.json { render :json => rendered_current_object }
    end

    response_for(:create) do |format|
      format.json { render :status => :created, :json => rendered_current_object }
    end

    response_for(:update_fails, :create_fails) do |format|
      format.json { render :status => :unprocessable_entity, :json => { :object => rendered_current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def rendered_current_object
    current_object.to_json(:include => :image)
  end


  def create
    @current_object = @parent_object.product_images.build(object_parameters)

    if !params.slice(:data).is_a?(Array)
      @current_object.image = Image.new(params[:image])

      if @current_object.save
        response_for :create
      else
        response_for :create_fails
      end
    else

      raise "Concurrent uploads not implemented yet."

      # below code has never run

      # @current_objects = []

      # all_ok = true
      # params.slice(:data).each do |d|
      #   o = @parent_object.images.build(params.slice(:data))
      #   all_ok = all_ok && o.save
      #   @current_objects.push(o)
      # end

      # if all_ok
      #   render :status => :created, :json => @current_objects
      # else
      #   errors = @current_objects.map do |obj|
      #     { :object => obj, 
      #       :errors => obj.errors, 
      #       :full_messages => obj.errors.full_messages
      #     }
      #   end
      #   render :status => :unprocessable_entity, :json => errors
      # end
    end
  end

  def toggle_primary
    current_object.update_attributes(:primary => !current_object.primary)
    if current_object.save
      response_for :update
    else
      response_for :update_fails
    end
  end

  def object_parameters
    params.slice(* ProductImage.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _refine_top_query_scope
    @parent_object = @parent_object.products.find params[:product_id]
  end

  def _require_business_support
    _bsupports?(Feature::Names::PRODUCTS)
  end

end
