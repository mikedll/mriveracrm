class PagesController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :require_active_plan_public
  before_filter :_require_business_support
  before_filter :_require_page
  before_filter :_calculate_title
  before_filter :calculate_public_navigation, :only => [:show]

  configure_apps :model => Page do
    actions :show

    response_for :show do |format|
      format.html
    end
  end

  def current_object
    @current_object ||= current_business.pages.find_by_slug params[:id]
  end

  protected

  def _require_page
    head :not_found if current_object.nil?
  end

  def _calculate_title
    @title = current_object.title
  end

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
