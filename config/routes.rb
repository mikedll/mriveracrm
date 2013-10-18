
MikedllCrm::Application.routes.draw do

  devise_for :users

  devise_scope :user do
    [:google_oauth2].tap do |omniauth_providers|

      providers = Regexp.union(omniauth_providers.map(&:to_s))

      match "users/auth/:provider",
      :constraints => { :provider => providers },
      :to => "users/sessions#authorize",
      :as => :omniauth_authorize,
      :via => [:get, :post]

      match "users/auth/:action/callback",
      :constraints => { :action => providers },
      :to => "users/sessions",
      :as => :omniauth_callback,
      :via => [:get, :post]
    end

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
