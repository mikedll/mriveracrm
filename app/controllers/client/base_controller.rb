class Client::BaseController < ApplicationController
  before_filter :require_client
  before_filter :require_active_plan_public
  before_filter :_require_business_support

  before_filter :_define_top_query_scope

  protected

  def ssl_required?; Rails.env.production?; end

  #
  # Use this to further restrict the top level query scope.
  #
  def self.refine_top_query_scope
    before_filter :_release_parent_name
    before_filter :_refine_top_query_scope
  end

  private

  def _release_parent_name
    @parent_name = nil
  end

  #
  # This is debatably redundant with belongs_to in make_resourceful.
  #
  def _refine_top_query_scope
    # recommended before_filter for subclasses to restrict @parent_object further.
    raise "Override in subclass."
  end

  def _define_top_query_scope
    @parent_name = "client" # hack; parent_object isnt enough. this also fixes a huge security short-coming
    # of parent? and current_model_name? where a klass is used instead of the parent object. M. Rivera 12/16/15.

    @parent_object = current_user.client
  end

end
