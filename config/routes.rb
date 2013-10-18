
MikedllCrm::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } 

  [:google_auth2].tap do |omniauth_providers|
    match "users/:provider",
    :constraints => { :provider => omniauth_providers },
    :to => "users/omniauth_callbacks#authorize",
    :as => :omniauth_authorize,
    :via => [:get, :post]

    match "users/:action/callback",
    :constraints => { :action => omniauth_providers },
    :to => "users/omniauth_callbacks#authorize",
    :as => :omniauth_callback,
    :via => [:get, :post]
  end

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

  resources :products, :only => [:index] do
    collection do
      get :search
    end
  end

  namespace 'manage' do

    resource :business, :only => [:show, :update]
    resource :status_monitor, :controller => :status_monitor,  :only => [:show]


    resources :products do
      resources :product_images, :path => "images" do
        member do
          put :toggle_primary
        end
      end
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
          put :regenerate_pdf
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
