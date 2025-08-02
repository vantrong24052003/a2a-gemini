class AgentStatusController < ApplicationController
  def update
    task_id = params[:task_id]
    agent_name = params[:agent_name]
    status = params[:status]
    message = params[:message]
    result_data = params[:result_data]

    if task_id.blank? || agent_name.blank? || status.blank?
      render json: { error: 'Thiếu thông tin bắt buộc' }, status: :bad_request
      return
    end

    master_service = MasterAgentService.new(nil, task_id)
    success = master_service.update_agent_status(agent_name, status, message)

    if success
      # Lưu kết quả nếu có
      if result_data.present?
        save_agent_result(task_id, agent_name, result_data)
      end

      render json: { 
        message: 'Trạng thái đã được cập nhật',
        task_id: task_id,
        agent: agent_name,
        status: status
      }
    else
      render json: { error: 'Không thể cập nhật trạng thái' }, status: :unprocessable_entity
    end
  end

  def get_task
    task_id = params[:task_id]
    agent_name = params[:agent_name]

    task_file = "shared/#{agent_name}_task_#{task_id}.json"
    
    if File.exist?(task_file)
      task_data = JSON.parse(File.read(task_file), symbolize_names: true)
      render json: task_data
    else
      render json: { error: 'Không tìm thấy task' }, status: :not_found
    end
  end

  private

  def save_agent_result(task_id, agent_name, result_data)
    result_file = "shared/#{agent_name}_result_#{task_id}.json"
    FileUtils.mkdir_p('shared')
    
    result = {
      task_id: task_id,
      agent_name: agent_name,
      result_data: result_data,
      completed_at: Time.current.iso8601
    }
    
    File.write(result_file, result.to_json)
  end
end 
