# Makefile for MacCleaner

.PHONY: build install clean test run help

# Default target
.DEFAULT_GOAL := help

# Variables
BINARY_NAME = maccleaner
INSTALL_PATH = /usr/local/bin
BUILD_CONFIG = release

## help: Show this help message
help:
	@echo "MacCleaner - Available Make targets:"
	@echo ""
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'
	@echo ""

## build: Build the project in release mode
build:
	@echo "🏗️  Building MacCleaner..."
	swift build -c $(BUILD_CONFIG)
	@echo "✅ Build complete!"

## build-debug: Build the project in debug mode
build-debug:
	@echo "🏗️  Building MacCleaner (debug)..."
	swift build
	@echo "✅ Debug build complete!"

## install: Build and install to /usr/local/bin
install: build
	@echo "📦 Installing to $(INSTALL_PATH)/$(BINARY_NAME)..."
	@if [ ! -d "$(INSTALL_PATH)" ]; then \
		echo "Creating $(INSTALL_PATH)..."; \
		sudo mkdir -p $(INSTALL_PATH); \
	fi
	sudo cp .build/$(BUILD_CONFIG)/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME)
	sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✅ Installation complete!"
	@echo ""
	@echo "You can now run: $(BINARY_NAME) --help"

## uninstall: Remove installed binary
uninstall:
	@echo "🗑️  Uninstalling $(BINARY_NAME)..."
	sudo rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✅ Uninstalled!"

## clean: Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	@echo "✅ Clean complete!"

## clean-all: Clean build artifacts and user data
clean-all: clean
	@echo "🧹 Cleaning user data..."
	rm -rf ~/Library/Application\ Support/MacCleaner
	@echo "✅ All cleaned!"

## test: Run tests
test:
	@echo "🧪 Running tests..."
	swift test
	@echo "✅ Tests complete!"

## run: Build and run with default arguments
run: build
	@echo "🚀 Running MacCleaner..."
	.build/$(BUILD_CONFIG)/$(BINARY_NAME) --help

## scan: Quick scan of home directory
scan: build
	@echo "🔍 Scanning for large files..."
	.build/$(BUILD_CONFIG)/$(BINARY_NAME) scan --threshold 500

## status: Show storage status
status: build
	.build/$(BUILD_CONFIG)/$(BINARY_NAME) status

## stats: Show operation statistics
stats: build
	.build/$(BUILD_CONFIG)/$(BINARY_NAME) stats

## config: Show current configuration
config: build
	.build/$(BUILD_CONFIG)/$(BINARY_NAME) config --show

## setup-launchagent: Install LaunchAgent for weekly scans
setup-launchagent:
	@echo "🤖 Setting up LaunchAgent..."
	cp com.user.maccleaner.weekly.plist ~/Library/LaunchAgents/
	launchctl load ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
	@echo "✅ LaunchAgent installed! Will run weekly on Sunday at 10 AM"

## remove-launchagent: Remove LaunchAgent
remove-launchagent:
	@echo "🗑️  Removing LaunchAgent..."
	launchctl unload ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist 2>/dev/null || true
	rm -f ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
	@echo "✅ LaunchAgent removed!"

## format: Format Swift code
format:
	@echo "🎨 Formatting Swift code..."
	@command -v swift-format >/dev/null 2>&1 || { echo "swift-format not installed. Run: brew install swift-format"; exit 1; }
	swift-format -i -r Sources/
	@echo "✅ Formatting complete!"

## lint: Run SwiftLint
lint:
	@echo "🔍 Running SwiftLint..."
	@command -v swiftlint >/dev/null 2>&1 || { echo "swiftlint not installed. Run: brew install swiftlint"; exit 1; }
	swiftlint
	@echo "✅ Linting complete!"

## docs: Open documentation
docs:
	@echo "📚 Opening documentation..."
	open START_HERE.md

## version: Show version information
version:
	@echo "MacCleaner v1.0.0"
	@echo "Swift version:"
	@swift --version

## dev-setup: Set up development environment
dev-setup:
	@echo "⚙️  Setting up development environment..."
	@command -v swift >/dev/null 2>&1 || { echo "❌ Swift not installed"; exit 1; }
	@echo "✅ Swift installed"
	@command -v git >/dev/null 2>&1 || { echo "❌ Git not installed"; exit 1; }
	@echo "✅ Git installed"
	@echo ""
	@echo "Optional tools:"
	@command -v swift-format >/dev/null 2>&1 && echo "✅ swift-format installed" || echo "⚠️  swift-format not installed (optional)"
	@command -v swiftlint >/dev/null 2>&1 && echo "✅ swiftlint installed" || echo "⚠️  swiftlint not installed (optional)"
	@echo ""
	@echo "🎉 Development environment ready!"

## package-info: Show package information
package-info:
	@echo "📦 Package Information:"
	@echo ""
	swift package describe

## dependencies: Show package dependencies
dependencies:
	@echo "📚 Package Dependencies:"
	@echo ""
	swift package show-dependencies

## quick-install: Quick build and install (no prompts)
quick-install:
	@swift build -c release >/dev/null 2>&1
	@sudo cp .build/release/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME)
	@sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✅ Quick install complete!"

# Development shortcuts
.PHONY: b i c r s
b: build
i: install
c: clean
r: run
s: scan
