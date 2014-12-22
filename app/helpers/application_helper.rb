# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def absolute_asset_prefix
    s = ""
    s += ActionController::Base.asset_host if ActionController::Base.asset_host
    s += ActionController::Base.asset_path.call('') if ActionController::Base.asset_path
    s
  end

  #
  # This is a legacy helper...should not be used going forward from June 15th, 2014,
  # or equivalently, after the multitenant oauth refactoring.
  #
  def user_omniauth_authorize_path(provider)
    omniauth_authorize_path(provider)
  end

  def page_title
    if @title
      @title += " - #{@current_business.name}"
    else
      @title = !@current_mfe.nil? ? @current_mfe.title : @current_business.name
    end
  end

  def bcan?(n)
    @current_business && @current_business.supports?(n)
  end

end
