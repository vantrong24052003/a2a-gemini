# 🎯 Gemini Studio - Multi-Agent AI System

Hệ thống điều phối AI agent sử dụng Rails + Gemini API để xây dựng ứng dụng web một cách tự động.

## 🏗 Kiến trúc tổng quan

```
[User Prompt] → [Gemini Studio] → [Cursor Agents]
                    ↓
            [Frontend Agent] [Backend Agent] [Tester Agent]
                    ↓
            [Kết quả hoàn thành]
```

## 🚀 Khởi động

### 1. Cài đặt dependencies
```bash
bundle install
```

### 2. Khởi động server
```bash
rails server
```

Server sẽ chạy tại: `http://localhost:3000`

## 📡 API Endpoints

### Root Endpoint
- `GET /` - Thông tin về Gemini Studio

### V1 API
- `POST /api/v1/prompts` - Tạo prompt mới
- `GET /api/v1/prompts/:id/status` - Kiểm tra trạng thái task
- `PUT /api/v1/agent_status` - Cập nhật trạng thái agent
- `GET /api/v1/agent_status/:task_id/:agent_name/task` - Lấy task cho agent

## 🔄 Workflow

### 1. Tạo Prompt
```bash
curl -X POST http://localhost:3000/api/v1/prompts \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Tạo trang bán mèo với giao diện đẹp và API xử lý đặt hàng"}'
```

### 2. Kiểm tra trạng thái
```bash
curl http://localhost:3000/api/v1/prompts/{task_id}/status
```

### 3. Agent báo cáo trạng thái
```bash
curl -X PUT http://localhost:3000/api/v1/agent_status \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "task_id_here",
    "agent_name": "frontend",
    "status": "completed",
    "message": "Đã tạo xong giao diện",
    "result_data": {"files": ["index.html", "style.css"]}
  }'
```

## 🧠 Các Agent

### Frontend Agent
- Nhận task từ file `shared/frontend_task_{task_id}.json`
- Tạo giao diện HTML/CSS/JS
- Báo cáo kết quả về Gemini Studio

### Backend Agent
- Nhận task từ file `shared/backend_task_{task_id}.json`
- Tạo API endpoints và database
- Báo cáo kết quả về Gemini Studio

### Tester Agent
- Được kích hoạt sau khi FE/BE hoàn thành
- Test integration và functionality
- Báo cáo kết quả test

## 📁 Cấu trúc thư mục

```
gemini/
├── app/
│   ├── controllers/
│   │   ├── api/v1/
│   │   │   ├── prompt_controller.rb
│   │   │   └── agent_status_controller.rb
│   │   └── prompt_controller.rb
│   └── services/
│       └── master_agent_service.rb
├── shared/           # File giao tiếp giữa các agent
├── logs/            # Log files
└── config/
    └── routes.rb
```

## 🔧 Cấu hình

### Gemini API Key
API key được cấu hình trong `MasterAgentService`:
```ruby
GEMINI_API_KEY = 'AIzaSyCiNaHKpr95bumQ49AD2uedr7aRTYo5OYc'
```

### Database (nếu cần)
```bash
rails db:create
rails db:migrate
```

## 📊 Monitoring

### Log files
- `logs/agent_status.log` - Trạng thái các agent
- `logs/development.log` - Rails logs

### Status files
- `shared/status_{task_id}.json` - Trạng thái tổng thể
- `shared/{agent}_task_{task_id}.json` - Task cho từng agent
- `shared/{agent}_result_{task_id}.json` - Kết quả từ agent

## 🎯 Ví dụ sử dụng

### Tạo ứng dụng bán mèo
```bash
# 1. Gửi prompt
curl -X POST http://localhost:3000/api/v1/prompts \
  -d '{"prompt": "Tạo trang web bán mèo với: giao diện đẹp, form đặt hàng, API xử lý đơn hàng, database lưu thông tin"}'

# 2. Lấy task_id từ response và kiểm tra trạng thái
curl http://localhost:3000/api/v1/prompts/{task_id}/status
```

## 🔄 Retry Logic

Nếu agent gặp lỗi:
1. Agent báo cáo status "failed"
2. Gemini Studio phân tích lỗi
3. Tạo prompt fix bug
4. Gửi lại task cho agent
5. Lặp lại cho đến khi thành công

## 🚀 Mở rộng

### Thêm Agent mới
1. Thêm agent vào `MasterAgentService`
2. Tạo method `send_task_to_{agent}_agent`
3. Cập nhật logic phân phối task

### Tích hợp với Cursor IDE
- Sử dụng file system để giao tiếp
- Hoặc implement WebSocket cho real-time
- Hoặc sử dụng message queue (Redis/RabbitMQ)

## 📝 License

MIT License
