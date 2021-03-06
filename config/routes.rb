Rails.application.routes.draw do

  post 'oauth/callback' => 'oauths#callback'
  get 'oauth/callback' => 'oauths#callback' # for use with Github, Facebook
  get 'oauth/:provider' => 'oauths#oauth', :as => :auth_at_provider

  get 'login' => 'user_sessions#new', as: :login
  post 'logout' => 'user_sessions#destroy', as: :logout
  get 'about' => 'pages#about', as: :about
  root to: 'pages#home'

  resources :user_sessions
  resources :users, except: [:index] do
    member do
      get :activate
      patch :default_group
    end
    collection do
      get :auto_complete
    end
  end

  # Only the collection routes of the children get member routes of the parent
  shallow do
    resources :user_groups do
      resources :users, module: :user_groups, only: [] do
        collection do
          get :show
        end
      end
      resources :groceries, except: [:update, :index, :edit] do
        resources :recipes, module: :groceries, only: [] do
          collection do
            patch :update
          end
        end
        resources :checkouts, module: :groceries, only: [:create] do
          collection do
            get :show
          end
        end
        resources :items, module: :groceries, only: [] do
          collection do
            get :show
            patch :update
          end
        end
        resources :receipts, module: :groceries, only: [:create] do
          collection do
            get :show
            post :confirm
          end
        end
        resources :items, only: [:update] do
          collection do
            get :auto_complete
          end
        end
        member do
          patch :receipt
          patch :do_checkout
          patch :update_store
          post :email_group
        end
      end
      member do
        get :payments
        patch :accept_invitation
        patch :do_payment
        patch :leave
      end
    end
  end
end
