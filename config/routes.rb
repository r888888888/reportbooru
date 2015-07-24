Rails.application.routes.draw do
  resources :hits, only: [:create, :show] do
    collection do
      get :popular_by_day
      get :popular_by_week
      get :popular_by_year
    end
  end
end
