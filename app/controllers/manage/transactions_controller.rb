class Manage::TransactionsController < Manage::BaseController

  # Makes outside transactions by default

  make_resourceful do
    actions :index, :show, :update, :create, :destroy
    belongs_to :invoice
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects.map(&:to_editor) }
    end

    response_for(:show, :update, :destroy) do |format|
      format.js { render :json => current_object.to_editor }
    end

    response_for(:create) do |format|
      format.js { render :status => :created, :json => current_object.to_editor }
    end

    response_for(:update_fails, :create_fails, :destroy_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object.to_editor, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def build_object
    # We only build OutsideTransaction, not other types. Those are built automatically.
    @current_object = parent_object.outside_transactions.build(object_parameters)
  end

  def object_parameters
    params.slice(* Transaction.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= begin
                         client = current_business.clients.find_by_id params[:client_id]
                         raise ActiveRecord::RecordNotFound if client.nil?
                         invoice = client.invoices.find_by_id params[:invoice_id]
                         raise ActiveRecord::RecordNotFound if invoice.nil?
                         invoice
                       end 
  end

  def mark_successful
    if current_object.begin && current_object.succeed
      response_for :update
    else
      current_object.add_transition_errors
      response_for :update_fails
    end
  end

end

