class TaskOrchestratorService
  def initialize(task_id)
    @task_id = task_id
    @master_service = MasterAgentService.new(nil, task_id)
    @cursor_client = CursorAgentClient.new
  end

  def self.run(task_id)
    new(task_id).run
  end

  def run
    log_info("🚀 Bắt đầu điều phối task: #{@task_id}")

    loop do
      status_info = @master_service.get_status
      overall_status = status_info[:status]

      log_info("📊 Trạng thái hiện tại: #{overall_status}")

      case overall_status
      when "completed"
        handle_completion(status_info)
        break
      when "failed"
        handle_failure(status_info)
        break
      when "in_progress"
        handle_in_progress(status_info)
      when "pending"
        handle_pending(status_info)
      end

      sleep(10)
    end
  end

  private

  def handle_completion(status_info)
    log_info("🎉 Task hoàn thành! Gửi kết quả tổng hợp về IDE")

    aggregated_result = aggregate_results(status_info)

    @cursor_client.send_completion_result(@task_id, aggregated_result)

    log_info("✅ Đã gửi kết quả hoàn thành về IDE")
  end

  def handle_failure(status_info)
    log_info("❌ Task thất bại! Xử lý lỗi")

    failed_agents = status_info[:agents].select { |_, agent| agent[:status] == "failed" }

    failed_agents.each do |agent_name, agent_data|
      log_info("🔄 Retry agent: #{agent_name}")
      retry_agent(agent_name, agent_data)
    end
  end

  def handle_in_progress(status_info)
    agents = status_info[:agents]

    agents.each do |agent_name, agent_data|
      next unless agent_data[:status] == "started"

      if agent_stuck?(agent_data)
        log_info("⚠️ Agent #{agent_name} có vẻ bị stuck, gửi hỗ trợ")
        @cursor_client.send_support_message(@task_id, agent_name, "Agent có vẻ bị stuck, cần hỗ trợ")
      end
    end
  end

  def handle_pending(status_info)
    agents = status_info[:agents]

    agents.each do |agent_name, agent_data|
      next unless agent_data[:status] == "pending"

      if should_activate_agent?(agent_name, status_info)
        log_info("🚀 Kích hoạt agent: #{agent_name}")
        activate_agent(agent_name)
      end
    end
  end

  def aggregate_results(status_info)
    results = {}

    status_info[:agents].each do |agent_name, agent_data|
      result_file = "shared/#{agent_name}_result_#{@task_id}.json"

      if File.exist?(result_file)
        result_data = JSON.parse(File.read(result_file), symbolize_names: true)
        results[agent_name] = result_data[:result_data]
      end
    end

    {
      task_id: @task_id,
      overall_status: "completed",
      agent_results: results,
      summary: generate_summary(results),
      completed_at: Time.current.iso8601
    }
  end

  def generate_summary(results)
    summary = []

    if results[:frontend]
      summary << "✅ Frontend: #{results[:frontend][:files]&.join(', ') || 'Hoàn thành'}"
    end

    if results[:backend]
      summary << "✅ Backend: #{results[:backend][:endpoints]&.join(', ') || 'Hoàn thành'}"
    end

    if results[:tester]
      summary << "✅ Testing: #{results[:tester][:test_results] || 'Hoàn thành'}"
    end

    summary.join(" | ")
  end

  def retry_agent(agent_name, agent_data)
    @cursor_client.send_retry_signal(@task_id, agent_name, agent_data[:last_message])

    @master_service.update_agent_status(agent_name, "pending", "Đang retry...")
  end

  def agent_stuck?(agent_data)
    return false unless agent_data[:started_at]

    started_time = Time.parse(agent_data[:started_at])
    (Time.current - started_time) > 300
  end

  def should_activate_agent?(agent_name, status_info)
    case agent_name.to_sym
    when :tester
      frontend_done = status_info[:agents][:frontend][:status] == "completed"
      backend_done = status_info[:agents][:backend][:status] == "completed"
      frontend_done && backend_done
    else
      true
    end
  end

  def activate_agent(agent_name)
    @cursor_client.send_activation_signal(@task_id, agent_name)
  end

  def log_info(message)
    Rails.logger.info("[TaskOrchestrator] #{message}")
  end

  def log_error(message)
    Rails.logger.error("[TaskOrchestrator] #{message}")
  end
end
