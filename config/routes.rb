Rails.application.routes.draw do
  resources :hits, only: [:create, :show]

  get "reports/uploads", to: "reports#uploads"
end
