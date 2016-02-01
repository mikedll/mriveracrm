class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan
  before_filter :_require_business_support

  before_filter :_define_top_query_scope

  protected

  #
  # Use this to further restrict the top level query scope.
  #
  def self.refine_top_query_scope
    before_filter :_refine_top_query_scope
    before_filter :_redefine_parent_name
  end

  def ssl_required?; Rails.env.production?; end

  private

  #
  # This is debatably redundant with belongs_to in make_resourceful.
  #
  def _refine_top_query_scope
    # recommended before_filter for subclasses to restrict @parent_object further.
    raise "Override in subclass."
  end

  def _redefine_parent_name
    @parent_name = @parent_object.class.to_s
  end

  def _define_top_query_scope
    @parent_name = "business" # hack; parent_object isnt enough. this also fixes a huge security short-coming
    # of parent? and current_model_name? where a klass is used instead of the parent object. M. Rivera 12/16/15.

    @parent_object = current_business
  end

end
