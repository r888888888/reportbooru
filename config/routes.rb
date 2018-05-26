Rails.application.routes.draw do
  resources :hits, only: [:create, :show]
  resources :post_views, only: [:create, :show]
  resource :post_searches, only: [:create, :show]
  resource :missed_searches, only: [:create, :show]
  resource :user_searches, only: [:show]

  get "reports/uploads", to: "reports#uploads"
  get "reports/user_similarity", to: "reports#user_similarity"
  get "reports/post_vote_similarity", to: "reports#post_vote_similarity"
  get "reports/status", to: "reports#status"
end
