class Manage::ClientsController < Manage::BaseController


  def object_parameters
    params.slice(* Client.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

end
