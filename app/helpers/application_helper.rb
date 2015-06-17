# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def current_business
    @current_business
  end

  def absolute_asset_prefix
    s = ""
    s += ActionController::Base.asset_host if ActionController::Base.asset_host
    s += ActionController::Base.asset_path.call('') if ActionController::Base.asset_path
    s
  end

  #
  # This is a legacy helper...should not be used going forward from June 15th, 2014,
  # or equivalently, after the multitenant oauth refactoring.
  #
  def user_omniauth_authorize_path(provider)
    omniauth_authorize_path(provider)
  end

  def page_title
    if @title
      @title += " - #{@current_business.name}"
    else
      @title = !@current_mfe.nil? ? @current_mfe.title : @current_business.name
    end
  end

  def bcan?(*names)
    @current_business && @current_business.active_plan? && @current_business.supports?(*names)
  end

  def business_home_url(business)
    if business.host.blank?
      business_url(:use_route => 'bhandle_home', :business_handle => business.handle, :host => business.default_url_host)
    else
      business_url(:host => business.default_url_host)
    end

  end

  def apps_configuration
    @apps_configuration
  end

  def read_only_field(model_name, attribute_name, type_mods = [])

    control_group_mod = ""
    if type_mods.include?(:error)
      control_group_mod = "error"
      type_mods.reject! { |mod| mod == :error }
    end

    opts = {
      :class => ['read-only-field'],
      :data => { :name => "#{model_name}[#{attribute_name}]" },
    }
    opts[:class] += type_mods if type_mods

    content_tag(:div, :class => ["control-group", control_group_mod]) do
      concat content_tag(:div, :class => "control-label") { concat(label_tag("#{attribute_name.to_s.titleize}:")) }
      concat content_tag(:div, content_tag(:div, '', opts), :class => 'controls')
    end
  end

  def apps_form_for(object, *args, &block)
    options = args.extract_options!
    simple_form_for(object, *(args << options.merge(:builder => AppsFormBuilder)), &block)
  end


end
