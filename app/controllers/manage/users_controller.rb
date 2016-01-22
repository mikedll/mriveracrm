class Manage::UsersController < Manage::BaseController

  refine_top_query_scope

  make_resourceful do
    actions :show, :index
    belongs_to :client

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects }
    end

    response_for(:show) do |format|
      format.js { render :json => current_object }
    end
  end

  protected

  def _refine_top_query_scope
    @parent_object = @parent_object.clients.find params[:client_id]
  end

  def _require_business_support
    true
  end

end
