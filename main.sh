#!/bin/bash/

THRESHOLD=80
WEBHOOK_URL="nigga"



send_discord_alert() {
    local message="$1"
    
 
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is not installed. Cannot construct safe JSON." >&2
        return 1
    fi


    if [[ -z "$WEBHOOK_URL" ]]; then
        echo "Error: WEBHOOK_URL variable is empty." >&2
        return 1
    fi

  
    local payload
    payload=$(jq -n --arg content "$message" '{content: $content}')

  
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload" \
        "$WEBHOOK_URL")


    if [[ "$status_code" -eq 204 || "$status_code" -eq 200 ]]; then
        return 0
    else
        echo "Error: Failed to send Discord alert. Server returned: $status_code" >&2
        return 1
    fi
}

echo "---------------------------------"
echo "          SERVER HEALTH          "
echo "---------------------------------"


CPU_MODEL=$(lscpu | sed -n 's/^Model name:[ \t]*//p')
MSG="[+] Server Details: $CPU_MODEL"
echo "$MSG"
send_discord_alert "$MSG"


TOTAL_RAM=$(free -h | grep Mem | awk '{print $2}')
MSG="[+] Total Ram: $TOTAL_RAM"
echo "$MSG"
send_discord_alert "$MSG"

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d %) 
if [[ "$DISK_USAGE" -ge "$THRESHOLD" ]]; then
    MSG="[+] CRITICAL: Disk usage is high: ${DISK_USAGE}% on $(hostname)"
    echo "[-] $MSG"
    send_discord_alert "$MSG"
else
    echo "[+] NORMAL: Disk usage is at ${DISK_USAGE}%"
fi


RAM_USAGE=$(free -m | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')

if [[ "$RAM_USAGE" -ge "$THRESHOLD" ]]; then
    MSG="[+] CRITICAL: RAM usage is high: ${RAM_USAGE}% on $(hostname)"
    echo "[-] $MSG"
    send_discord_alert "$MSG"
else
    echo "[+] NORMAL: RAM usage is at ${RAM_USAGE}%"
fi


CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.0f", $1}')

if [[ "$CPU_LOAD" -ge "$THRESHOLD" ]]; then
    MSG="[+] CRITICAL: CPU load is high: ${CPU_LOAD}% on $(hostname)"
    echo "[-] $MSG"
    send_discord_alert "$MSG"
else
    echo "[+] NORMAL: CPU load is at ${CPU_LOAD}%"
fi
