class Manage::InvoicesController < Manage::BaseController

  make_resourceful do
    actions :index, :show, :update, :create, :destroy
    belongs_to :client
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
      format.js { render :status => :created, :json => current_object }
    end

    response_for(:update_fails, :create_fails, :destroy_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def mark_pending
    load_object
    if current_object.update_attributes(object_parameters)
      if current_object.mark_pending!
        response_for :update
      else
        response_for :update_fails
      end
    else
      response_for :update_fails
    end
  end

  def regenerate_pdf
    load_object
    if current_object.regenerate_pdf
      response_for :update
    else
      response_for :update_fails
    end
  end

  def cancel
    load_object
    if current_object.cancel!
      response_for :update
    else
      response_for :update_fails
    end
  end

  def charge
    load_object
    if current_object.charge!
      response_for :update
    else
      response_for :update_fails
    end
  end

  def mark_paid
    if current_object.mark_paid
      response_for :update
    else
      response_for :update_fails
    end
  end

  def parent_object
    @parent_object ||= Business.current.clients.find params[:client_id]
  end


  def object_parameters
    params.slice(* Invoice.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

end

