# PromptForge Makefile
# Cross-platform builds for Windows, Linux, and macOS

# Variables
APP_NAME = promptforge
VERSION = $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME = $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS = -ldflags="-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)"

# Build directories
BUILD_DIR = build
DIST_DIR = $(BUILD_DIR)/dist

# Build targets
.PHONY: build clean clean-frontend deps test run help all windows linux macos dev package install

# Default target
all: clean deps windows linux macos package clean-frontend

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	cd api && go mod tidy
	@echo "🔨 Copying frontend..."
	@cp -r frontend api/

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f main $(APP_NAME) $(APP_NAME).exe

# Clean frontend files from api
clean-frontend:
	@echo "🗑️  Cleaning frontend from api..."
	@rm -rf api/frontend

# Windows build
windows: deps
	@echo "🪟 Building for Windows..."
	@mkdir -p $(DIST_DIR)/windows
	cd api && GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o ../$(DIST_DIR)/windows/$(APP_NAME).exe main.go
	@echo "✅ Windows binary created: $(DIST_DIR)/windows/$(APP_NAME).exe"

# Linux build
linux: deps
	@echo "🐧 Building for Linux..."
	@mkdir -p $(DIST_DIR)/linux
	cd api && GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o ../$(DIST_DIR)/linux/$(APP_NAME) main.go
	@echo "✅ Linux binary created: $(DIST_DIR)/linux/$(APP_NAME)"

# macOS build
macos: deps
	@echo "🍎 Building for macOS..."
	@mkdir -p $(DIST_DIR)/macos
	cd api && GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o ../$(DIST_DIR)/macos/$(APP_NAME) main.go
	cd api && GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o ../$(DIST_DIR)/macos/$(APP_NAME)-arm64 main.go
	@echo "✅ macOS binaries created:"
	@echo "   - Intel: $(DIST_DIR)/macos/$(APP_NAME)"
	@echo "   - Apple Silicon: $(DIST_DIR)/macos/$(APP_NAME)-arm64"

# Current platform build
build: deps
	@echo "🔨 Building for current platform..."
	cd api && go build $(LDFLAGS) -o ../$(APP_NAME) main.go
	@echo "✅ Binary created: $(APP_NAME)"

# Development build (current platform)
dev: deps
	@echo "🔨 Building development version..."
	cd api && go build -o ../main main.go
	@echo "✅ Development binary created: main"
	@echo "🗑️  Cleaning frontend from api..."
	@rm -rf api/frontend

# Run development server
run:
	@echo "🚀 Starting PromptForge server..."
	@echo "📦 Database initialized successfully"
	@echo "🧠 Enhanced prompt analyzer ready"
	@echo "🤖 AI Providers: OpenAI, Azure OpenAI, Anthropic"
	@echo "🚀 Starting PromptForge server..."
	@echo "📍 Server will be available at: http://localhost:8080"
	@echo "🔍 Critique endpoint: http://localhost:8080/api/critique"
	@echo "⚡ Execute endpoint: http://localhost:8080/api/execute"
	@echo ""
	@echo "Press Ctrl+C to stop the server"
	@echo "================================"
	./start.sh

# Test
test:
	@echo "🧪 Running tests..."
	cd api && go test -v ./...

# Install to /usr/local (for macOS/Linux)
install: build
	@echo "📥 Installing to /usr/local/bin..."
	sudo cp $(APP_NAME) /usr/local/bin/
	@echo "✅ $(APP_NAME) installed to /usr/local/bin/$(APP_NAME)"

# Create distribution packages
package: all
	@echo "📦 Creating distribution packages..."
	@mkdir -p $(BUILD_DIR)/packages
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64
	@cp $(DIST_DIR)/windows/$(APP_NAME).exe $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-windows-amd64.tar.gz $(APP_NAME)-windows-amd64/
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64
	@cp $(DIST_DIR)/linux/$(APP_NAME) $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-linux-amd64.tar.gz $(APP_NAME)-linux-amd64/
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64
	@cp $(DIST_DIR)/macos/$(APP_NAME) $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-darwin-amd64.tar.gz $(APP_NAME)-darwin-amd64/
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64
	@cp $(DIST_DIR)/macos/$(APP_NAME)-arm64 $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-darwin-arm64.tar.gz $(APP_NAME)-darwin-arm64/
	@echo "✅ Distribution packages created in $(BUILD_DIR)/packages/"
	@ls -la $(BUILD_DIR)/packages/

# Show help
help:
	@echo "📚 PromptForge Makefile Commands:"
	@echo ""
	@echo "  build      - Build for current platform"
	@echo "  dev        - Build development version"
	@echo "  windows    - Build for Windows (amd64)"
	@echo "  linux      - Build for Linux (amd64)"
	@echo "  macos      - Build for macOS (Intel + Apple Silicon)"
	@echo "  all        - Build for all platforms"
	@echo "  package    - Create distribution packages"
	@echo "  run        - Run development server"
	@echo "  test       - Run tests"
	@echo "  clean      - Clean build artifacts"
	@echo "  clean-frontend - Clean frontend from api"
	@echo "  deps       - Install dependencies"
	@echo "  install    - Install to /usr/local/bin"
	@echo "  after      - Clean up after builds"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make dev       # Build development version"
	@echo "  make all       # Build for all platforms"
	@echo "  make package   # Build and create distribution packages"