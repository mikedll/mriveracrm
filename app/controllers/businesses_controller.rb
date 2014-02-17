class BusinessesController < ApplicationController

  skip_before_filter :authenticate_user!

  #
  # This is a marketing site, or something else?
  #
  def show
    if marketing?

      # render with the marketing site's pages.
      # this is a lot of custom work...for the given marketing site.

    else

      # render with business' pages, similar to 'home'

    end
  end

end
