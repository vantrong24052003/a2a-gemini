#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class GeminiStudioTester
  BASE_URL = 'http://localhost:3000'

  def initialize
    @task_id = nil
  end

  def test_root_endpoint
    puts "🔍 Testing root endpoint..."
    response = get('/')
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Root endpoint OK"
      puts "   Message: #{data['message']}"
      puts "   Version: #{data['version']}"
    else
      puts "❌ Root endpoint failed: #{response.code}"
    end
  end

  def test_create_prompt
    puts "\n🔍 Testing create prompt..."

    prompt_data = {
      prompt: "Tạo trang web bán mèo với giao diện đẹp, form đặt hàng và API xử lý đơn hàng"
    }

    response = post('/api/v1/prompts', prompt_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      @task_id = data['task_id']
      puts "✅ Create prompt OK"
      puts "   Task ID: #{@task_id}"
      puts "   Status: #{data['status']}"
      puts "   Sub tasks: #{data['sub_tasks'].length}"
    else
      puts "❌ Create prompt failed: #{response.code}"
      puts "   Response: #{response.body}"
    end
  end

  def test_check_status
    return unless @task_id

    puts "\n🔍 Testing check status..."
    response = get("/api/v1/prompts/#{@task_id}/status")
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Check status OK"
      puts "   Task ID: #{data['task_id']}"
      puts "   Overall Status: #{data['status']}"
      puts "   Agents:"
      data['agents'].each do |agent_name, agent_data|
        puts "     #{agent_name}: #{agent_data['status']} - #{agent_data['last_message']}"
      end
    else
      puts "❌ Check status failed: #{response.code}"
    end
  end

  def test_agent_status_update
    return unless @task_id

    puts "\n🔍 Testing agent status update..."

    status_data = {
      task_id: @task_id,
      agent_name: 'frontend',
      status: 'completed',
      message: 'Đã tạo xong giao diện HTML/CSS',
      result_data: {
        files: [ 'index.html', 'style.css', 'script.js' ],
        features: [ 'responsive design', 'form validation' ]
      }
    }

    response = put('/api/v1/agent_status', status_data)
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Agent status update OK"
      puts "   Agent: #{data['agent']}"
      puts "   Status: #{data['status']}"
    else
      puts "❌ Agent status update failed: #{response.code}"
      puts "   Response: #{response.body}"
    end
  end

  def test_get_agent_task
    return unless @task_id

    puts "\n🔍 Testing get agent task..."
    response = get("/api/v1/agent_status/#{@task_id}/frontend/task")
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ Get agent task OK"
      puts "   Task ID: #{data['task_id']}"
      puts "   Tasks: #{data['tasks'].join(', ')}"
    else
      puts "❌ Get agent task failed: #{response.code}"
    end
  end

  def run_all_tests
    puts "🚀 Starting Gemini Studio API Tests"
    puts "=" * 50

    test_root_endpoint
    test_create_prompt
    test_check_status
    test_agent_status_update
    test_check_status  # Check again after update
    test_get_agent_task

    puts "\n" + "=" * 50
    puts "✅ All tests completed!"
  end

  private

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

# Run tests if this script is executed directly
if __FILE__ == $0
  tester = GeminiStudioTester.new
  tester.run_all_tests
end
