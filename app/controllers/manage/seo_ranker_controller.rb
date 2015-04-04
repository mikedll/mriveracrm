class Manage::SeoRankerController < Manage::BaseController

  skip_before_filter :require_active_plan

  before_filter :_configure_apps

  make_resourceful do
    actions :show

    response_for(:show) do |format|
      format.html do
        apps_configuration.merge!({
            :multiplicity => 'single',
            :bootstrap => rendered_current_object
          })
        render :partial => "shared/app_container", :locals => apps_configuration
      end
      format.json { render :json => rendered_current_object }
    end
  end

  def current_object
    @current_object ||= SeoRanker.new
  end

  def show
    current_object.rank!
    super
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::PRODUCTS)
  end

  def _configure_apps
    apps_configuration.merge!({
        :app_top => false,
        :app_class => 'seo-ranker',
        :title => "SEO Ranker",
        :model_templates => [SeoRanker]
      })
  end

end
