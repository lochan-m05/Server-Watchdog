# Server Watchdog

A lightweight server monitoring tool that combines a Bash script for health checks and Discord alerts with a FastAPI web dashboard for live metrics.

## Features

- **System Metrics** – CPU model, total RAM, disk usage, RAM usage, CPU load.
- **Discord Alerts** – Sends notifications when disk, RAM, or CPU usage exceed a configurable threshold (default 80%).
- **Live Web Dashboard** – Auto‑refreshing page showing current metrics with colour‑coded warnings.
- **Flexible Deployment** – Run locally or in a Docker container.
- **JSON API** – Exposes metrics via a simple `/api/health` endpoint.

## Prerequisites

- **Bash** – The monitoring script is written in Bash.
- **jq** – Used for JSON construction in the Bash script.
- **curl** – Required for Discord webhook calls.
- **Python 3.9+** – For the FastAPI web server (if running locally).
- **FastAPI & Uvicorn** – Python dependencies (see below).

If using Docker, only Docker Engine is required on the host.

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/server-watchdog.git
cd server-watchdog
```

### 2. Local Installation

#### Install System Dependencies (Ubuntu/Debian example)

```bash
sudo apt update
sudo apt install bash jq curl python3 python3-pip
```

#### Install Python Packages

```bash
pip3 install fastapi uvicorn
```

#### Make the Bash Script Executable

```bash
chmod +x main.sh
```

### 3. Docker Installation

Build the Docker image using the provided `Dockerfile`:

```bash
docker build -t server-watchdog .
```

## Configuration

### Discord Webhook

Edit `main.sh` and replace the placeholder `WEBHOOK_URL` with your actual Discord webhook URL:

```bash
WEBHOOK_URL="https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
```

**Optional:** For security, you can modify the script to read the webhook from an environment variable (see Advanced Configuration below).

### Threshold

The alert threshold is set to `80` in the script. Change it by editing the `THRESHOLD` variable at the top of `main.sh`:

```bash
THRESHOLD=80   # Change to desired percentage
```

## Usage

### Running Locally

1. **Start the FastAPI server**

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

2. **Access the dashboard** at `http://localhost:8000`.

The server will call `main.sh --json` every time you load the dashboard or hit the `/api/health` endpoint.

### Running with Docker

Run the container with host access to gather accurate system metrics:

```bash
docker run -d \
  --name watchdog \
  --privileged \
  -p 8000:8000 \
  -e DISCORD_WEBHOOK_URL="your_webhook_url" \   # if you modified the script to use env var
  server-watchdog
```

Then open `http://your-server-ip:8000`.

> **Note:** `--privileged` is required because the Bash script uses commands like `df /`, `free`, and `lscpu` that need access to host system information. For a more restricted approach, you could mount specific host directories, but that would require script modifications.

## API Endpoints

| Endpoint       | Method | Description                          |
|----------------|--------|--------------------------------------|
| `/`            | GET    | Serves the HTML dashboard.           |
| `/api/health`  | GET    | Returns JSON with current metrics.   |

Example `/api/health` response:

```json
{
  "cpu_model": "Intel(R) Core(TM) i7-10750H",
  "total_ram": "15Gi",
  "disk_usage": 45,
  "ram_usage": 30,
  "cpu_load": 10,
  "threshold": 80,
  "hostname": "my-server"
}
```

## Dashboard

The dashboard auto‑refreshes every 5 seconds. Metrics that exceed the threshold are highlighted in red.

![Dashboard Screenshot](screenshot.png) *(Add a screenshot if you like)*

## Advanced Configuration

### Using Environment Variables for Discord Webhook

Modify the Bash script to read the webhook from an environment variable:

```bash
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
```

Then pass the variable when running the container:

```bash
docker run -d --name watchdog --privileged -p 8000:8000 -e DISCORD_WEBHOOK_URL="your_url" server-watchdog
```

### Changing the Update Interval

The dashboard refreshes every 5 seconds. To change this, edit the `setInterval` value in the HTML template inside `main.py`:

```javascript
setInterval(fetchMetrics, 5000);   // change 5000 to desired milliseconds
```

## Troubleshooting

### 1. API returns 500 Internal Server Error

Check the container logs:

```bash
docker logs watchdog
```

Common causes:
- **Wrong script path** – Ensure `SCRIPT_PATH` in `main.py` points to the correct location inside the container (`/app/main.sh`).
- **Missing `jq`** – The Bash script requires `jq`. If running locally, install it. In Docker, the `Dockerfile` should install it.
- **Script not executable** – Run `chmod +x main.sh` and rebuild.

### 2. Dashboard shows "Error loading data"

Open browser developer tools (F12) and check the network tab for the `/api/health` request. The response should contain an error message.

### 3. Discord alerts not sent

- Verify the webhook URL is correct.
- Ensure `curl` is installed.
- If using the environment variable, confirm it is passed correctly.

## License

This project is open source and available under the [MIT License](LICENSE).

---

Enjoy monitoring your server!
