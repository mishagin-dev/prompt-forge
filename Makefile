# PromptForge Makefile
# Cross-platform builds for Windows, Linux, and macOS

# Variables
APP_NAME = promptforge
# Clean version from latest tag (only v1.2.3 format)
VERSION = $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")
# If on main branch and no new tag, increment patch version
ifeq ($(shell git branch --show-current),main)
ifeq ($(shell git describe --tags --exact-match 2>/dev/null || echo "no-tag"),no-tag)
VERSION = $(shell git describe --tags --abbrev=0 2>/dev/null | awk -F. '{print $$1"."$$2"."$$3+1}' || echo "1.0.0")
endif
endif
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
	@# Windows package with ZIP format and proper structure
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64
	@cp $(DIST_DIR)/windows/$(APP_NAME).exe $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/.env
	@# Add Windows batch script
	@echo '@echo off' > $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'echo Starting PromptForge...' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'echo.' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'echo The application will create a SQLite database in this directory.' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'echo Make sure your .env file is configured with API keys.' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'echo.' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'promptforge.exe' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@echo 'pause' >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/start.bat
	@# Create comprehensive README
	@echo "PromptForge $(VERSION)" > $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "=== INSTALLATION ===" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "Windows:" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "1. Extract the ZIP file to a permanent location" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "2. Edit the .env file and add your API keys" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "3. Double-click start.bat OR run promptforge.exe from command line" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "4. Open http://localhost:8080 in your browser" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "=== IMPORTANT NOTES ===" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "- The binary MUST run from the extracted directory" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "- SQLite database (promptforge.db) will be created in the same directory" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "- The .env file must be in the same directory as the binary" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "- Do NOT move the binary after the database is created" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "=== TROUBLESHOOTING ===" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "If the application can't find its configuration:" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "1. Ensure you're running from the extracted directory" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "2. Check that .env file exists and is properly configured" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@echo "3. Run as Administrator if you encounter permission issues" >> $(BUILD_DIR)/packages/$(APP_NAME)-windows-amd64/README.txt
	@cd $(BUILD_DIR)/packages && zip -r $(APP_NAME)-$(VERSION)-windows-amd64.zip $(APP_NAME)-windows-amd64/
	@# Linux package with tar.gz format
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64
	@cp $(DIST_DIR)/linux/$(APP_NAME) $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-linux-amd64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-linux-amd64.tar.gz $(APP_NAME)-linux-amd64/
	@# macOS Intel package with tar.gz format
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64
	@cp $(DIST_DIR)/macos/$(APP_NAME) $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-darwin-amd64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-darwin-amd64.tar.gz $(APP_NAME)-darwin-amd64/
	@# macOS Apple Silicon package with tar.gz format
	@mkdir -p $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64
	@cp $(DIST_DIR)/macos/$(APP_NAME)-arm64 $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64/
	@cp .env.example $(BUILD_DIR)/packages/$(APP_NAME)-darwin-arm64/.env
	@cd $(BUILD_DIR)/packages && tar -czf $(APP_NAME)-$(VERSION)-darwin-arm64.tar.gz $(APP_NAME)-darwin-arm64/
	@echo "✅ Distribution packages created in $(BUILD_DIR)/packages/"
	@echo "📁 Windows: $(APP_NAME)-$(VERSION)-windows-amd64.zip"
	@echo "📁 Linux: $(APP_NAME)-$(VERSION)-linux-amd64.tar.gz"
	@echo "📁 macOS Intel: $(APP_NAME)-$(VERSION)-darwin-amd64.tar.gz"
	@echo "📁 macOS Apple Silicon: $(APP_NAME)-$(VERSION)-darwin-arm64.tar.gz"
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