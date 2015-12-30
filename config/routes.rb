Rails.application.routes.draw do
  resources :hits, only: [:create, :show]

  get "reports/uploads", to: "reports#uploads"
  get "reports/user_similarity", to: "reports#user_similarity"
end
