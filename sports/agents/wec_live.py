#!/Users/aksarada/.meshclaw/workspace/f1-agent/.venv/bin/python3
"""WEC Live Timing Agent - Connects to Alkamelsystems Meteor DDP for race control & pit events."""

import sys
sys.path = [p for p in sys.path if '.toolbox/tools/meshclaw' not in p]

import json
import os
import time
import websockets.sync.client as ws_client

import notify_helper

NOTIFY_LOG = os.path.expanduser("~/.meshclaw/workspace/f1-agent/wec_notifications.log")
WS_URL = "wss://livetiming.alkamelsystems.com/websocket"

# DDP subscriptions we care about (param is feed ID or session ID)
FEED_NAME = "fiawec"
FEED_ID = "NGydCE7hoibZgxvD9"
SUBS_WITH_FEED = ["raceControl", "sessionStatus", "pitInfo", "weather"]


def notify(title, message, subtitle=None):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    full = f"[{ts}] {title}" + (f" | {subtitle}" if subtitle else "") + f"\n{message}\n"
    print(f"  [{ts}] 🏁 {title}: {message}" + (f" ({subtitle})" if subtitle else ""), flush=True)
    try:
        with open(NOTIFY_LOG, "a") as f:
            f.write(full + "\n")
    except Exception:
        pass
    notify_helper.send(title, message, subtitle=subtitle, group="wec", open_path=NOTIFY_LOG)


def run():
    print("🏁 WEC Live Timing Agent starting...", flush=True)
    sub_id = 1
    seen_rc_ids = set()  # race control message IDs
    session_name = ""
    initial_load = True

    while True:
        try:
            print("  Connecting to Alkamelsystems DDP...", flush=True)
            with ws_client.connect(WS_URL, additional_headers={"User-Agent": "Mozilla/5.0"}) as ws:
                # DDP handshake
                ws.send(json.dumps({"msg": "connect", "version": "1", "support": ["1"]}))
                resp = ws.recv(timeout=10)  # server_id
                resp = ws.recv(timeout=10)  # connected

                if "connected" not in resp:
                    print(f"  [!] Handshake failed: {resp[:100]}", flush=True)
                    time.sleep(30)
                    continue

                print("  ✅ Connected!", flush=True)

                # Subscribe to feed to get session list
                ws.send(json.dumps({"msg": "sub", "id": str(sub_id), "name": "livetimingFeed", "params": [FEED_NAME]}))
                sub_id += 1

                # Wait for feed data to get session IDs
                session_oids = []
                for _ in range(10):
                    try:
                        raw = ws.recv(timeout=5)
                        data = json.loads(raw)
                        if data.get("msg") == "added" and data.get("collection") == "feeds":
                            sessions = data.get("fields", {}).get("sessions", [])
                            session_oids = [s["$value"] for s in sessions if "$value" in s]
                            print(f"  Found {len(session_oids)} sessions", flush=True)
                            break
                        elif data.get("msg") == "ready":
                            break
                    except TimeoutError:
                        break

                # Subscribe to each session with ObjectID format
                for sid in session_oids:
                    oid = {"$type": "oid", "$value": sid}
                    for sub_name in ["raceControl", "sessionStatus", "sessionResults"]:
                        ws.send(json.dumps({"msg": "sub", "id": str(sub_id), "name": sub_name, "params": [oid]}))
                        sub_id += 1

                notify("🏁 WEC Agent", f"Connected - tracking {len(session_oids)} sessions")

                # Process messages
                ready_count = 0
                connect_time = time.time()
                while True:
                    try:
                        raw = ws.recv(timeout=30)
                    except TimeoutError:
                        ws.send(json.dumps({"msg": "ping"}))
                        continue

                    if not raw:
                        continue

                    data = json.loads(raw)
                    msg_type = data.get("msg", "")

                    if msg_type == "ping":
                        ws.send(json.dumps({"msg": "pong"}))
                        continue

                    if msg_type == "ready":
                        ready_count += 1
                        if initial_load and time.time() - connect_time > 15:
                            initial_load = False
                            print("  Initial load complete, listening for live updates...", flush=True)
                        continue

                    if msg_type not in ("added", "changed"):
                        continue

                    # Time-based initial load completion
                    if initial_load and time.time() - connect_time > 15:
                        initial_load = False
                        print("  Initial load complete, listening for live updates...", flush=True)

                    coll = data.get("collection", "")
                    fields = data.get("fields", {})
                    doc_id = data.get("id", "")

                    # Session results (get session name from classification)
                    if coll == "session_results" and not session_name:
                        cls = fields.get("classification", {}).get("session", {})
                        champ = cls.get("championship_name", "")
                        event = cls.get("event_name", "")
                        sname = cls.get("session_name", "")
                        if champ:
                            session_name = f"{champ} - {sname}" if sname else champ
                            print(f"  Session: {session_name} ({event})", flush=True)

                    # Feed updates (session changes)
                    if coll == "feeds":
                        curr = fields.get("currentSession", {})
                        if curr and curr.get("name"):
                            new_name = curr["name"]
                            if new_name != session_name:
                                session_name = new_name
                                notify("🏎️ WEC Session", session_name)

                    # Session info
                    if coll == "sessions" and fields.get("name"):
                        new_name = fields["name"]
                        status = fields.get("status", "")
                        if new_name != session_name:
                            session_name = new_name
                            if not initial_load:
                                notify("🏎️ WEC Session", f"{session_name} [{status}]")

                    # Session status changes
                    elif coll == "session_status":
                        if initial_load:
                            continue
                        status_obj = fields.get("status", {})
                        flag = status_obj.get("currentFlag", "") if isinstance(status_obj, dict) else ""
                        if not initial_load and flag:
                            flag_map = {"GF": "🟢 Green Flag", "YF": "🟡 Yellow Flag", "RF": "🔴 Red Flag", "SC": "🚨 Safety Car", "FCY": "🟡 Full Course Yellow", "CF": "🏁 Chequered Flag"}
                            msg = flag_map.get(flag, f"Flag: {flag}")
                            # Get session name from the classification
                            sid = fields.get("session", {}).get("$value", "")
                            notify(f"🏁 {msg}", session_name or sid[-8:])

                    # Race control messages
                    elif coll == "race_control":
                        rc_msgs = fields.get("raceControlMessages", {})
                        log = rc_msgs.get("log", {}) if isinstance(rc_msgs, dict) else {}
                        for ts_key, msg_obj in log.items():
                            if ts_key in seen_rc_ids:
                                continue
                            seen_rc_ids.add(ts_key)
                            if initial_load:
                                continue
                            msg_text = msg_obj.get("message", "") if isinstance(msg_obj, dict) else ""
                            if msg_text:
                                icon = "🚩"
                                upper = msg_text.upper()
                                if "SAFETY CAR" in upper:
                                    icon = "🚨"
                                elif "YELLOW" in upper:
                                    icon = "🟡"
                                elif "RED" in upper:
                                    icon = "🔴"
                                elif "GREEN" in upper or "CLEAR" in upper:
                                    icon = "🟢"
                                elif "CHEQUERED" in upper:
                                    icon = "🏁"
                                notify(f"{icon} {msg_text}", session_name)
                        # Also check currentMessages
                        current = rc_msgs.get("currentMessages", {}) if isinstance(rc_msgs, dict) else {}
                        for key, msg_obj in current.items():
                            cid = f"cur_{doc_id}_{key}"
                            if cid in seen_rc_ids:
                                continue
                            seen_rc_ids.add(cid)
                            if initial_load:
                                continue
                            msg_text = msg_obj.get("message", "") if isinstance(msg_obj, dict) else ""
                            if msg_text:
                                notify(f"🚩 {msg_text}", session_name)

                    # Pit info
                    elif coll == "session_pit_info" and not initial_load:
                        car = fields.get("number", "?")
                        team = fields.get("team", "")
                        pit_time = fields.get("pitTime", "")
                        if pit_time:
                            notify("🔧 Pit Stop", f"#{car} {team} — {pit_time}s", session_name)

        except KeyboardInterrupt:
            print("\n  Shutting down.", flush=True)
            sys.exit(0)
        except Exception as e:
            print(f"  [!] Error: {e}", flush=True)
            print("  Reconnecting in 15s...", flush=True)
            time.sleep(15)


if __name__ == "__main__":
    run()
