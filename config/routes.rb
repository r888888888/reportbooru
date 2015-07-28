Rails.application.routes.draw do
  resources :hits, only: [:create, :show]
end
