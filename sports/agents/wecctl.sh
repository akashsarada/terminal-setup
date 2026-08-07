#!/bin/bash
AGENT_DIR="$HOME/.meshclaw/workspace/f1-agent"
PID_FILE="$AGENT_DIR/wec_live.pid"
LOG_FILE="$AGENT_DIR/wec_live.log"
start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "WEC agent already running (PID $(cat "$PID_FILE"))"; return 1; fi
    echo "Starting WEC Live Agent..."
    PYTHONPATH="" PYTHONHOME="" nohup env -u PYTHONPATH -u PYTHONHOME "$AGENT_DIR/.venv/bin/python3" "$AGENT_DIR/wec_live.py" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"; echo "Started (PID $!). Logs: $LOG_FILE"
}
stop() {
    if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then kill "$PID"; rm -f "$PID_FILE"; echo "Stopped (PID $PID)"
        else rm -f "$PID_FILE"; echo "Not running (stale PID removed)"; fi
    else echo "Not running"; fi
}
status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ WEC agent running (PID $(cat "$PID_FILE"))"; tail -5 "$LOG_FILE" 2>/dev/null
    else echo "❌ WEC agent is not running"; fi
}
case "${1:-start}" in start) start;; stop) stop;; status) status;; restart) stop; sleep 1; start;; *) echo "Usage: $0 {start|stop|status|restart}";; esac
