.PHONY: help install start stop clean
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies (ollama, colima, docker), pull model, and setup .env
	@echo "🔍 Checking for Homebrew..."
	@command -v brew >/dev/null 2>&1 || { echo "❌ Homebrew not found. Please install it first: https://brew.sh/"; exit 1; }
	@echo "📦 Installing core dependencies..."
	brew install ollama colima docker docker-compose
	@echo "📥 Pulling recommended model (batiai/gemma4-e4b:q4)..."
	@echo "⚠️  Note: Ollama must be running for this to succeed."
	-ollama pull batiai/gemma4-e4b:q4
	@echo "⚙️ Setting up environment files..."
	@if [ ! -f .env ]; then cp .env.example .env && echo "✅ Created .env from .env.example"; else echo "ℹ️ .env already exists, skipping copy"; fi
	@echo "✨ Installation Complete!"

start: stop clean ## Stop existing services, clean runners, and start Colima/OpenClaw
	@echo "🚀 Starting Colima with optimized M4 settings (4GB RAM / 6 CPU)..."
	colima start --cpu 6 --memory 4 --vm-type vz --mount-type virtiofs
	@echo "📦 Starting OpenClaw containers..."
	docker-compose up -d
	@echo "✅ Startup Complete!"
	@echo "🌐 Web UI: http://localhost:3000"
	@open http://localhost:3000
	@echo "🔑 Please check config/openclaw.json for your Access Token."
	@echo "📊 Run 'ollama ps' to monitor model memory usage."

stop: ## Stop OpenClaw containers and Colima
	@echo "🛑 Stopping OpenClaw and Colima..."
	-docker-compose down
	-colima stop

clean: ## Kill Ollama memory runners
	@echo "🧹 Clearing Ollama memory runners..."
	-pkill -9 -f "ollama runner"
