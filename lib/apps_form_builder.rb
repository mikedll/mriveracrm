class AppsFormBuilder < SimpleForm::FormBuilder
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
