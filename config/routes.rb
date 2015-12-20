
MikedllCrm::Application.routes.draw do

  ActiveAdmin.routes(self)

  # raw marketing / custom domain
  resource :business, :path => "", :only => [:show]

  resource :home, :path => "", :controller => :home, :only => [] do
    member do
      get :contact
    end
  end

  resources :stripe_webhooks, :only => [:create]

  ######################################## custom domain
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations", :confirmations => "users/confirmations" }

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

    get 'forbidden', :to => 'users/sessions#forbidden', :as => :forbidden_user_session
  end


  resources :invitations, :only => [:show] do
    put :accept
  end

  resources :products, :only => [:index] do
    collection do
      get :search
    end
  end

  resources :monitored_computers, :only => [] do
    collection do
      post :heartbeat
    end
  end

  namespace 'manage' do

    resource :billing_settings, :only => [:show, :update]
    resource :business, :only => [:show, :update, :destroy] do
      member do
        put  :regenerate_monitored_computers_key
      end
    end
    resource :status_monitor, :controller => :status_monitor,  :only => [:show]

    resources :monitored_computers, :only => [:index, :show, :create, :update, :destroy]

    resources :products do
      resources :product_images, :path => "images" do
        member do
          put :toggle_primary
        end
      end
    end

    resources :clients, :only => [:new, :index, :show, :update, :create] do
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

    resources :invoices, :only => [:index, :show] do
      member do
        put :charge
      end
    end
  end


  ################################################ Business via MFE
  ################################################
  ################################################ This is NOT exactly the same as down below.
  ################################################ sometimes its useful to comment this out
  ################################################ when running rake routes, since its almosta dup of above

  scope "b/(:business_handle)", :as => 'bhandle', :constraints => { :business_handle => Regexes::BUSINESS_HANDLE_ROUTING } do
    resource :business, :path => "", :only => [:show]

    resource :home, :path => "", :controller => :home, :only => [] do
      member do
        get :contact
      end
    end

    devise_for :users, :controllers => { :sessions => "users/sessions", :confirmations => "users/confirmations" }, :skip => [:registrations, :passwords]

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
    end


    resources :invitations, :only => [:show] do
      put :accept
    end

    resources :products, :only => [:index] do
      collection do
        get :search
      end
    end

    resources :monitored_computers, :only => [] do
      collection do
        post :heartbeat
      end
    end

    namespace 'manage' do

      resource :billing_settings, :only => [:show, :update]
      resource :business, :only => [:show, :update, :destroy] do
        member do
          put :regenerate_monitored_computers_key
        end
      end
      resource :status_monitor, :controller => :status_monitor,  :only => [:show]

      resources :monitored_computers, :only => [:index, :show, :create, :update, :destroy]

      resources :products do
        resources :product_images, :path => "images" do
          member do
            put :toggle_primary
          end
        end
      end

      resources :clients, :only => [:new, :index, :show, :update, :create] do
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

      resources :invoices, :only => [:index, :show]  do
        member do
          put :charge
        end
      end
    end
  end


  root :to => "business#show"

end
