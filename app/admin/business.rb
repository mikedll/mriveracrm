ActiveAdmin.register Business do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it

    def scoped_collection
      Business.unscoped
    end
  end

  actions :all, except: [:new, :create, :update, :edit, :destroy]

  index do
    column :id
    column :name
    column :host
    column :handle
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :host
      row :created_at
      row :updated_at
      row :handle
      row :default_mfe
    end
  end

end
