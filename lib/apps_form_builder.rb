class AppsFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    options.merge!(:label_html => { :class => 'control-label' }) if options[:wrapper] != :inline_label
    super(attribute_name, options, &block)
  end
end
