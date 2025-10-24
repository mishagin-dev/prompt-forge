#!/bin/bash

echo "🔨 Starting PromptForge..."
echo "================================"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.25.3 or higher."
    exit 1
fi

# Check if Make is available
if command -v make &> /dev/null; then
    echo "🏗️  Using Makefile for build..."

    # Build development version using Makefile (includes frontend preparation)
    make dev

    # Copy .env file to project root (where the binary will be)
    if [ -f ".env" ]; then
        echo "📄 .env file already exists in project root"
    else
        if [ -f "api/.env" ]; then
            cp api/.env .env
            echo "📄 Copied .env file to project root"
        else
            echo "⚠️  No .env file found. Please create one from .env.example"
        fi
    fi

    echo "🚀 Starting PromptForge server..."
    echo "📍 Server will be available at: http://localhost:8080"
    echo "🔍 Critique endpoint: http://localhost:8080/api/critique"
    echo "⚡ Execute endpoint: http://localhost:8080/api/execute"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo "================================"

    # Start server
    ./main
else
    echo "⚠️  Make not found, using fallback build method..."

    # Navigate to API directory
    cd api

    # Install dependencies if needed
    echo "📦 Installing dependencies..."
    go mod tidy

    # Build binary
    go build -o ../main main.go

    cd ..

    # Copy .env file to project root (where the binary will be)
    if [ -f ".env" ]; then
        echo "📄 .env file already exists in project root"
    else
        if [ -f "api/.env" ]; then
            cp api/.env .env
            echo "📄 Copied .env file to project root"
        else
            echo "⚠️  No .env file found. Please create one from .env.example"
        fi
    fi

    echo "🚀 Starting PromptForge server..."
    echo "📍 Server will be available at: http://localhost:8080"
    echo "🔍 Critique endpoint: http://localhost:8080/api/critique"
    echo "⚡ Execute endpoint: http://localhost:8080/api/execute"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo "================================"

    # Start the server
    ./main
fi