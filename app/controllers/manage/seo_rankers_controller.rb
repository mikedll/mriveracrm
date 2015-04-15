class Manage::SeoRankersController < Manage::BaseController

  skip_before_filter :require_active_plan

  before_filter :_parent_name
  before_filter :_configure_apps

  make_resourceful do
    actions :index, :show, :create, :update, :destroy
    belongs_to :business
  end

  def object_parameters
    params.slice(* SeoRanker.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= current_business
  end

  protected

  def _parent_name
    @parent_name = "business" # hack; parent_object isnt enough.
  end

  def _require_business_support
    true # _bsupports?(Feature::Names::SEO_RANKER)
  end

  def _configure_apps
    apps_configuration.merge!({
        :app_top => false,
        :app_class => 'seo-ranker',
        :title => "SEO Ranker"
        # :model_templates => [SeoRanker]
      })
  end

end
