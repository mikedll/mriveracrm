
Mikedll::Application.routes.draw do

  get "today", :to => 'today#show', :as => :todays

  root :to => "home#index"

end
