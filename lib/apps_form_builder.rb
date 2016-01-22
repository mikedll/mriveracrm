class AppsFormBuilder < SimpleForm::FormBuilder
  include ActionView::Context
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::TranslationHelper

  def derived_inputs_buttons(options = {})
    derived_inputs(options).safe_concat(derived_buttons(options))
  end

  def derived_inputs(options = {})
    return nil if object.nil?

    config = object.class.introspectable_configuration
    output = ActiveSupport::SafeBuffer.new

    config.nested_associations_for_view(options[:view]).each do |na|
      button_html = ActiveSupport::SafeBuffer.new
      button_html.safe_concat(content_tag('i', '', :class => na.values.first[:icon]))
      button_html.safe_concat(" #{na.keys.first.to_s.titleize}")
      inner_html = ActiveSupport::SafeBuffer.new
      inner_html.safe_concat(content_tag('div', '', :class => 'control-label'))
      inner_html.safe_concat(content_tag('div', content_tag('div', content_tag('a', button_html, :class => "#{na.keys.first.to_s.underscore} btn"), :class => 'btn-group'), :class => 'controls'))
      output.safe_concat(content_tag('div', inner_html, :class => 'control-group'))
    end

    config.attribute_stack_for_view(options[:view]).each do |row|
      if row.length == 1
        output.safe_concat(derived_input(row.first, config.attr_decoration(row.first.keys.first.to_sym, options[:view])))
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
          inputs_html.safe_concat(content_tag('div', derived_input(attr, config.attr_decoration(attr.keys.first.to_sym, options[:view])), :class => div_class))
        end
        output.safe_concat(div_class.nil? ? inputs_html : content_tag('div', inputs_html, :class => 'row-fluid'))
      end
    end

    output
  end

  def derived_buttons(options = {})
    output = ActiveSupport::SafeBuffer.new
    tail_output = nil
    output.safe_concat(content_tag('div', :class => 'btn-group') do
                         content_tag('button', 'Save', :class => 'save btn btn-primary', :type => 'button')
                       end)

    output.safe_concat(content_tag('div', :class => 'btn-group sensitive') do
                         content_tag('button', 'Revert', :class => 'revert btn btn-warning', :type => 'button', :data => { :confirm => t('revert_confirm') })
                       end)


    #
    # We as of yet don't derive a default button set for objectless invocations of
    # this FormBuilder, although supplying a default here in the future may
    # not be hard. It's not clear that we need such a default right now. M. Rivera 12/19/15
    #
    if object
      object.class.introspectable_configuration.actions_for_view(options[:view]).each do |action_descriptor|
        name = action_descriptor.keys.first.to_s
        label = name.titleize
        btn_group_css_classes = ["btn-group"]
        btn_css_classes = ['btn', name.to_s]
        data_opts = { :data => { :action => name} }
        is_tail_output = false
        action_descriptor.values.first.each do |k, v|
          case k
          when :type
            if v == :basic
              data_opts[:data].delete(:action) if data_opts[:data][:action].nil?
            elsif v == :delete
              data_opts[:data][:confirm] = t('delete_confirm') if data_opts[:data][:confirm].nil?
              btn_css_classes.push('destroy')
              btn_css_classes.push('btn-danger')
              is_tail_output = true
            else
              btn_css_classes.push('put_action')
            end
          when :enabler
            # bug: usage in button_tag fails to preserve underscore if we index [:data]
            data_opts['data-attribute_enabler'] = v
          when :confirm
            data_opts[:data][:confirm] = v
          when :label
            label = v
          end
        end

        selected_output = output
        if is_tail_output
          tail_output ||= ActiveSupport::SafeBuffer.new
          btn_group_css_classes.push('pull-right')
          tail_output.safe_concat(content_tag('div', :class => btn_group_css_classes.join(' ')) do
                                        button_tag(label, {:type => 'button', :class => btn_css_classes.join(' ')}.merge(data_opts))
                                      end)
        else
          selected_output.safe_concat(content_tag('div', :class => btn_group_css_classes.join(' ')) do
                                        button_tag(label, {:type => 'button', :class => btn_css_classes.join(' ')}.merge(data_opts))
                                      end)

        end

      end
    end

    output.safe_concat(tail_output) if !tail_output.blank?
    content_tag('div', content_tag('div', output, :class => 'controls'), :class => 'control-group')
  end

  def derived_input(attr, decorations = {})
    input(attr.keys.first.to_sym, :apps_traits => Array.wrap(attr.values.first), :apps_decors => decorations)
  end

  def input(attribute_name, options={}, &block) #:nodoc:
    apps_traits = options.delete(:apps_traits)
    apps_attr_decors = options.delete(:apps_decors)

    if apps_traits
      apps_derived_options = apps_traits.inject({:input_html => { :class => (options[:input_html].try(:[], :class) || '') }}) do |acc, trait|

        css_class = nil
        case trait
        when :read_only
          acc[:as] = :read_only
          css_class = 'read-only-field'
        when :datetime, :currency
          acc[:as] = :string if acc[:as].nil?
          css_class = trait
        when :hidden, :string
          acc[:as] = trait if acc[:as].nil? # allow read_only to overwrite this
        else
          css_class = trait
        end

        acc[:input_html][:class] += "#{acc[:input_html][:class].blank? ? '' : ' '}#{css_class}" if css_class
        acc
      end

      # "Futhermore"
      if apps_attr_decors
        apps_attr_decors.each do |k, v|
          case k
          when :as
            apps_derived_options[k] = v
            case v
            when :text
              apps_derived_options[:input_html] ||= {}
              apps_derived_options[:input_html][:rows] = 8 if apps_derived_options[:input_html][:rows].nil?
            else
            end
          when :input_html
            apps_derived_options[:input_html] ||= {}
            apps_derived_options[:input_html].merge!(v)
          else
            apps_derived_options[k] = v
          end
        end
      end

      options.deep_merge!(apps_derived_options)
    end

    super(attribute_name, options, &block)
  end
end
