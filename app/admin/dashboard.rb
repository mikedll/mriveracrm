ActiveAdmin.register_page "Dashboard" do

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
        "Nothing here for now..."
      end
    end
  end
end
