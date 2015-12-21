class Manage::LettersController < Manage::BaseController

  configure_apps :model => Letter do
    belongs_to :business
    actions :index, :show, :update, :create, :destroy
  end

  def object_parameters
    params.slice(* Letter.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= current_business
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::LETTERS)
  end

end
