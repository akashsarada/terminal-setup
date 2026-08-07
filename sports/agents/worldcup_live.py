#!/Users/aksarada/.meshclaw/workspace/f1-agent/.venv/bin/python3
"""FIFA World Cup 2026 Live Agent - Polls ESPN API for match events."""

import sys
sys.path = [p for p in sys.path if '.toolbox/tools/meshclaw' not in p]

import json
import os
import time
import urllib.request

import notify_helper

NOTIFY_LOG = os.path.expanduser("~/.meshclaw/workspace/f1-agent/worldcup_notifications.log")
POLL_INTERVAL = 30  # seconds
MAX_BACKOFF = 300   # 5 min cap on error backoff
ESPN_URL = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"


def notify(title, message, subtitle=None):
    """Send a macOS notification."""
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    full = f"[{ts}] {title}"
    if subtitle:
        full += f" | {subtitle}"
    full += f"\n{message}\n"
    print(f"  [{ts}] ⚽ {title}: {message}" + (f" ({subtitle})" if subtitle else ""), flush=True)
    try:
        with open(NOTIFY_LOG, "a") as f:
            f.write(full + "\n")
    except Exception:
        pass
    notify_helper.send(title, message, subtitle=subtitle, group="worldcup", open_path=NOTIFY_LOG)


def fetch_scoreboard():
    """Fetch World Cup scoreboard from ESPN."""
    req = urllib.request.Request(ESPN_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def run():
    """Main polling loop."""
    print("⚽ FIFA World Cup 2026 Agent starting...", flush=True)

    # Track state per match: {match_id: {"status": ..., "score": ..., "seen_events": set()}}
    match_states = {}

    error_count = 0
    while True:
        try:
            data = fetch_scoreboard()
            events = data.get("events", [])

            for event in events:
                match_id = event["id"]
                comp = event.get("competitions", [{}])[0]
                teams = comp.get("competitors", [])
                status_obj = comp.get("status", {})
                status = status_obj.get("type", {}).get("name", "")
                clock = status_obj.get("displayClock", "")
                period = status_obj.get("period", 0)

                if len(teams) < 2:
                    continue

                home = teams[0].get("team", {}).get("shortDisplayName", "?")
                away = teams[1].get("team", {}).get("shortDisplayName", "?")
                home_score = int(teams[0].get("score", "0") or 0)
                away_score = int(teams[1].get("score", "0") or 0)
                home_id = teams[0].get("team", {}).get("id", "")
                away_id = teams[1].get("team", {}).get("id", "")
                scoreline = f"{home} {home_score} - {away_score} {away}"
                time_str = f"{clock}" if clock and period else ""

                # Initialize state
                if match_id not in match_states:
                    # Skip all existing events on first discovery (avoid re-fire on restart)
                    skip_initial = status not in ("STATUS_SCHEDULED", "STATUS_SCHEDULED_TO_START", "")
                    match_states[match_id] = {
                        "status": "",
                        "score": "",
                        "seen_events": set(),
                        "notified_started": skip_initial,
                        "notified_halftime": skip_initial or status in ("STATUS_HALFTIME", "STATUS_SECOND_HALF", "STATUS_FULL_TIME"),
                        "notified_fulltime": skip_initial and status == "STATUS_FULL_TIME",
                        "skip_initial_events": skip_initial,
                    }

                state = match_states[match_id]

                # Detect status changes (notify only once per transition)
                if status == "STATUS_IN_PROGRESS" and not state["notified_started"]:
                    state["notified_started"] = True
                    venue = comp.get("venue", {})
                    venue_str = venue.get("fullName", "")
                    if venue.get("address", {}).get("city"):
                        venue_str += f", {venue['address']['city']}"
                    subtitle = venue_str if venue_str else f"{home} vs {away}"
                    notify("⚽ Match Started!", f"{scoreline}", subtitle)
                elif status == "STATUS_HALFTIME" and not state["notified_halftime"]:
                    state["notified_halftime"] = True
                    notify("⏸️ Half Time", scoreline)
                elif status == "STATUS_FULL_TIME" and not state["notified_fulltime"]:
                    state["notified_fulltime"] = True
                    notify("🏁 Full Time!", scoreline)
                elif status == "STATUS_POSTPONED":
                    notify("⚠️ Postponed", f"{home} vs {away}")

                state["status"] = status

                # Process match details (goals, cards, pens)
                details = comp.get("details", [])
                # On first discovery of finished match, mark all events seen without notifying
                if state.get("skip_initial_events"):
                    for det in details:
                        display_t = det.get("clock", {}).get("displayValue", "")
                        evt_type = det.get("type", {}).get("text", "")
                        state["seen_events"].add(f"{match_id}:{display_t}:{evt_type}")
                    state["skip_initial_events"] = False
                    continue

                for det in details:
                    # Create unique ID for each event (clock + type is stable, team can change)
                    evt_type = det.get("type", {}).get("text", "")
                    clock_val = det.get("clock", {}).get("value", 0)
                    display_time = det.get("clock", {}).get("displayValue", "")
                    evt_id = f"{match_id}:{display_time}:{evt_type}"

                    if evt_id in state["seen_events"]:
                        continue
                    state["seen_events"].add(evt_id)

                    scoring = det.get("scoringPlay", False)
                    red = det.get("redCard", False)
                    penalty = det.get("penaltyKick", False)
                    own_goal = det.get("ownGoal", False)

                    # Get athlete name if available
                    athletes = det.get("athletesInvolved", [])
                    player = athletes[0].get("shortName", "") if athletes else ""

                    if scoring:
                        # Compute score up to this goal from all scoring events
                        h_goals = sum(1 for d in details if d.get("scoringPlay") and
                                      d.get("clock", {}).get("value", 0) <= clock_val and
                                      ((d.get("team", {}).get("id") == home_id and not d.get("ownGoal")) or
                                       (d.get("team", {}).get("id") == away_id and d.get("ownGoal"))))
                        a_goals = sum(1 for d in details if d.get("scoringPlay") and
                                      d.get("clock", {}).get("value", 0) <= clock_val and
                                      ((d.get("team", {}).get("id") == away_id and not d.get("ownGoal")) or
                                       (d.get("team", {}).get("id") == home_id and d.get("ownGoal"))))
                        goal_scoreline = f"{home} {h_goals} - {a_goals} {away}"
                        goal_type = det.get("type", {}).get("text", "Goal")
                        if own_goal:
                            icon = "🙈"
                            desc = f"OWN GOAL! {player} ({display_time})"
                        elif penalty:
                            icon = "🎯"
                            desc = f"PENALTY GOAL! {player} ({display_time})"
                        else:
                            icon = "⚽"
                            # Include type if it's more specific than just "Goal"
                            label = goal_type if goal_type != "Goal" else "GOAL"
                            desc = f"{label}! {player} ({display_time})"
                        notify(f"{icon} {desc}", goal_scoreline)
                    elif red:
                        notify(f"🟥 RED CARD! {player} ({display_time})", scoreline)
                    elif det.get("yellowCard", False):
                        notify(f"🟨 Yellow Card: {player} ({display_time})", scoreline)

                # Update stored score
                state["score"] = scoreline

            # Clean up finished matches after 10 min
            for mid in list(match_states.keys()):
                if match_states[mid]["status"] in ("STATUS_FULL_TIME", "STATUS_POSTPONED"):
                    # Keep for a while then remove
                    pass

            error_count = 0

        except KeyboardInterrupt:
            print("\n  Shutting down.", flush=True)
            sys.exit(0)
        except Exception as e:
            error_count += 1
            backoff = min(POLL_INTERVAL * (2 ** error_count), MAX_BACKOFF)
            print(f"  [!] Error ({error_count}): {e} — retrying in {backoff}s", flush=True)
            time.sleep(backoff)
            continue

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
