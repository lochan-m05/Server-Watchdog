#!/bin/bash/

THRESHOLD=1
WEBHOOK_URL="https://discord.com/api/webhooks/1445009226480222363/NTPINv1HAGQId8unXSpal6SgCl6HQHFA-zxf5lbY6lJTTSUZWCmWOxSzzvjA4PREsLe-"




send_discord_alert() {
    local message="$1"
       curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$message\"}" \
         "$WEBHOOK_URL" > /dev/null 2>&1
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
