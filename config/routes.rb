Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Gemini Studio API Routes
  namespace :api do
    get "/", to: "prompt#index"
    post "/prompts", to: "prompt#create"
    get "/prompts/:id/status", to: "prompt#status"

    put "/agent_status", to: "agent_status#update"
    get "/agent_status/:task_id/:agent_name/task", to: "agent_status#get_task"
  end

  root "api/prompt#index"
end
