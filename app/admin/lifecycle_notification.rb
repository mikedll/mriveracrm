ActiveAdmin.register LifecycleNotification do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it
  end

  actions :all, except: [:new, :create, :update, :edit, :destroy]

  index do
    column :id
    column :identifier
    column :created_at
    column :updated_at
    column :business do |ln|
      link_to ln.business_id, abdiel_business_path(ln.business_id)
    end
    actions
  end
end
