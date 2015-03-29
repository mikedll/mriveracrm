class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan

  protected

  def ssl_required?; Rails.env.production?; end

  def state_transition
    if yield
      response_for :update
    else
      response_for :update_fails
    end
  end

end
