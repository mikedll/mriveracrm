
Mikedll::Application.routes.draw do

  get "today", :to => 'today#show', :as => :todays

  get "stream", :to => 'home#stream', :as => :stream

  root :to => "home#index"

end
