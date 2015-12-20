
#
# This should be improved to load all Rails Engine's paths
# first. For now, we load at least our translations.
#
# Acive Admin reloads the routes file and looks at our models
# before i18n load paths have been configured if we do not
# do this.
#
local_locales_finder = Rails::Paths::Root.new(Rails.root.to_s)
local_locales_finder.add("config/locales", :glob => "*.{rb,yml}").existent.each do |p|
  I18n.config.load_path << p
end
