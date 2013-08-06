
MikedllCrm::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } 

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  resource :home, :controller => "home", :path => "", :only => [] do
    get :contact
    get :projects
  end

  resources :invitations, :only => [:show] do
    put :accept
  end

  namespace 'manage' do

    resource :status_monitor, :controller => :status_monitor,  :only => [:show]

    resources :general_images, :path => 'images' do
    end

    resources :products do
    end

    resources :clients do
      put :archive
      put :unarchive
      resources :notes
      resources :invitations
      resources :users, :only => [:index, :show]
      resources :invoices do
        member do
          put :mark_pending
          put :cancel
          put :charge
          put :mark_paid
        end

        resources :transactions do
          member do
            put :mark_successful
          end
        end
      end
    end

    resources :invoices, :only => [:index, :create, :show]
  end

  namespace "client" do
    resource :payment_gateway_profile, :only => [:create, :update, :show]

    resources :invoices do
      member do
        put :charge
      end
    end
  end

  root :to => "home#index"

end
