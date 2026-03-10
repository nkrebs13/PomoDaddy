.PHONY: help setup build test test-coverage lint format format-check clean install-tools install-hooks security-check

help:
	@echo "PomoDaddy Development Commands:"
	@echo "  make setup          - Install dependencies and generate project"
	@echo "  make build          - Build the project"
	@echo "  make test           - Run all tests"
	@echo "  make test-coverage  - Run tests with coverage report"
	@echo "  make lint           - Run SwiftLint"
	@echo "  make format         - Format code with SwiftFormat"
	@echo "  make format-check   - Check code formatting"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make install-tools  - Install development tools"
	@echo "  make install-hooks  - Install pre-commit hooks"
	@echo "  make security-check - Run security scanning"

setup: install-tools
	@echo "📦 Generating Xcode project..."
	xcodegen generate
	@echo "✅ Setup complete!"

build:
	@echo "🔨 Building PomoDaddy..."
	xcodebuild build \
		-project PomoDaddy.xcodeproj \
		-scheme PomoDaddy \
		-configuration Debug \
		-destination 'platform=macOS'

test:
	@echo "🧪 Running tests..."
	xcodebuild test \
		-project PomoDaddy.xcodeproj \
		-scheme PomoDaddy \
		-configuration Debug \
		-destination 'platform=macOS' \
		| xcpretty

test-coverage:
	@echo "📊 Running tests with coverage..."
	xcodebuild test \
		-project PomoDaddy.xcodeproj \
		-scheme PomoDaddy \
		-configuration Debug \
		-destination 'platform=macOS' \
		-enableCodeCoverage YES \
		-resultBundlePath TestResults
	@echo "📈 Generating coverage report..."
	@xcrun xccov view --report TestResults.xcresult

lint:
	@echo "🔍 Running SwiftLint..."
	swiftlint lint --strict

format:
	@echo "✨ Formatting code..."
	swiftformat .
	@echo "✅ Code formatted!"

format-check:
	@echo "🔍 Checking code formatting..."
	swiftformat --lint .

clean:
	@echo "🧹 Cleaning..."
	rm -rf build/
	rm -rf DerivedData/
	rm -rf TestResults/
	xcodebuild clean \
		-project PomoDaddy.xcodeproj \
		-scheme PomoDaddy
	@echo "✅ Clean complete!"

install-tools:
	@echo "🔧 Installing development tools..."
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew required"; exit 1; }
	@brew install xcodegen swiftlint swiftformat xcpretty pre-commit || true
	@echo "✅ Tools installed!"

install-hooks:
	@echo "🪝 Installing pre-commit hooks..."
	@command -v pre-commit >/dev/null 2>&1 || { echo "Installing pre-commit..."; brew install pre-commit; }
	@pre-commit install
	@echo "✅ Pre-commit hooks installed!"

security-check:
	@echo "🔒 Running security scan..."
	@bash scripts/security-scan.sh
