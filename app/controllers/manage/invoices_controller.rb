class Manage::InvoicesController < Manage::BaseController

  refine_top_query_scope

  configure_apps :model => Invoice do
    actions :index, :show, :update, :create, :destroy
    member_actions :mark_pending, :regenerate_pdf, :cancel, :charge, :mark_paid
    belongs_to :client

    response_for(:index) do |format|
      format.html
      format.json { render :json => rendered_current_objects }
    end
  end

  def mark_pending
    with_update_and_transition { current_object.mark_pending! }
  end

  def regenerate_pdf
    with_update_and_transition { current_object.regenerate_pdf }
  end

  def cancel
    with_update_and_transition { current_object.cancel! }
  end

  def charge
    with_update_and_transition { current_object.charge! }
  end

  def mark_paid
    with_update_and_transition { current_object.mark_paid }
  end

  def _refine_top_query_scope
    @parent_object = @parent_object.clients.find params[:client_id]
  end

  def object_parameters
    params.slice(* Invoice.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::INVOICING)
  end

end

