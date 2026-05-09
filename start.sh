#!/bin/bash

# OpenClaw Optimized Start Script for Mac Mini M4 (16GB)

echo "🛑 Stopping OpenClaw and Colima..."
docker-compose down
colima stop

echo "🧹 Clearing Ollama memory runners..."
pkill -9 -f "ollama runner"

echo "🚀 Starting Colima with optimized M4 settings (4GB RAM / 6 CPU)..."
colima start --cpu 6 --memory 4 --vm-type vz --mount-type virtiofs

echo "📦 Starting OpenClaw containers..."
docker-compose up -d

echo "✅ Startup Complete!"
echo "🌐 Web UI: http://localhost:3000"
open http://localhost:3000
echo "🔑 Please check config/openclaw.json for your Access Token."
echo "📊 Run 'ollama ps' to monitor model memory usage."
