.PHONY: help install start reset stop clean ollama-start ollama-stop
.DEFAULT_GOAL := help

# Memory limits for M4 Apple Silicon (Default: 8GB VRAM)
OLLAMA_MAX_VRAM ?= 8589934592

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
	@echo "📥 Pulling recommended demo model (qwen3.5:0.8b)..."
	@echo "⚠️  Note: Ollama must be running for this to succeed."
	-ollama pull qwen3.5:0.8b
	@echo "⚙️ Setting up environment files..."
	@if [ ! -f .env ]; then cp .env.example .env && echo "✅ Created .env from .env.example"; else echo "ℹ️ .env already exists, skipping copy"; fi
	@echo "✨ Installation Complete!"

ollama-start: ## Start Ollama with VRAM limit (run this in a separate terminal)
	@echo "🚀 Starting Ollama with $(OLLAMA_MAX_VRAM) bytes VRAM limit..."
	OLLAMA_MAX_VRAM=$(OLLAMA_MAX_VRAM) ollama serve

ollama-stop: ## Stop the Ollama server
	@echo "🛑 Stopping Ollama server..."
	-pkill -9 -f "ollama serve"

start: stop clean ## Stop existing services, clean runners, and start Colima/OpenClaw
	@echo "🚀 Starting Colima with optimized M4 settings (6 CPU / 4GB RAM)..."
	colima start --cpu 6 --memory 4 --vm-type vz --mount-type virtiofs
	@echo "⚙️ Pre-configuring OpenClaw..."
	@mkdir -p config
	@if [ ! -f config/openclaw.json ]; then \
		printf '{\n  "gateway": {\n    "controlUi": {\n      "allowedOrigins": ["http://localhost:18789","http://127.0.0.1:18789","http://localhost:3000","http://127.0.0.1:3000"]\n    }\n  },\n  "agents": {\n    "defaults": {\n      "model": {\n        "primary": "ollama/qwen3.5:0.8b"\n      },\n      "thinkingDefault": "off",\n      "bootstrapMaxChars": 2000,\n      "bootstrapTotalMaxChars": 8000,\n      "experimental": {\n        "localModelLean": true\n      }\n    }\n  },\n  "models": {\n    "providers": {\n      "ollama": {\n        "baseUrl": "http://host.docker.internal:11434",\n        "models": [{"id":"qwen3.5:0.8b","name":"Qwen 3.5 0.8B","api":"ollama","contextTokens":16384}]\n      }\n    }\n  },\n  "tools": {\n    "profile": "coding"\n  }\n}\n' > config/openclaw.json; \
	else \
		echo "ℹ️ Existing config/openclaw.json found; preserving token and local settings"; \
	fi
	@echo "📦 Starting OpenClaw containers..."
	docker-compose up -d
	@echo "🩹 Finalizing configuration health..."
	@sleep 10 && docker exec openclaw openclaw doctor --fix
	@echo "✅ Startup Complete!"
	@echo "🌐 Web UI: http://localhost:3000"
	@open http://localhost:3000
	@echo "🔑 Please check config/openclaw.json for your Access Token."
	@echo "📊 Run 'ollama ps' to monitor model memory usage."

reset: ## Wipe all data (config/sandbox) and start fresh
	@echo "🧨 Resetting environment..."
	-docker-compose down -v
	@echo "🧹 Cleaning directories..."
	-rm -rf config/* sandbox/*
	@$(MAKE) start

stop: ## Stop OpenClaw containers and Colima
	@echo "🛑 Stopping OpenClaw and Colima..."
	-docker-compose down
	-colima stop

clean: ## Kill Ollama model runners
	@echo "🧹 Clearing Ollama model runners..."
	-pkill -9 -f "ollama runner"
