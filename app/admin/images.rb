ActiveAdmin.register Image do

  form :html => { :enctype => 'multipart/form-data' } do |f|
    f.inputs "Details" do
      f.input :project
      f.input :data, :as => :file
    end

    f.buttons
  end

end
