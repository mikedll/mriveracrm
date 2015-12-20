module SimpleForm
  module Components
    module BootstrapControlLabel

      def bootstrap_control_label
        options[:label_html] ||= {}
        options[:label_html][:class] = [] if !options[:label_html].key?(:class)
        options[:label_html][:class].push('control-label') if !options[:label_html][:class].include?('control-label')
        nil
      end
    end
  end
end
