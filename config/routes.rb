Mikedll::Application.routes.draw do
  get 'today', :to => 'today#show', :as => :todays
  match '/:controller(/:action(/:id))'
end
