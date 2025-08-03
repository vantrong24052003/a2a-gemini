class MasterAgentService
  GEMINI_API_KEY = "AIzaSyCiNaHKpr95bumQ49AD2uedr7aRTYo5OYc"

  AgentStatus = Struct.new(:name, :status, :last_message, :started_at, :completed_at)

  def initialize(prompt = nil, task_id = nil)
    @prompt = prompt
    @task_id = task_id || SecureRandom.uuid
    @agents = {
      frontend: AgentStatus.new("frontend", "pending", "Chờ giao task", nil, nil),
      backend: AgentStatus.new("backend", "pending", "Chờ giao task", nil, nil),
      tester: AgentStatus.new("tester", "pending", "Chờ kết quả từ FE/BE", nil, nil)
    }
    @sub_tasks = []
    @overall_status = "pending"
  end

  def process_prompt
    return { error: "Prompt không được cung cấp" } unless @prompt

    begin
      @sub_tasks = analyze_prompt_with_gemini(@prompt)

      distribute_tasks_to_agents

      save_status

      start_task_orchestrator

      {
        task_id: @task_id,
        status: @overall_status,
        sub_tasks: @sub_tasks,
        agents: @agents.transform_values(&:to_h)
      }
    rescue => e
      log_error("Lỗi xử lý prompt: #{e.message}")
      { error: e.message }
    end
  end

  def get_status
    load_status
    {
      task_id: @task_id,
      status: @overall_status,
      agents: @agents.transform_values(&:to_h),
      sub_tasks: @sub_tasks
    }
  end

  def update_agent_status(agent_name, status, message)
    return false unless @agents[agent_name.to_sym]

    agent = @agents[agent_name.to_sym]
    agent.status = status
    agent.last_message = message

    case status
    when "started"
      agent.started_at = Time.current
    when "completed", "failed"
      agent.completed_at = Time.current
    end

    check_overall_completion

    save_status
    true
  end

  private

  def analyze_prompt_with_gemini(prompt)
    analysis_prompt = <<~PROMPT
      Phân tích prompt sau thành các task con cho Frontend, Backend và Testing:

      "#{prompt}"

      Trả về JSON với format:
      {
        "frontend_tasks": ["task1", "task2"],
        "backend_tasks": ["task1", "task2"],#{' '}
        "testing_tasks": ["task1", "task2"]
      }
    PROMPT

    mock_response = {
      frontend_tasks: extract_frontend_tasks(prompt),
      backend_tasks: extract_backend_tasks(prompt),
      testing_tasks: extract_testing_tasks(prompt)
    }

    [
      { type: "frontend", tasks: mock_response[:frontend_tasks] },
      { type: "backend", tasks: mock_response[:backend_tasks] },
      { type: "testing", tasks: mock_response[:testing_tasks] }
    ]
  end

  def extract_frontend_tasks(prompt)
    tasks = []
    tasks << "Tạo giao diện người dùng" if prompt.match?(/giao diện|ui|frontend|react|vue/i)
    tasks << "Tạo form nhập liệu" if prompt.match?(/form|nhập|input/i)
    tasks << "Tạo trang landing" if prompt.match?(/landing|trang chủ|home/i)
    tasks << "Tạo responsive design" if prompt.match?(/responsive|mobile/i)
    tasks.empty? ? [ "Tạo giao diện cơ bản" ] : tasks
  end

  def extract_backend_tasks(prompt)
    tasks = []
    tasks << "Tạo API endpoints" if prompt.match?(/api|backend|server/i)
    tasks << "Thiết lập database" if prompt.match?(/database|db|dữ liệu/i)
    tasks << "Tạo authentication" if prompt.match?(/auth|đăng nhập|login/i)
    tasks << "Xử lý business logic" if prompt.match?(/logic|xử lý|process/i)
    tasks.empty? ? [ "Tạo API cơ bản" ] : tasks
  end

  def extract_testing_tasks(prompt)
    tasks = []
    tasks << "Test giao diện" if prompt.match?(/test|kiểm thử/i)
    tasks << "Test API endpoints" if prompt.match?(/api|backend/i)
    tasks << "Test integration" if prompt.match?(/integration|tích hợp/i)
    tasks.empty? ? [ "Test tổng thể hệ thống" ] : tasks
  end

  def distribute_tasks_to_agents
    @sub_tasks.each do |sub_task|
      case sub_task[:type]
      when "frontend"
        @agents[:frontend].status = "started"
        @agents[:frontend].last_message = "Đang xử lý: #{sub_task[:tasks].join(', ')}"
        send_task_to_frontend_agent(sub_task)
      when "backend"
        @agents[:backend].status = "started"
        @agents[:backend].last_message = "Đang xử lý: #{sub_task[:tasks].join(', ')}"
        send_task_to_backend_agent(sub_task)
      when "testing"
        @agents[:tester].last_message = "Chờ kết quả từ Frontend và Backend"
      end
    end
  end

  def send_task_to_frontend_agent(sub_task)
    task_file = "shared/frontend_task_#{@task_id}.json"
    FileUtils.mkdir_p("shared")

    File.write(task_file, {
      task_id: @task_id,
      tasks: sub_task[:tasks],
      original_prompt: @prompt,
      timestamp: Time.current.iso8601
    }.to_json)

    log_info("Task đã gửi cho Frontend Agent: #{task_file}")
  end

  def send_task_to_backend_agent(sub_task)
    task_file = "shared/backend_task_#{@task_id}.json"
    FileUtils.mkdir_p("shared")

    File.write(task_file, {
      task_id: @task_id,
      tasks: sub_task[:tasks],
      original_prompt: @prompt,
      timestamp: Time.current.iso8601
    }.to_json)

    log_info("Task đã gửi cho Backend Agent: #{task_file}")
  end

  def check_overall_completion
    frontend_done = @agents[:frontend].status == "completed"
    backend_done = @agents[:backend].status == "completed"

    if frontend_done && backend_done
      @agents[:tester].status = "started"
      @agents[:tester].last_message = "Bắt đầu testing integration"
      @agents[:tester].started_at = Time.current

      send_task_to_tester_agent
    end

    if @agents.values.all? { |agent| agent.status == "completed" }
      @overall_status = "completed"
    elsif @agents.values.any? { |agent| agent.status == "failed" }
      @overall_status = "failed"
    else
      @overall_status = "in_progress"
    end
  end

  def send_task_to_tester_agent
    task_file = "shared/tester_task_#{@task_id}.json"
    FileUtils.mkdir_p("shared")

    File.write(task_file, {
      task_id: @task_id,
      frontend_status: @agents[:frontend].to_h,
      backend_status: @agents[:backend].to_h,
      original_prompt: @prompt,
      timestamp: Time.current.iso8601
    }.to_json)

    log_info("Task đã gửi cho Tester Agent: #{task_file}")
  end

  def save_status
    status_file = "shared/status_#{@task_id}.json"
    FileUtils.mkdir_p("shared")

    status_data = {
      task_id: @task_id,
      prompt: @prompt,
      overall_status: @overall_status,
      agents: @agents.transform_values(&:to_h),
      sub_tasks: @sub_tasks,
      updated_at: Time.current.iso8601
    }

    File.write(status_file, status_data.to_json)
  end

  def load_status
    status_file = "shared/status_#{@task_id}.json"
    return unless File.exist?(status_file)

    status_data = JSON.parse(File.read(status_file), symbolize_names: true)
    @prompt = status_data[:prompt]
    @overall_status = status_data[:overall_status]
    @sub_tasks = status_data[:sub_tasks]

    status_data[:agents].each do |agent_name, agent_data|
      @agents[agent_name.to_sym] = AgentStatus.new(
        agent_data[:name],
        agent_data[:status],
        agent_data[:last_message],
        agent_data[:started_at] ? Time.parse(agent_data[:started_at]) : nil,
        agent_data[:completed_at] ? Time.parse(agent_data[:completed_at]) : nil
      )
    end
  end

  def log_info(message)
    Rails.logger.info("[GeminiStudio] #{message}")
  end

  def start_task_orchestrator
    Thread.new do
      begin
        TaskOrchestratorService.run(@task_id)
      rescue => e
        log_error("Lỗi TaskOrchestrator: #{e.message}")
      end
    end
  end

  def log_error(message)
    Rails.logger.error("[GeminiStudio] #{message}")
  end
end
