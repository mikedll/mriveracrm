class AppsFormBuilder < SimpleForm::FormBuilder
  include ActionView::Context
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::TranslationHelper

  cattr_accessor :action_button_defaults
  self.action_button_defaults = { :action_type => :put_action }


  def derived_buttons
    output = ActiveSupport::SafeBuffer.new
    output.safe_concat(content_tag('div', :class => 'btn-group') do
                         content_tag('button', 'Save', :class => 'save btn btn-primary', :type => 'button')
                       end)

    output.safe_concat(content_tag('div', :class => 'btn-group sensitive') do
                         content_tag('button', 'Revert', :class => 'revert btn btn-warning', :type => 'button', :data => { :confirm => t('revert_confirm') })
                       end)

    if object
      object.apps_actions.each do |action_descriptor|
        name = action_descriptor.keys.first.to_s
        label = name.titleize
        btn_css_classes = ['btn', name.to_s]
        data_opts = { :data => { :action => name} }
        action_button_defaults.merge(action_descriptor.values.first).each do |k, v|
          case k
          when :action_type
            if v == :basic
              data_opts = { :data => {}}
            else
              btn_css_classes.push('put_action')
            end
          when :enabled_on
            # bug: useage in button_tag fails to preserve underscore if we index [:data]
            data_opts['data-attribute_enabler'] = v.to_s
            data_opts['data-enabled_when'] = 'true'
          when :confirm
            data_opts[:data][:confirm] = v
          when :label
            label = v
          end
        end

        output.safe_concat(content_tag('div', :class => 'btn-group') do
                             button_tag(label, {:type => 'button', :class => btn_css_classes.join(' ')}.merge(data_opts))
                           end)
      end
    end

    if object.nil? || object.class.apps_destroyable == true
      data_opts = { :data => { :confirm => t('delete_confirm') } }
      if object && object.class.apps_destroyable_enabler
        data_opts = data_opts[:data][:attribute_enabler] = object.class.apps_destroyable_enabler
      end

      output.safe_concat(content_tag('div', :class => 'btn-group pull-right') do
                           content_tag('button', 'Delete', {:class => 'destroy btn btn-danger', :type => 'button'}.merge(data_opts))
                         end)
    end

    content_tag('div', content_tag('div', output, :class => 'controls'), :class => 'control-group')
  end


  def derived_input(attr)
    if attr.is_a?(Hash)
      input(attr.keys.first.to_sym, :apps_traits => Array.wrap(attr.values.first))
    else
      input(attr)
    end
  end

  def input(attribute_name, options={}, &block) #:nodoc:
    apps_traits = options.delete(:apps_traits)
    if apps_traits
      apps_derived_options = apps_traits.inject({:input_html => { :class => (options[:input_html].try(:[], :class) || '') }}) do |acc, trait|

        css_class = nil
        case trait
        when :read_only
          acc[:as] = :read_only
          css_class = 'read-only-field'
        when :datetime
          css_class = trait
        end

        acc[:input_html][:class] += "#{acc[:input_html][:class].blank? ? '' : ' '}#{css_class}" if css_class
        acc
      end

      options.deep_merge!(apps_derived_options)
    end

    super(attribute_name, options, &block)
  end
end
