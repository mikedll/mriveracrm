class Client::InvoicesController < Client::BaseController

  make_resourceful do
    actions :index

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects.map(&:public) }
    end

    response_for(:show) do |format|
      format.js { render :json => current_object.public }
    end

    response_for(:update_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object.public, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def charge
    if current_object.charge!
      response_for :update
    else
      response_for :update_fails
    end
  end

  def current_objects
    @current_objects ||= current_user.client.invoices
  end

end
