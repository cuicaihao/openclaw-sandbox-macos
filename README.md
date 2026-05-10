# 🦞 OpenClaw Sandbox - Mac Mini M4 (16GB)

[English](README.md) / [中文](README.zh.md)

**OpenClaw Sandbox** is a highly optimized local AI Agent development and execution environment, deeply customized for **Apple Silicon (M4 chip)** hardware features. It aims to provide a **low-power, high-performance, and high-privacy** local inference solution. By physically and logically decoupling the inference engine (Ollama) from the execution logic (OpenClaw), we have successfully achieved smooth operation of complex long-context AI workflows even under the 16GB unified memory limitation.

![feature](feature.png)

> 💡 **Project Positioning & Core Purpose**
> This is a sandbox environment configuration guide optimized specifically for the **Apple Mac Mini M4 (16GB RAM)**, intended to provide a structured and easy-to-understand reference manual.
> This project serves primarily as a sandbox for **exploration and learning**, helping **individual users** and developers quickly get started and intuitively understand the basic principles, operating mechanisms, and hybrid architecture design of OpenClaw with very low hardware barriers.

⚠️ **Please Note: This project configuration is NOT for production use.**
Due to the physical bottleneck of 16GB unified memory, the concurrent processing limitations of single-node local LLMs, and the lack of enterprise-grade high availability (HA), rigorous data security, and distributed scheduling in a sandbox environment, do not apply this solution directly to formal production services. To deploy OpenClaw or similar AI Agent services in production, it is recommended to use professional server clusters or cloud-native infrastructure, accompanied by robust monitoring, authentication, and load balancing systems.

---

## Project Structure

```text
.
├── config/                  # Stores tokens, history, and learned knowledge (Ignored by Git)
│   ├── memory/              # SQLite databases
│   └── openclaw.json        # Auto-generated configuration with Access Token
├── sandbox/                 # The Agent's isolated workspace for file operations (Ignored by Git)
├── .env.example             # Example environment variables
├── docker-compose.yml       # Docker Compose configuration for OpenClaw
├── Makefile                 # Make commands for setup and maintenance
├── feature.png              # Project feature image
├── README.md                # English documentation
└── README.zh.md             # Chinese documentation
```

## 📋 I. Prerequisites

Before starting, ensure your macOS has the following core components installed. This project is specifically optimized for Apple Silicon and the M4 unified memory architecture.

### 1. Required Dependencies

I recommend macOS users use `brew` to install dependencies.

| Tool | Purpose | Installation Check |
| :--- | :--- | :--- |
| **Homebrew** | macOS Package Manager | `brew --version` |
| **Ollama** | Local LLM Inference Engine (Native) | `ollama --version` |
| **Colima** | Lightweight Docker VM (Optimized for M4) | `colima --version` |
| **Docker CLI** | Container operation CLI | `docker --version` |

---

### 2. Installation Steps

Alternatively, you can use `make` to automatically install dependencies (refer to the Makefile; it's recommended to check the specific commands first):

```bash
❯ make
Usage: make [target]

Targets:
  clean           Kill Ollama model runners
  help            Show this help message
  install         Install dependencies (ollama, colima, docker), pull model, and setup .env
  ollama-start    Start Ollama with VRAM limit (run this in a separate terminal)
  ollama-stop     Stop the Ollama server
  reset           Wipe all data (config/sandbox) and start fresh
  start           Stop existing services, clean runners, and start Colima/OpenClaw
  stop            Stop OpenClaw containers and Colima
```

### 3. Manual Installation Steps

* **Step 1: Install Homebrew** (if not installed):

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

* **Step 2: Install Ollama**:

    ```bash
    brew install ollama
    # Start the service
    ollama serve
    ```

* **Step 3: Pull Recommended Demo Model**:

    ```bash
    # Lightweight default for this demo sandbox
    ollama pull qwen3.5:0.8b
    ```

* **Step 4: Install Colima & Docker**:

    ```bash
    brew install colima docker docker-compose
    ```

* **Step 5: Configure Environment Variables**:

    Copy the example environment file and modify as needed (especially UID/GID):

    ```bash
    cp .env.example .env
    ```

---

## 🚀 II. Getting Started

### 1. Makefile Start (Recommended)

The environment is fully automated through the Makefile. Use `make start` to stop existing services, clear Ollama runners, start Colima with the optimized hardware flags, pre-configure OpenClaw, and launch the container stack.

```bash
make start
```

### 2. Manual Start Steps

If you need manual control, follow these steps in order:

* **Start Colima**:

    ```bash
    colima start --cpu 6 --memory 4 --vm-type=vz --mount-type=virtiofs
    ```

* **Start Docker Stack**:

    ```bash
    docker-compose up -d
    ```

### 3. Access Web UI

* **URL**: [http://localhost:3000](http://localhost:3000)
* **Access Token**: Automatically generated after the first run, usually saved in `config/openclaw.json`:

```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "YOUR_GENERATED_TOKEN_HERE"
    }
  }
}
```

---

## 🗺️ III. Architecture Overview

### 1. Why Hybrid Architecture?

Running **Ollama natively** on Apple Silicon significantly improves Metal GPU utilization and reduces file I/O latency.

| Component | Execution Environment | Core Responsibility |
| :--- | :--- | :--- |
| **Ollama** | macOS Host (Native) | GPU Accelerated Inference (Metal GPU) |
| **Colima VM** | Virtualization Layer (vz) | Provides lightweight Linux environment |
| **OpenClaw** | Docker Container | AI Agent logic orchestration & sandbox isolation |

### 2. Why Colima instead of Docker Desktop?

On a 16GB Mac Mini, every megabyte of RAM matters. Colima offers significant advantages over Docker Desktop:

* **Lower Memory Overhead**: Colima is a lightweight VM without heavy background processes, freeing up more memory for local LLMs (Ollama).
* **Better Apple Silicon Integration**: By using macOS's native `vz` virtualization framework, Colima runs with minimal CPU overhead.
* **Superior File I/O Performance**: With `virtiofs`, the Agent's speed for reading/writing code in `./sandbox` is close to native disk speed, which is crucial for AI workflows involving frequent compilation and execution.
* **Hard Resource Limits**: Colima allows precise control over VM resource usage, ensuring Docker never "cannibalizes" the unified GPU memory belonging to Ollama.

### 3. System Diagram

```mermaid
flowchart LR
    classDef user fill:#fafafa,stroke:#616161,color:#212121,stroke-width:2px;
    classDef host fill:#f3f4f6,stroke:#374151,color:#111827,stroke-width:3px;
    classDef compute fill:#ede9fe,stroke:#7c3aed,color:#4c1d95,stroke-width:2px;
    classDef vm fill:#dbeafe,stroke:#2563eb,color:#1e3a8a,stroke-width:2px;
    classDef docker fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px;
    classDef storage fill:#ffedd5,stroke:#ea580c,color:#9a3412,stroke-width:2px;
    classDef tmp fill:#ecfccb,stroke:#65a30d,color:#365314,stroke-width:2px;

    User(("👤 User")):::user
    Browser["🌐 Browser<br/>localhost:3000"]:::user
    User --> Browser

    subgraph Host["💻 Mac Mini M4 Host"]
        direction TB
        subgraph Compute["🚀 Native AI Inference Layer"]
            direction TB
            Ollama["🦙 Ollama<br/>Native macOS service<br/>Metal GPU acceleration<br/>qwen3.5:0.8b • 16k default"]:::compute
        end
        subgraph VM["🖥️ Colima VM"]
            direction TB
            VMConfig["⚙️ 6 vCPU • 4GB RAM<br/>vz + virtiofs"]:::vm
            subgraph Docker["🐳 Docker Runtime"]
                direction TB
                OpenClaw["🦞 OpenClaw Container<br/>Node.js Gateway<br/>2 CPU / 3GB limit<br/>read-only rootfs"]:::docker
                TmpFS[("⚡ tmpfs<br/>ephemeral /tmp")]:::tmp
            end
        end
        subgraph Storage["📁 macOS Bind-Mounted Storage"]
            direction LR
            Config["🧠 ./config<br/>OpenClaw home<br/>config + tokens + memory"]:::storage
            Workspace["🛠️ ./sandbox<br/>Agent workspace<br/>created/edited files"]:::storage
        end
    end

    Browser -->|"HTTP :3000 → :18789"| OpenClaw
    OpenClaw -->|"Ollama API<br/>host.docker.internal:11434"| Ollama
    OpenClaw -.->|"Bind mount<br/>/home/node/.openclaw"| Config
    OpenClaw -.->|"Bind mount<br/>/home/node/.openclaw/workspace"| Workspace
    OpenClaw --- TmpFS

    style Host fill:#f9fafb,stroke:#111827,stroke-width:4px
    style Compute fill:#ede9fe,stroke:#7c3aed,stroke-width:3px
    style VM fill:#dbeafe,stroke:#2563eb,stroke-width:3px
    style Docker fill:#dcfce7,stroke:#16a34a,stroke-width:3px
    style Storage fill:#ffedd5,stroke:#ea580c,stroke-width:3px
```

---

## 🧠 IV. Memory & Context Management

In the 16GB Unified Memory (UMA) architecture, preventing memory pressure and Swap is key to maintaining performance. A larger context window can keep longer chats alive, but it also increases latency and memory pressure; it does **not** make a tiny model reason better.

### 1. ⚠️ RAM Monitoring Levels

Please run `ollama ps` regularly to check the loaded model and active context:

| Status | Context Size | Memory Usage | System Performance |
| :--- | :--- | :--- | :--- |
| **Recommended** | 16384 (16k) | Moderate memory footprint | Good default for this 16GB demo setup |
| **Experimental** | 24576 - 32768 (24k - 32k) | Higher memory pressure | Useful for longer chats; watch macOS memory pressure |
| **Risky** | 65536+ (64k+) | Heavy memory pressure | Likely slower and less stable on 16GB |
| **Not recommended** | 131k - 262k | Very heavy memory pressure | The model supports it on paper, but the machine likely will not enjoy it |

### 2. Optimization Tips

* **Context Size**: This demo defaults to **16384** so OpenClaw has enough room for agent instructions, session state, and tool context while staying reasonable for the lightweight demo model.
* **Model Selection**: This repo defaults to **`qwen3.5:0.8b`** as a lightweight demo model. Use **`qwen3.5:4b`** only when you want better quality and can accept higher memory pressure.
* **Quality vs Context**: Increasing context helps with longer conversations, not arithmetic or reasoning quality. If `qwen3.5:0.8b` gives incorrect answers, prefer `qwen3.5:4b` before increasing context.
* **Measured Baseline**: On a Mac Mini M4 with 16GB RAM, `qwen3.5:0.8b` at 16k showed about `2.4GB` loaded in Ollama, OpenClaw around `538MiB / 3GiB`, and macOS already using compression. That makes **32k** a reasonable experiment, but not a safer default.
* **32k Test**: To test 32k, set both `OPENCLAW_PROVIDERS_OLLAMA_NUM_CTX=32768` in `docker-compose.yml` and `"contextTokens": 32768` in `config/openclaw.json`, then restart OpenClaw.

### 3. Hardware Sizing Guide

This repository targets a **Mac Mini M4 with 16GB unified memory**, which is excellent for a local OpenClaw demo but not ideal as a full-time local large-model workstation. For Ollama + OpenClaw, memory capacity and memory bandwidth matter more than raw CPU alone.

| Goal | Suggested Mac Class | RAM | SSD | Practical Model Range | Practical Context |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Lightweight demo like this repo | Mac Mini M4 | 16GB | 512GB - 1TB | 0.5B - 4B | 16k default, 32k experimental |
| Comfortable local agent | Mac Mini M4 Pro / Mac Studio M4 Max | 32GB - 36GB+ | 1TB+ | 4B - 8B | 16k - 32k |
| Recommended daily-driver setup | Mac Studio M4 Max | 64GB | 1TB - 2TB | 8B - 14B | 32k - 64k |
| Serious local large-model setup | Mac Studio M4 Max / M3 Ultra | 96GB - 128GB+ | 2TB+ | 14B - 32B | 64k where stable |
| Enthusiast local experiments | High-memory Mac Studio Ultra | 192GB+ | 4TB+ | 32B - 70B quantized models | Depends on model and speed tolerance |

For this repo's current machine, the practical profile is:

```text
Mac Mini M4
CPU/GPU: 10-core CPU / 10-core GPU
RAM: 16GB unified memory
SSD: 512GB or 1TB
Model: qwen3.5:0.8b or qwen3.5:4b
Context: 16k default, 32k experimental
```

If you want OpenClaw to feel more like a reliable daily assistant for files, tools, code, and reasoning, the sweet spot is closer to:

```text
Mac Studio M4 Max
RAM: 64GB unified memory
SSD: 2TB
Model: 8B - 14B
Context: 32k - 64k
```

---

## ⚙️ V. Configuration Details

### 1. Core Model Configuration

* **Primary Demo Model**: `qwen3.5:0.8b`
* **Optional Heavier Model**: `qwen3.5:4b` for better quality at higher memory cost

### 2. Key Environment Variables (Docker Compose)

* `OPENCLAW_PROVIDERS_OLLAMA_NUM_CTX=16384`: Requests a 16k context window for the local Ollama model.
* `OPENCLAW_AGENTS_DEFAULTS_MODEL_PRIMARY=ollama/qwen3.5:0.8b`: Sets the demo model.
* `agents.defaults.thinkingDefault=off`: Keeps the smoke-test prompt small for tiny local models.
* `agents.defaults.experimental.localModelLean=true`: Drops heavier default tool context for weaker local models.
* `tools.profile=coding`: Keeps file/workspace tools available without the heavier full tool profile.
* `shm_size: '2gb'`: Allocates sufficient shared memory for browser automation.

---

## 📂 VI. Directory Roles

* **`config/`**: Maps to `/home/node/.openclaw`. Stores tokens, history, and learned knowledge. *Ignored by Git.*
* **`sandbox/`**: Maps to `/home/node/.openclaw/workspace`. The Agent's isolated workshop. *Ignored by Git.*

---

## 🛠️ VII. Maintenance Commands

| Goal | Command |
| :--- | :--- |
| **Full Cleanup & Restart** | `make start` |
| **Gracefully Stop All Services** | `docker-compose down` |
| **Clear History & Cache** | `docker-compose down -v && rm config/memory/main.sqlite` |
| **Check Model Status** | `ollama ps` |

---

## 🔧 VIII. Troubleshooting

| Problem | Solution |
| :--- | :--- |
| **System is lagging** | Execute `pkill -9 -f "ollama runner"` to force release memory, then restart. |
| **Docker cannot connect to host** | Run `colima restart` and check if `host.docker.internal` is resolvable. |
| **Model not responding / Timeout** | Run `ollama ps` to see if a model is loading, or try restarting the Ollama service. |
| **Browser automation crashes** | Check if `shm_size` in `docker-compose.yml` is set to `2gb` or more. |
| **Permission Denied** | Ensure the host directory is owned by the current user and the container starts with `user: "501:20"`. |

---

## ⚠️ IX. Known Limitations

As an AI Infra project, we must transparently point out the physical constraints in a 16GB unified memory environment:

* **Memory Capacity Bottleneck**: 16GB UMA is still tight when handling extremely large context inference compared to 32GB/64GB models.
* **Context Risks**: Context windows of 131k+ easily trigger system Swap (disk paging), leading to a massive drop in inference speed.
* **Multi-model Limitations**: **Strongly discouraged** to run multiple models simultaneously or execute heavy tasks concurrently.
* **Browser Automation**: Playwright/Puppeteer consumes significant memory spikes when active, which may squeeze inference space.
* **Long-term Maintenance**: Ollama Runners running for extended periods may not release memory completely; periodic manual resets according to the maintenance table are recommended.

---
