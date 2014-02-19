class BusinessesController < ApplicationController

  skip_before_filter :authenticate_user!

  #
  # This is a marketing site, or something else?
  #
  def show
  end

end
