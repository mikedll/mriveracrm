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

  sidebar "More", only: [:show] do
    ul do
      li link_to "Users",    abdiel_business_users_path(business)
    end
  end

  ActiveAdmin.register User do

    controller do
      skip_before_filter :_require_business_or_mfe
      skip_before_filter :require_business_and_current_user_belongs_to_it
    end

    belongs_to :business, :parent_class => Business
    navigation_menu :business


    actions :all, :except => [:new, :create, :edit, :update, :destroy]

    index do
      column :id
      column :email
      column :first_name
      column :last_name
      column :created_at
      column :is_admin
      column :employee_id
      column :client_id
      column "Is Owner?" do |user|
        if user.employee
          user.employee.owner?.to_s
        else
          "n/a"
        end
      end
      column :business_id do |user|
        link_to(user.business_id, abdiel_business_path(user.business_id))
      end
      actions
    end

    show do
      attributes_table do
        row :id
        row :email
        row :first_name
        row :last_name
        row :created_at
        row :updated_at
        row :last_sign_in_at
        row :employee_id
        row "Is Owner?" do
          if user.employee
            user.employee.owner?.to_s
          else
            "n/a"
          end
        end
        row :client_id
        row :is_admin do
          user.is_admin?.to_s
        end
        row :business_id do
          link_to(user.business_id, abdiel_business_path(user.business_id))
        end
      end
    end
  end

end
