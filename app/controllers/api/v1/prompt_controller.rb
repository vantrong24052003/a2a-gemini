module Api
  module V1
    class PromptController < ApplicationController
      def create
        user_prompt = params[:prompt]
        
        if user_prompt.blank?
          render json: { error: 'Prompt không được để trống' }, status: :bad_request
          return
        end

        # Khởi tạo Master Agent Service để xử lý
        master_service = MasterAgentService.new(user_prompt)
        result = master_service.process_prompt

        render json: {
          message: 'Prompt đã được nhận và đang xử lý',
          task_id: result[:task_id],
          status: result[:status],
          sub_tasks: result[:sub_tasks]
        }
      end

      def status
        task_id = params[:id]
        master_service = MasterAgentService.new(nil, task_id)
        status_info = master_service.get_status

        render json: status_info
      end

      def index
        render json: {
          message: 'Gemini Studio API v1',
          endpoints: {
            create_prompt: 'POST /api/v1/prompts',
            check_status: 'GET /api/v1/prompts/:id/status',
            update_agent_status: 'PUT /api/v1/agent_status',
            get_agent_task: 'GET /api/v1/agent_status/:task_id/:agent_name/task'
          }
        }
      end
    end
  end
end 
