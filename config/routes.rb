Rails.application.routes.draw do
  resources :users do
    resources :books # , only: [ :index, :show ]
  end
  root "users#index"
end
