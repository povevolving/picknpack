Rails.application.routes.draw do
  resources :batches
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  match '/batches/:id/print_labels' => 'batches#print_labels', via: :get, :as => :print_labels

  match 'test_label.:format' => 'batches#test_label', via: :get

  root :to => "batches#index"
end
