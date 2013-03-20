class Manage::InvoicesController < Manage::BaseController

  make_resourceful do
    belongs_to :client
  end

  def object_parameters
    params.slice(* Invoice.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

end

