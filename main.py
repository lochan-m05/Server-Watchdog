from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
import subprocess
import json

app = FastAPI(title="Server Health Dashboard")


SCRIPT_PATH = "/app/main.sh"


HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Server Health Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 5px; }
        .metric { padding: 10px; border-bottom: 1px solid #ddd; }
        .metric:last-child { border: none; }
        .label { font-weight: bold; display: inline-block; width: 150px; }
        .value { color: #333; }
        .critical { color: red; font-weight: bold; }
        .normal { color: green; }
        h1 { text-align: center; }
        .footer { text-align: center; margin-top: 20px; font-size: 0.9em; color: #777; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Health Dashboard</h1>
        <div id="metrics">Loading...</div>
    </div>
    <div class="footer">Last update: <span id="timestamp"></span></div>

    <script>
        async function fetchMetrics() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                displayMetrics(data);
                document.getElementById('timestamp').innerText = new Date().toLocaleString();
            } catch (error) {
                document.getElementById('metrics').innerHTML = '<p class="critical">Error loading data</p>';
            }
        }

        function displayMetrics(data) {
            let html = '';
            const threshold = data.threshold;

            html += `<div class="metric"><span class="label">Hostname:</span> <span class="value">${data.hostname}</span></div>`;
            html += `<div class="metric"><span class="label">CPU Model:</span> <span class="value">${data.cpu_model}</span></div>`;
            html += `<div class="metric"><span class="label">Total RAM:</span> <span class="value">${data.total_ram}</span></div>`;

            let diskClass = data.disk_usage >= threshold ? 'critical' : 'normal';
            html += `<div class="metric"><span class="label">Disk Usage:</span> <span class="value ${diskClass}">${data.disk_usage}%</span></div>`;

            let ramClass = data.ram_usage >= threshold ? 'critical' : 'normal';
            html += `<div class="metric"><span class="label">RAM Usage:</span> <span class="value ${ramClass}">${data.ram_usage}%</span></div>`;

            let cpuClass = data.cpu_load >= threshold ? 'critical' : 'normal';
            html += `<div class="metric"><span class="label">CPU Load:</span> <span class="value ${cpuClass}">${data.cpu_load}%</span></div>`;

            document.getElementById('metrics').innerHTML = html;
        }

        // Fetch immediately and then every 5 seconds
        fetchMetrics();
        setInterval(fetchMetrics, 5000);
    </script>
</body>
</html>
"""

@app.get("/", response_class=HTMLResponse)
async def root():
    return HTML_TEMPLATE

@app.get("/api/health")
async def health_check():
    try:
        
        output = subprocess.check_output([SCRIPT_PATH, "--json"], text=True, stderr=subprocess.PIPE)
        data = json.loads(output)
        return JSONResponse(data)
    except subprocess.CalledProcessError as e:
        return JSONResponse({"error": f"Script failed: {e.stderr}"}, status_code=500)
    except json.JSONDecodeError:
        return JSONResponse({"error": "Invalid JSON from script"}, status_code=500)