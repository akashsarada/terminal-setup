#!/bin/bash
# F1 Live Timing Agent - start/stop/status
AGENT_DIR="$HOME/.meshclaw/workspace/f1-agent"
PID_FILE="$AGENT_DIR/f1_live.pid"
LOG_FILE="$AGENT_DIR/f1_live.log"

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "F1 agent already running (PID $(cat "$PID_FILE"))"
        return 1
    fi
    echo "Starting F1 Live Timing Agent..."
    PYTHONPATH="" PYTHONHOME="" nohup env -u PYTHONPATH -u PYTHONHOME "$AGENT_DIR/.venv/bin/python3" "$AGENT_DIR/f1_live.py" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "Started (PID $!). Logs: $LOG_FILE"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PID_FILE"
            echo "Stopped F1 agent (PID $PID)"
        else
            rm -f "$PID_FILE"
            echo "Agent was not running (stale PID file removed)"
        fi
    else
        echo "Agent is not running"
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ F1 agent running (PID $(cat "$PID_FILE"))"
        echo "Last log lines:"
        tail -5 "$LOG_FILE" 2>/dev/null
    else
        echo "❌ F1 agent is not running"
    fi
}

case "${1:-start}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    restart) stop; sleep 1; start ;;
    *)      echo "Usage: $0 {start|stop|status|restart}" ;;
esac
