require "net/http"
require "json"
require "uri"

class CursorAgentClient
  CURSOR_API_BASE = "http://localhost:3001"

  def initialize
    @http = Net::HTTP.new("localhost", 3001)
    @http.open_timeout = 10
    @http.read_timeout = 30
  end

  def send_completion_result(task_id, aggregated_result)
    message = {
      type: "task_completion",
      task_id: task_id,
      result: aggregated_result,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/notify", message)
  end

  def send_retry_signal(task_id, agent_name, error_message)
    message = {
      type: "retry_request",
      task_id: task_id,
      agent_name: agent_name,
      error_message: error_message,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/retry", message)
  end

  def send_activation_signal(task_id, agent_name)
    message = {
      type: "activation_request",
      task_id: task_id,
      agent_name: agent_name,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/activate", message)
  end

  def send_support_message(task_id, agent_name, support_message)
    message = {
      type: "support_request",
      task_id: task_id,
      agent_name: agent_name,
      message: support_message,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/support", message)
  end

  def send_new_task(task_id, agent_name, task_data)
    message = {
      type: "new_task",
      task_id: task_id,
      agent_name: agent_name,
      task_data: task_data,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/task", message)
  end

  def send_code_execution(task_id, agent_name, code_data)
    message = {
      type: "code_execution",
      task_id: task_id,
      agent_name: agent_name,
      code: code_data,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/execute", message)
  end

  def send_task_plan(task_id, agent_name, plan_data)
    message = {
      type: "task_plan",
      task_id: task_id,
      agent_name: agent_name,
      plan: plan_data,
      timestamp: Time.current.iso8601
    }

    send_to_cursor("/api/cursor/plan", message)
  end

  private

  def send_to_cursor(endpoint, data)
    begin
      uri = URI("#{CURSOR_API_BASE}#{endpoint}")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = data.to_json

      response = @http.request(request)

      if response.code == "200"
        log_info("✅ Gửi thành công đến Cursor: #{endpoint}")
        JSON.parse(response.body, symbolize_names: true)
      else
        log_error("❌ Lỗi gửi đến Cursor: #{response.code} - #{response.body}")
        nil
      end
    rescue => e
      log_error("❌ Lỗi kết nối Cursor: #{e.message}")
      nil
    end
  end

  def log_info(message)
    Rails.logger.info("[CursorClient] #{message}")
  end

  def log_error(message)
    Rails.logger.error("[CursorClient] #{message}")
  end
end
