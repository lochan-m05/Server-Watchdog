#!/bin/bash

THRESHOLD=80
WEBHOOK_URL="nigga"   


JSON_OUTPUT=0
if [[ "$1" == "--json" ]]; then
    JSON_OUTPUT=1
fi


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


CPU_MODEL=$(lscpu | sed -n 's/^Model name:[ \t]*//p')
TOTAL_RAM=$(free -h | grep Mem | awk '{print $2}')
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d %)
RAM_USAGE=$(free -m | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.0f", $1}')
HOSTNAME=$(hostname)

if [[ $JSON_OUTPUT -eq 0 ]]; then
    echo "---------------------------------"
    echo "          SERVER HEALTH          "
    echo "---------------------------------"

    MSG="[+] Server Details: $CPU_MODEL"
    echo "$MSG"
    send_discord_alert "$MSG"

    MSG="[+] Total Ram: $TOTAL_RAM"
    echo "$MSG"
    send_discord_alert "$MSG"

    if [[ "$DISK_USAGE" -ge "$THRESHOLD" ]]; then
        MSG="[+] CRITICAL: Disk usage is high: ${DISK_USAGE}% on $HOSTNAME"
        echo "[-] $MSG"
        send_discord_alert "$MSG"
    else
        echo "[+] NORMAL: Disk usage is at ${DISK_USAGE}%"
    fi

    if [[ "$RAM_USAGE" -ge "$THRESHOLD" ]]; then
        MSG="[+] CRITICAL: RAM usage is high: ${RAM_USAGE}% on $HOSTNAME"
        echo "[-] $MSG"
        send_discord_alert "$MSG"
    else
        echo "[+] NORMAL: RAM usage is at ${RAM_USAGE}%"
    fi

    if [[ "$CPU_LOAD" -ge "$THRESHOLD" ]]; then
        MSG="[+] CRITICAL: CPU load is high: ${CPU_LOAD}% on $HOSTNAME"
        echo "[-] $MSG"
        send_discord_alert "$MSG"
    else
        echo "[+] NORMAL: CPU load is at ${CPU_LOAD}%"
    fi
else
    # In JSON mode, still send alerts for critical values (optional, but we do)
    if [[ "$DISK_USAGE" -ge "$THRESHOLD" ]]; then
        send_discord_alert "[+] CRITICAL: Disk usage is high: ${DISK_USAGE}% on $HOSTNAME"
    fi
    if [[ "$RAM_USAGE" -ge "$THRESHOLD" ]]; then
        send_discord_alert "[+] CRITICAL: RAM usage is high: ${RAM_USAGE}% on $HOSTNAME"
    fi
    if [[ "$CPU_LOAD" -ge "$THRESHOLD" ]]; then
        send_discord_alert "[+] CRITICAL: CPU load is high: ${CPU_LOAD}% on $HOSTNAME"
    fi
fi


if [[ $JSON_OUTPUT -eq 1 ]]; then
    # Use jq to build a safe JSON object
    jq -n \
        --arg cpu_model "$CPU_MODEL" \
        --arg total_ram "$TOTAL_RAM" \
        --argjson disk_usage "$DISK_USAGE" \
        --argjson ram_usage "$RAM_USAGE" \
        --argjson cpu_load "$CPU_LOAD" \
        --argjson threshold "$THRESHOLD" \
        --arg hostname "$HOSTNAME" \
        '{
            cpu_model: $cpu_model,
            total_ram: $total_ram,
            disk_usage: $disk_usage,
            ram_usage: $ram_usage,
            cpu_load: $cpu_load,
            threshold: $threshold,
            hostname: $hostname
        }'
fi