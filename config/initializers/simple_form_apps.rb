# Form Builder
require 'apps_form_builder'

SimpleForm.setup do |config|

  config.wrappers :inline_label, :tag => 'div', :class=> 'control-group', :error_class => 'error' do |b|
    b.use :html5
    b.wrapper :tag => 'div', :class => 'controls' do |ba|
      ba.use :label_input
      ba.use :error, :wrap_with => { :tag => 'span', :class => 'help-inline' }
    end
  end

  config.wrappers :read_only, :tag => 'div', :class=> 'control-group', :error_class => 'error' do |b|
    b.use :bootstrap_control_label
    b.use :label
    b.wrapper :tag => 'div', :class => 'controls' do |ba|
      ba.use :input
    end
  end

end
