#!/bin/bash

echo "🔨 Starting PromptForge..."
echo "================================"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or higher."
    exit 1
fi

# Navigate to API directory
cp env.ollama.js frontend/.env.js
cd api

# Install dependencies if needed
echo "📦 Installing dependencies..."
go mod tidy

# Start the server
echo "🚀 Starting PromptForge server..."
echo "📍 Server will be available at: http://localhost:8080"
echo "🔍 Critique endpoint: http://localhost:8080/api/critique"
echo "⚡ Execute endpoint: http://localhost:8080/api/execute"
echo ""
echo "Press Ctrl+C to stop the server"
echo "================================"

go build -o ../main main.go

cd .. && ./main