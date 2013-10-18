# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def absolute_asset_prefix
    s = ""
    s += ActionController::Base.asset_host if ActionController::Base.asset_host
    s += ActionController::Base.asset_path.call('') if ActionController::Base.asset_path
    s
  end

  def user_omniauth_authorize_path(provider)
    omniauth_authorize_path(provider)
  end


end
