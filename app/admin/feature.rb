ActiveAdmin.register Feature do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it
  end

  actions :all, except: [:new, :create, :destroy]

  form do |f|
    f.semantic_errors
    f.inputs   :public_name
    f.actions
  end
end
