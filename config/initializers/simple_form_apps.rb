
SimpleForm.setup do |config|

  config.wrappers :inline_label, :tag => 'div', :class=> 'control-group', :error_class => 'error' do |b|
    b.use :html5
    b.wrapper :tag => 'div', :class => 'controls' do |ba|
      ba.use :label_input
      ba.use :error, :wrap_with => { :tag => 'span', :class => 'help-inline' }
    end
  end

end
