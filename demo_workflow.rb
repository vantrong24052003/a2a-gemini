#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class GeminiStudioDemo
  BASE_URL = 'http://localhost:3000'

  def initialize
    @task_id = nil
  end

  def run_demo
    puts "🎯 Gemini Studio - Multi-Agent AI System Demo"
    puts "=" * 60

    step_1_create_prompt
    step_2_check_initial_status
    step_3_frontend_agent_completes
    step_4_backend_agent_completes
    step_5_tester_agent_completes
    step_6_final_status

    puts "\n" + "=" * 60
    puts "✅ Demo completed successfully!"
    puts "🎉 Gemini Studio is working perfectly!"
  end

  private

  def step_1_create_prompt
    puts "\n📝 Step 1: Creating prompt..."

    prompt_data = {
      prompt: "Tạo trang web bán mèo với: giao diện đẹp, form đặt hàng, API xử lý đơn hàng, database lưu thông tin khách hàng"
    }

    response = post('/api/v1/prompts', prompt_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      @task_id = data['task_id']
      puts "✅ Prompt created successfully"
      puts "   Task ID: #{@task_id}"
      puts "   Status: #{data['status']}"
      puts "   Sub tasks: #{data['sub_tasks'].length}"
    else
      puts "❌ Failed to create prompt: #{response.code}"
      exit 1
    end
  end

  def step_2_check_initial_status
    puts "\n🔍 Step 2: Checking initial status..."

    response = get("/api/v1/prompts/#{@task_id}/status")
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Status retrieved"
      puts "   Overall Status: #{data['status']}"
      puts "   Agents:"
      data['agents'].each do |agent_name, agent_data|
        puts "     #{agent_name}: #{agent_data['status']} - #{agent_data['last_message']}"
      end
    else
      puts "❌ Failed to get status: #{response.code}"
    end
  end

  def step_3_frontend_agent_completes
    puts "\n🎨 Step 3: Frontend agent completes..."

    status_data = {
      task_id: @task_id,
      agent_name: 'frontend',
      status: 'completed',
      message: 'Đã tạo xong giao diện HTML/CSS/JS với responsive design',
      result_data: {
        files: [ 'index.html', 'style.css', 'script.js', 'components/' ],
        features: [ 'responsive design', 'form validation', 'product gallery', 'shopping cart' ],
        technologies: [ 'HTML5', 'CSS3', 'JavaScript', 'Bootstrap' ]
      }
    }

    response = put('/api/v1/agent_status', status_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Frontend agent completed"
      puts "   Agent: #{data['agent']}"
      puts "   Status: #{data['status']}"
    else
      puts "❌ Failed to update frontend status: #{response.code}"
    end
  end

  def step_4_backend_agent_completes
    puts "\n⚙️  Step 4: Backend agent completes..."

    status_data = {
      task_id: @task_id,
      agent_name: 'backend',
      status: 'completed',
      message: 'Đã tạo xong API endpoints và database schema',
      result_data: {
        endpoints: [ '/api/products', '/api/orders', '/api/customers', '/api/auth' ],
        database: {
          tables: [ 'products', 'orders', 'customers', 'order_items' ],
          schema: 'PostgreSQL',
          migrations: 'completed'
        },
        technologies: [ 'Rails API', 'PostgreSQL', 'JWT Auth', 'Active Record' ]
      }
    }

    response = put('/api/v1/agent_status', status_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Backend agent completed"
      puts "   Agent: #{data['agent']}"
      puts "   Status: #{data['status']}"
    else
      puts "❌ Failed to update backend status: #{response.code}"
    end
  end

  def step_5_tester_agent_completes
    puts "\n🧪 Step 5: Tester agent completes..."

    status_data = {
      task_id: @task_id,
      agent_name: 'tester',
      status: 'completed',
      message: 'Đã test xong toàn bộ hệ thống - tất cả test cases passed',
      result_data: {
        test_results: {
          frontend_tests: '15/15 passed',
          backend_tests: '12/12 passed',
          integration_tests: '8/8 passed',
          e2e_tests: '5/5 passed'
        },
        coverage: '95%',
        performance: 'Load time < 2s',
        security: 'All security checks passed'
      }
    }

    response = put('/api/v1/agent_status', status_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Tester agent completed"
      puts "   Agent: #{data['agent']}"
      puts "   Status: #{data['status']}"
    else
      puts "❌ Failed to update tester status: #{response.code}"
    end
  end

  def step_6_final_status
    puts "\n🎯 Step 6: Final status check..."

    response = get("/api/v1/prompts/#{@task_id}/status")
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Final status retrieved"
      puts "   Task ID: #{data['task_id']}"
      puts "   Overall Status: #{data['status']}"
      puts "   All Agents:"
      data['agents'].each do |agent_name, agent_data|
        status_icon = agent_data['status'] == 'completed' ? '✅' : '❌'
        puts "     #{status_icon} #{agent_name}: #{agent_data['status']} - #{agent_data['last_message']}"
      end

      if data['status'] == 'completed'
        puts "\n🎉 SUCCESS: All agents completed successfully!"
        puts "🚀 The multi-agent system is working perfectly!"
      else
        puts "\n⚠️  WARNING: Some agents may not have completed"
      end
    else
      puts "❌ Failed to get final status: #{response.code}"
    end
  end

  def get(path)
    uri = URI("#{BASE_URL}#{path}")
    Net::HTTP.get_response(uri)
  end

  def post(path, data)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = data.to_json
    http.request(request)
  end

  def put(path, data)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = data.to_json
    http.request(request)
  end
end

# Run demo if this script is executed directly
if __FILE__ == $0
  demo = GeminiStudioDemo.new
  demo.run_demo
end
