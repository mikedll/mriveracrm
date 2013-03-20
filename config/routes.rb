
MikedllCrm::Application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  get "today", :to => 'today#show', :as => :todays

  get "stream", :to => 'home#stream', :as => :stream

  resource :home, :controller => "home", :path => "", :only => [] do
    get :contact
    get :projects
  end

  resources :invitations, :only => [:show] do
    put :accept
  end

  namespace 'manage' do
    resources :clients do
      resources :invoices
    end
  end

  root :to => "home#index"

end
