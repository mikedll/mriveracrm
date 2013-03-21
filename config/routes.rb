
MikedllCrm::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } 

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

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
