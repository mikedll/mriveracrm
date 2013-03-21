
MikedllCrm::Application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  get "today", :to => 'today#show', :as => :todays

  resource :home, :controller => "home", :path => "", :only => [] do
    get :contact
    get :projects
  end

  resources :invitations, :only => [:show] do
    put :accept
  end

  namespace 'manage' do
    resources :clients do
      resources :invoices do
        member do
          put :mark_pending
        end
      end
    end

    resources :invoices, :only => [:index, :create, :show]
  end

  root :to => "home#index"

end
