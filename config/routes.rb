
Mikedll::Application.routes.draw do

  get "today", :to => 'today#show', :as => :todays

  get "stream", :to => 'home#stream', :as => :stream

  resource :home, :controller => "home", :path => "", :only => [] do
    get :projects
  end

  root :to => "home#index"

end
