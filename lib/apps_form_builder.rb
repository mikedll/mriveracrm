class AppsFormBuilder < SimpleForm::FormBuilder
  include ActionView::Context
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::TranslationHelper

  def derived_inputs_buttons(options = {})
    derived_inputs(options).safe_concat(derived_buttons(options))
  end

  def derived_inputs(options = {})
    return nil if object.nil?

    output = ActiveSupport::SafeBuffer.new
    object.class.introspectable_configuration.attribute_stack_for_view(options[:view]).each do |row|
      if row.length == 1
        output.safe_concat(derived_input(row.first))
      else
        div_class = nil
        if row.length > 4
          # inline mode. assume class describer knows what he's doing.
          div_class = nil
        else
          div_class = "span6" if row.length == 2
          div_class = "span4" if row.length == 3
          div_class = "span3" if row.length == 4
        end

        inputs_html = ActiveSupport::SafeBuffer.new
        row.each do |attr|
          inputs_html.safe_concat(content_tag('div', derived_input(attr), :class => div_class))
        end
        output.safe_concat(div_class.nil? ? inputs_html : content_tag('div', inputs_html, :class => 'row-fluid'))
      end
    end

    output
  end


  def derived_buttons(options = {})
    output = ActiveSupport::SafeBuffer.new
    output.safe_concat(content_tag('div', :class => 'btn-group') do
                         content_tag('button', 'Save', :class => 'save btn btn-primary', :type => 'button')
                       end)

    output.safe_concat(content_tag('div', :class => 'btn-group sensitive') do
                         content_tag('button', 'Revert', :class => 'revert btn btn-warning', :type => 'button', :data => { :confirm => t('revert_confirm') })
                       end)

    if object
      object.class.introspectable_configuration.actions.each do |action_descriptor|
        name = action_descriptor.keys.first.to_s
        label = name.titleize
        btn_css_classes = ['btn', name.to_s]
        data_opts = { :data => { :action => name} }
        action_descriptor.values.first.each do |k, v|
          case k
          when :type
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

    if object.nil? || object.class.introspectable_configuration.destroyable == true
      data_opts = { :data => { :confirm => t('delete_confirm') } }
      if object && object.class.introspectable_configuration.destroyable_enabler
        data_opts['data-attribute_enabler'] = object.class.introspectable_configuration.destroyable_enabler
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
          acc[:as] = :string if acc[:as].nil?
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
