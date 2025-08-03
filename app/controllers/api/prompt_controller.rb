class Api::PromptController < ApplicationController
  def index
    render json: {
      message: "🎯 Gemini Studio - Multi-Agent AI System",
      description: "Hệ thống điều phối AI agent sử dụng Rails + Gemini API",
      version: "1.0.0",
      api_endpoints: {
        create_prompt: "POST /api/prompts",
        check_status: "GET /api/prompts/:id/status",
        update_agent_status: "PUT /api/agent_status",
        get_agent_task: "GET /api/agent_status/:task_id/:agent_name/task"
      },
      agents: {
        frontend: "Cursor Frontend Agent",
        backend: "Cursor Backend Agent",
        tester: "Testing Agent"
      },
      workflow: [
        "1. Nhận prompt từ user",
        "2. Phân tích thành sub-tasks",
        "3. Giao task cho các agent",
        "4. Theo dõi tiến độ",
        "5. Xử lý retry nếu có lỗi",
        "6. Hoàn thành và test"
      ]
    }
  end

  def create
    user_prompt = params[:prompt]

    if user_prompt.blank?
      render json: { error: "Prompt không được để trống" }, status: :bad_request
      return
    end

    # Khởi tạo Master Agent Service để xử lý
    master_service = MasterAgentService.new(user_prompt)
    result = master_service.process_prompt

    render json: {
      message: "Prompt đã được nhận và đang xử lý",
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
end
