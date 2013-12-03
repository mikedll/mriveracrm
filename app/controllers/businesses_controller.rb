class BusinessesController < ApplicationController

  skip_before_filter :authenticate_user!

  def new
  end

  def show
  end

end
