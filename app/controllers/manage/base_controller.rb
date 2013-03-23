class Manage::BaseController < ApplicationController
  before_filter :require_employee

end
