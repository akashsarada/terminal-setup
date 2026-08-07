#!/Users/aksarada/.meshclaw/workspace/f1-agent/.venv/bin/python3
"""F1 Live Timing Agent - Connects to F1 SignalR stream and sends macOS notifications."""

import sys
# Remove any injected paths from parent process (meshclaw venv)
sys.path = [p for p in sys.path if '.toolbox/tools/meshclaw' not in p]

import json
import os
import time
import urllib.parse
import urllib.request
import threading
import sys
import zlib
import base64

SIGNALR_BASE = "https://livetiming.formula1.com/signalr"
STREAMING_HUB = "Streaming"
import notify_helper

# Topics we subscribe to for lap-by-lap updates
TOPICS = [
    "TimingData",
    "LapCount",
    "RaceControlMessages",
    "SessionStatus",
    "SessionInfo",
    "DriverList",
    "TimingAppData",
]


NOTIFY_LOG = os.path.expanduser("~/.meshclaw/workspace/f1-agent/notifications.log")


def notify(title, message, subtitle=None):
    """Send a macOS notification. Click opens full log."""
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    full = f"[{ts}] {title}"
    if subtitle:
        full += f" | {subtitle}"
    full += f"\n{message}\n"
    print(f"  [{ts}] 🔔 {title}: {message}" + (f" ({subtitle})" if subtitle else ""), flush=True)
    # Append to log so clicking notification shows full history
    try:
        with open(NOTIFY_LOG, "a") as f:
            f.write(full + "\n")
    except Exception:
        pass
    notify_helper.send(title, message, subtitle=subtitle, group="f1live", open_path=NOTIFY_LOG)


def negotiate():
    """Negotiate a SignalR connection."""
    conn_data = urllib.parse.quote(json.dumps([{"name": STREAMING_HUB}]))
    url = f"{SIGNALR_BASE}/negotiate?connectionData={conn_data}&clientProtocol=1.5"
    req = urllib.request.Request(url, headers={"User-Agent": "BestHTTP"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def build_ws_url(token):
    """Build the WebSocket URL for SignalR streaming."""
    conn_data = urllib.parse.quote(json.dumps([{"name": STREAMING_HUB}]))
    token_enc = urllib.parse.quote(token)
    return (f"wss://livetiming.formula1.com/signalr/connect"
            f"?transport=webSockets&clientProtocol=1.5"
            f"&connectionToken={token_enc}&connectionData={conn_data}&tid=1")


def start_url(token):
    """Build the start URL to finalize the connection."""
    conn_data = urllib.parse.quote(json.dumps([{"name": STREAMING_HUB}]))
    token_enc = urllib.parse.quote(token)
    return (f"{SIGNALR_BASE}/start?transport=webSockets&clientProtocol=1.5"
            f"&connectionToken={token_enc}&connectionData={conn_data}")


class F1LiveAgent:
    def __init__(self):
        self.drivers = {}  # number -> {"name": ..., "team": ...}
        self.lap_count = {"current": 0, "total": 0}
        self.session_name = ""
        self.session_type = ""  # "Race", "Practice", "Qualifying", etc.
        self.session_status = ""
        self.last_leader_lap = 0
        self.notified_messages = set()
        self.initial_load = True  # Suppress notifications during initial data dump

    def handle_driver_list(self, data):
        """Parse driver list."""
        if isinstance(data, dict):
            for num, info in data.items():
                if isinstance(info, dict):
                    name = info.get("BroadcastName", info.get("FullName", f"#{num}"))
                    team = info.get("TeamName", "")
                    self.drivers[num] = {"name": name, "team": team}

    def handle_session_info(self, data):
        """Parse session info."""
        if isinstance(data, dict):
            meeting = data.get("Meeting", {})
            name = data.get("Name", "")
            location = meeting.get("Location", meeting.get("Name", ""))
            session_name = meeting.get("Name", "")
            if name:
                self.session_type = name  # e.g. "Practice 1", "Qualifying", "Race"
            if session_name or name:
                new_name = f"{session_name} — {name}" if name else session_name
                if location and location not in new_name:
                    new_name = f"{location} | {new_name}"
                if new_name != self.session_name:
                    # Rotate log on new F1 session (not on reconnect)
                    if self.session_name and os.path.exists(NOTIFY_LOG) and os.path.getsize(NOTIFY_LOG) > 0:
                        import glob
                        rot_ts = time.strftime("%Y%m%d-%H%M%S")
                        os.rename(NOTIFY_LOG, f"{NOTIFY_LOG}.{rot_ts}")
                        for f in sorted(glob.glob(f"{NOTIFY_LOG}.*"))[:-5]:
                            os.remove(f)
                    self.session_name = new_name
                    notify("🏎️ F1 Session Active", self.session_name)

    def handle_session_status(self, data):
        """Parse session status changes."""
        if isinstance(data, dict):
            status = data.get("Status", "")
            if status and status != self.session_status:
                old = self.session_status
                self.session_status = status
                status_map = {
                    "Started": "🟢 Session Started!",
                    "Aborted": "🔴 Session Aborted!",
                    "Finished": "🏁 Session Finished!",
                    "Finalised": "✅ Results Finalised",
                    "Inactive": "⏸️ Session Inactive",
                }
                msg = status_map.get(status, f"Status: {status}")
                if old:  # Don't notify on initial connection
                    notify("🏎️ F1 Session", msg, self.session_name)

    def handle_lap_count(self, data):
        """Parse lap count updates."""
        if isinstance(data, dict):
            current = data.get("CurrentLap", self.lap_count["current"])
            total = data.get("TotalLaps", self.lap_count["total"])
            if current > self.last_leader_lap and self.last_leader_lap > 0:
                self.lap_count = {"current": current, "total": total}
                self.last_leader_lap = current
                remaining = total - current if total else "?"
                notify("🏎️ F1 Lap Update",
                       f"Lap {current}/{total} — {remaining} laps remaining",
                       self.session_name)
            elif current != self.lap_count["current"]:
                self.lap_count = {"current": current, "total": total}
                self.last_leader_lap = current

    def handle_race_control(self, data):
        """Parse race control messages (flags, penalties, etc.)."""
        if not isinstance(data, dict):
            return
        messages = data.get("Messages", {})
        # Messages can be a list (initial dump) or dict (incremental updates)
        items = []
        if isinstance(messages, list):
            items = [(str(i), m) for i, m in enumerate(messages)]
        elif isinstance(messages, dict):
            items = list(messages.items())
        
        for key, msg in items:
            msg_id = msg.get("Utc", key) if isinstance(msg, dict) else key
            if msg_id in self.notified_messages:
                continue
            self.notified_messages.add(msg_id)
            if self.initial_load:
                continue  # Don't spam old messages on connect
            text = msg.get("Message", "") if isinstance(msg, dict) else str(msg)
            category = msg.get("Category", "") if isinstance(msg, dict) else ""
            if not text:
                continue
            flag_str = msg.get("Flag", "") if isinstance(msg, dict) else ""
            if "Flag" in category or flag_str:
                if "YELLOW" in text.upper() or "YELLOW" in flag_str.upper():
                    flag = "🟡"
                elif "RED" in text.upper() or "RED" in flag_str.upper():
                    flag = "🔴"
                elif "GREEN" in text.upper() or "GREEN" in flag_str.upper() or "CLEAR" in text.upper():
                    flag = "🟢"
                elif "BLUE" in text.upper() or "BLUE" in flag_str.upper():
                    flag = "🔵"
                else:
                    flag = "🚩"
            elif "SafetyCar" in category or "SAFETY CAR" in text.upper():
                flag = "🚨"
            elif "DRS" in text.upper():
                flag = "📡"
            else:
                flag = "📋"
            notify(f"{flag} Race Control", text, self.session_name)

    def handle_timing_data(self, data):
        """Parse timing data for notable events (fastest laps, pit stops)."""
        if not isinstance(data, dict) or self.initial_load:
            return
        lines = data.get("Lines", {})
        if not isinstance(lines, dict):
            return
        for num, driver_data in lines.items():
            if not isinstance(driver_data, dict):
                continue
            # Notify on pit entry (race only)
            in_pit = driver_data.get("InPit")
            if in_pit is True and self.session_type.startswith("Race"):
                name = self.drivers.get(num, {}).get("name", f"#{num}")
                notify("🔧 Pit Stop", f"{name} has entered the pits", self.session_name)
            # Notify on personal best / overall best laps
            last_lap = driver_data.get("LastLapTime", {})
            if isinstance(last_lap, dict):
                overall_fastest = last_lap.get("OverallFastest", False)
                if overall_fastest:
                    name = self.drivers.get(num, {}).get("name", f"#{num}")
                    lap_time = last_lap.get("Value", "")
                    notify("⚡ Fastest Lap!", f"{name} — {lap_time}", self.session_name)

    def process_message(self, topic, data):
        """Route a message to the appropriate handler."""
        handlers = {
            "DriverList": self.handle_driver_list,
            "SessionInfo": self.handle_session_info,
            "SessionStatus": self.handle_session_status,
            "LapCount": self.handle_lap_count,
            "RaceControlMessages": self.handle_race_control,
            "TimingData": self.handle_timing_data,
        }
        handler = handlers.get(topic)
        if handler:
            try:
                handler(data)
            except Exception as e:
                print(f"  [!] Error in {topic} handler: {e}", flush=True)


def decode_payload(raw):
    """Decode a potentially zlib-compressed base64 payload."""
    if isinstance(raw, str):
        try:
            decoded = base64.b64decode(raw)
            return json.loads(zlib.decompress(decoded, -zlib.MAX_WBITS))
        except Exception:
            try:
                return json.loads(raw)
            except Exception:
                return raw
    return raw


def run():
    """Main loop - connect to F1 SignalR and process messages."""
    import websockets.sync.client as ws_client

    agent = F1LiveAgent()
    print("🏎️  F1 Live Timing Agent starting...", flush=True)

    while True:
        try:
            print("  Negotiating connection...", flush=True)
            neg = negotiate()
            token = neg["ConnectionToken"]
            ws_url = build_ws_url(token)

            print("  Connecting to WebSocket...", flush=True)
            with ws_client.connect(ws_url, additional_headers={"User-Agent": "BestHTTP"}) as ws:
                # Subscribe to topics
                subscribe_msg = json.dumps({
                    "H": STREAMING_HUB,
                    "M": "Subscribe",
                    "A": [TOPICS],
                    "I": 1
                })
                ws.send(subscribe_msg)
                print("  ✅ Connected! Subscribed to live timing.", flush=True)
                notify("🏎️ F1 Agent", "Connected to live timing stream")

                while True:
                    try:
                        raw = ws.recv(timeout=30)
                    except TimeoutError:
                        # Send keepalive
                        ws.send(json.dumps({}))
                        continue

                    if not raw or raw == "{}":
                        continue

                    try:
                        msg = json.loads(raw)
                    except json.JSONDecodeError:
                        continue

                    # Handle invocation results (initial data dump)
                    if "R" in msg and isinstance(msg["R"], dict):
                        for topic, payload in msg["R"].items():
                            data = decode_payload(payload)
                            agent.process_message(topic, data)
                        agent.initial_load = False

                    # Handle streaming messages
                    if "M" in msg:
                        for m in msg["M"]:
                            hub = m.get("H", "")
                            method = m.get("M", "")
                            args = m.get("A", [])
                            if method == "feed" and len(args) >= 2:
                                topic = args[0]
                                data = decode_payload(args[1])
                                agent.process_message(topic, data)
                                ts = time.strftime("%H:%M:%S")
                                print(f"  [{ts}] {topic}", flush=True)

        except KeyboardInterrupt:
            print("\n  Shutting down.", flush=True)
            notify("🏎️ F1 Agent", "Disconnected from live timing")
            sys.exit(0)
        except Exception as e:
            print(f"  [!] Connection error: {e}", flush=True)
            print("  Reconnecting in 10s...", flush=True)
            time.sleep(10)


if __name__ == "__main__":
    run()
