# frozen_string_literal: true

def loaderio_token
  (ENV['LOADERIO_TOKEN'] || 'loaderio-296a53739de683b99e3a2c4d7944230f')
end

Rails.application.routes.draw do
  mount Mercury::Engine => '/'

  root 'visitors#index'

  get '/.well-known/acme-challenge/:id' => 'static_pages#letsencrypt'
  get loaderio_token => 'static_pages#loaderio'
  get '/get-token' => 'av_dashboard_tokens#create', as: 'get_av_dashboard_token'

  resources :activities

  resources :cards, only: %i(create update edit new)
  resources :subscriptions, only: %i(create update new)
  get '/subscriptions_paypal_redirect' => 'subscriptions#create'
  post '/paypal/new' => 'paypal_agreement#new'
  get '/paypal/create' => 'paypal_agreement#create'

  devise_for :users, controllers: { registrations: 'registrations' }
  resources :users, only: %i(index show), format: false do
    member do
      patch :add_status
      delete :destroy
    end
  end

  resources :articles, format: false do
    member do
      get :upvote
      get :downvote
      get :cancelvote
    end
  end

  resources :dashboard, only: :index

  match '/hangouts/:id' => 'event_instances#update', :via => %i(put options), as: 'hangout'
  match '/hangouts' => 'event_instances#index', :via => [:get], as: 'hangouts'

  resources :event_instances, only: [:edit]
  patch '/event_instances/:id', to: 'event_instances#update_link'

  resources :projects, except: [:destroy], format: false do
    member do
      put :mercury_update
      get :mercury_saved
      get :follow
      get :unfollow
      post :activate, action: :update, defaults: { command: 'activate' }
      post :deactivate, action: :update, defaults: { command: 'deactivate' }
    end
    
    resources :documents, except: %i(edit update), format: false do
      put :mercury_update
      get :mercury_saved
    end
    
    resources :events, only: [:index]
  end
  get :pending_projects, controller: :projects, action: :index, defaults: { status: 'pending' }

  resources :events do
    member do
      patch :update_only_url
    end
  end

  scope '/legacy_api' do
    scope '/subscriptions' do
      get '/' => 'legacy_api/subscriptions#index', as: 'api_subscriptions', defaults: { format: 'json' }
    end
  end

  get '/mentors' => 'users#index', defaults: { title: 'Mentor' }
  get '/premium_members' => 'users#index', defaults: { title: 'Premium' }

  get '/verify/:id' => redirect { |params, _request| "http://av-certificates.herokuapp.com/verify/#{params[:id]}" }

  post 'preview/article', to: 'articles#preview', format: false
  patch 'preview/article', to: 'articles#preview', as: 'preview_articles', format: false

  get 'projects/:project_id/:id', to: 'documents#show', format: false

  get '/auth/:provider/callback' => 'authentications#create', :format => false
  get '/auth/failure' => 'authentications#failure', :format => false
  get '/auth/destroy/:id', to: 'authentications#destroy', via: :delete, format: false

  post 'mail_hire_me_form', to: 'users#hire_me', format: false
  get 'scrums', to: 'scrums#index', as: 'scrums', format: false

  put '*id/mercury_update', to: 'static_pages#mercury_update', as: 'static_page_mercury_update', format: false
  get '*id/mercury_saved', to: 'static_pages#mercury_saved', as: 'static_page_mercury_saved', format: false
  get 'sections', to: 'documents#get_doc_categories', as: 'project_document_sections', format: false
  put 'update_document_parent_id/:project_id/:id', to: 'documents#update_parent_id', as: 'update_document_parent_id',
                                                   format: false

  get '/calendar' => 'calendar#index'

  get '*id', to: 'static_pages#show', as: 'static_page', format: false
end
