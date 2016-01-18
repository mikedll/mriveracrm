class PagesController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :require_active_plan_public
  before_filter :_require_business_support

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

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
