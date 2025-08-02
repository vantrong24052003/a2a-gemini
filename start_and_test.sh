#!/bin/bash

echo "🚀 Starting Gemini Studio..."

# Check if Rails server is already running
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Rails server is already running on port 3000"
    echo "   Stopping existing server..."
    pkill -f "rails server"
    sleep 2
fi

# Start Rails server in background
echo "📡 Starting Rails server..."
cd "$(dirname "$0")"
rails server -p 3000 &
SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 5

# Check if server started successfully
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Rails server started successfully on port 3000"
    echo "   PID: $SERVER_PID"
    
    # Run API tests
    echo ""
    echo "🧪 Running API tests..."
    ruby test_api.rb
    
    echo ""
    echo "🎯 Gemini Studio is ready!"
    echo "   API Base URL: http://localhost:3000"
    echo "   Root endpoint: http://localhost:3000/"
    echo "   API v1: http://localhost:3000/api/v1"
    echo ""
    echo "📝 Example usage:"
    echo "   curl -X POST http://localhost:3000/api/v1/prompts \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"prompt\": \"Tạo trang web bán mèo\"}'"
    echo ""
    echo "🛑 To stop server: kill $SERVER_PID"
    
    # Keep script running
    wait $SERVER_PID
else
    echo "❌ Failed to start Rails server"
    exit 1
fi 
