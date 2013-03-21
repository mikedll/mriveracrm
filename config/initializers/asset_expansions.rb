
ActionView::Helpers::AssetTagHelper.register_javascript_expansion :jquery => ['jquery', 'rails']

ActiveSupport.on_load(:action_view) do
  ActiveSupport.on_load(:after_initialize) do
    ActionView::Helpers::AssetTagHelper::register_javascript_expansion :defaults => ['jquery', 
                                                                                     'jquery_ujs',
                                                                                     'jquery.easing-1.3.pack.js',
                                                                                     'builder'
                                                                                     ]
  end
end

ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :defaults => ["default"]
