#!/data/data/com.termux/files/usr/bin/bash

LOG="/data/data/com.termux/files/home/mcp-debug.log"

echo "=== MCP LAUNCH $(date) ===" >> "$LOG"
echo "CMD: $0 $@" >> "$LOG"
echo "ENV:" >> "$LOG"
env >> "$LOG"
echo "---" >> "$LOG"

# Redirect both stdout and stdetr
# exec "$@" >> "$LOG" 2>&1

# Redirect only stderr
exec "$@" 2>> "$LOG"
