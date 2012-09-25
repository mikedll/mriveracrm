ActiveAdmin.register ImageProject do

  form do |f|
    f.inputs do
      f.input :image, :as => :select,      :collection => Image.all.inject({}) { |acc, cur| acc[cur.data] = cur.id; acc }
      f.input :project
    end
    f.buttons
  end

end
