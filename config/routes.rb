require "sidekiq/web"

Touchbase::Application.routes.draw do
  
  namespace :api, defaults: { format: :json } do
    scope module: :v1 do
      resources :contacts
    end
  end

  devise_for :users
  
  get "/s/:token" => "contacts#subscriptions", as: :subscription
  
  authenticated :user do
    get "/pending" => "contacts#pending", as: :pending
    post "/multicreate" => "contacts#multicreate", as: :multicreate_contacts
    
    resources :tasks
    resources :users
    resources :followups, path: :templates
    resources :emails
    
    resources :contacts do 
      resources :notes
    end
    
    get "/fields" => "fields#index", as: :fields
    patch "/fields" => "fields#update"

    mount Sidekiq::Web => "/sidekiq"
    
    get "/" => "pages#show"
  end

  post "/:permalink/submit" => "pages#submit", as: :submit
  get "/:permalink/:option" => "pages#option", as: :option
  get "/:permalink" => "pages#show", as: :page
  
  unauthenticated :user do
    devise_scope :user do
      root "devise/registrations#new"
    end
  end
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
