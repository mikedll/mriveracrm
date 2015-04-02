ActiveAdmin.register_page "Dashboard" do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it
    helper :application
  end

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("app_title") } do

    columns do
      column do
        panel "Business and owner" do
          ul do
            Business.unscoped.all.each do |b|
              li do
                "#{b.id}: #{b.handle} - #{b.name} - #{b.employees.is_owner.first.try(:email)}"
              end
            end
          end
        end
      end

      column do
        link_to "Your Business, #{current_user.business.handle}", business_home_url(current_user.business)
      end
    end
  end
end
