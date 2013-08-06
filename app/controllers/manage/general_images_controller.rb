class Manage::GeneralImagesController < Manage::BaseController

  before_filter :_parent_name

  make_resourceful do
    actions :all
    belongs_to :business
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects }
    end

    response_for(:show, :update, :destroy) do |format|
      format.js { render :json => current_object }
    end

    response_for(:create) do |format|
      format.json { render :status => :created, :json => current_object }
    end

    response_for(:update_fails, :create_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def create
    @current_object = nil

    if !params.slice(:data).is_a?(Array)
      @current_object = @parent_object.general_images.build(params.slice(:data))
      if @current_object.save
        response_for :create
      else
        response_for :create_fails
      end
    else
      @current_objects = []

      all_ok = true
      params.slice(:data).each do |d|
        o = @parent_object.general_images.build(params.slice(:data))
        all_ok = all_ok && o.save
        @current_objects.push(o)
      end

      if all_ok
        render :status => :created, :json => @current_objects
      else
        errors = @current_objects.map do |obj|
          { :object => obj, 
            :errors => obj.errors, 
            :full_messages => obj.errors.full_messages
          }
        end
        render :status => :unprocessable_entity, :json => errors
      end
    end
  end

  def object_parameters
    params.slice(* GeneralImage.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= Business.current
  end

  def _parent_name
    @parent_name = "business" # hack; parent_object isnt enough.
  end
end
