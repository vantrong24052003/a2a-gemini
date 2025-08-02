Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Gemini Studio API Routes
  namespace :api do
    namespace :v1 do
      # Prompt processing
      post "/prompts", to: "prompt#create"
      get "/prompts/:id/status", to: "prompt#status"

      # Agent status updates
      put "/agent_status", to: "agent_status#update"
      get "/agent_status/:task_id/:agent_name/task", to: "agent_status#get_task"
    end
  end

  # Defines the root path route ("/")
  root "prompt#index"
end
