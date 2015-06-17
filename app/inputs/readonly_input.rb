class ReadonlyInput < SimpleForm::Inputs::Base
  def input
    @builder.content_tag('div', '', :class => input_html_classes)
  end
end
