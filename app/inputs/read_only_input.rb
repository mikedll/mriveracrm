class ReadOnlyInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::FormTagHelper

  def input
    content_tag('div', '', :class => input_html_classes, :data => { :name => "#{object_name}[#{attribute_name}]" } )
  end
end
