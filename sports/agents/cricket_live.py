#!/Users/aksarada/.meshclaw/workspace/f1-agent/.venv/bin/python3
"""Cricket Live Agent - Polls Cricbuzz for Rajasthan Royals & India match updates."""

import sys
sys.path = [p for p in sys.path if '.toolbox/tools/meshclaw' not in p]

import json
import os
import re
import time
import urllib.request

import notify_helper

NOTIFY_LOG = os.path.expanduser("~/.meshclaw/workspace/f1-agent/cricket_notifications.log")
POLL_INTERVAL = 15  # seconds between polls
MAX_BACKOFF = 300   # 5 min cap on error backoff
TEAM = "rajasthan"  # match filter
TEAM_ABBR = ["rajasthan", "india", "ind-vs", "vs-ind", "-rr-", "rr-vs", "vs-rr"]

# Events we care about
NOTIFY_EVENTS = {"four", "six", "wicket", "wkt", "over-break"}


def notify(title, message, subtitle=None):
    """Send a macOS notification."""
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    full = f"[{ts}] {title}"
    if subtitle:
        full += f" | {subtitle}"
    full += f"\n{message}\n"
    print(f"  [{ts}] 🏏 {title}: {message}" + (f" ({subtitle})" if subtitle else ""), flush=True)
    try:
        with open(NOTIFY_LOG, "a") as f:
            f.write(full + "\n")
    except Exception:
        pass
    notify_helper.send(title, message, subtitle=subtitle, group="cricket", open_path=NOTIFY_LOG)


def fetch_page(url):
    """Fetch a page from Cricbuzz."""
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Cache-Control": "no-cache, no-store",
        "Pragma": "no-cache",
    })
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read().decode("utf-8", errors="replace")


def find_rr_match():
    """Find a live Rajasthan Royals or India match ID from Cricbuzz."""
    html = fetch_page("https://www.cricbuzz.com/cricket-match/live-scores")
    matches = re.findall(r'href="/live-cricket-scores/(\d+)/([^"]+)"', html)
    for mid, slug in matches:
        slug_lower = slug.lower()
        if any(t in slug_lower for t in TEAM_ABBR):
            return mid, slug
    return None, None


def get_commentary(match_id):
    """Get ball-by-ball commentary for a match."""
    url = f"https://www.cricbuzz.com/live-cricket-scores/{match_id}?t={int(time.time())}"
    html = fetch_page(url)

    # Extract score from title (format: "Team Score | Match | Cricbuzz")
    score_match = re.search(r'<title>([^|<]{5,60})\|', html)
    score = score_match.group(1).strip() if score_match else ""
    if not score or len(score) > 80:
        s = re.search(r'(\w+ \d+/\d+ \(\d+[\.\d]* Ovs?\))', html)
        score = s.group(1) if s else ""

    # Extract commentary entries (Cricbuzz alternates between single/double-escaped JSON)
    # Try double-escaped first (\\\" format), fall back to single-escaped (\" format)
    # Use \\\",\\\" (quote-comma-quote) as delimiter -- bare \\\" appears inside commentary text
    comms = re.findall(
        r'commText\\\\\".{0,5}?\\\\\"(.{0,800}?)\\\\\",\\\\\"[^}]{0,600}?event\\\\\":\[([^\]]+)\][^}]{0,200}?timestamp\\\\\":(\d+)',
        html
    )
    if not comms:
        comms = re.findall(
            r'commText\\\".{0,5}?\\\"(.{0,800}?)\\\",\\\"[^}]{0,600}?event\\\":\[([^\]]+)\][^}]{0,200}?timestamp\\\":(\d+)',
            html
        )
    # Extract over separators: overNumber, overSummary, overRuns, teamScore
    over_seps = {}
    # Try double-escaped first
    sep_pattern = r'\\\\\"timestamp\\\\\":(\d+),\\\\\"overSeparator\\\\\":\{[^}]*?\\\\\"overNumber\\\\\":(\d+),\\\\\"overSummary\\\\\":\\\\\"(.*?)\\\\\"[^}]*?\\\\\"overRuns\\\\\":(\d+)[^}]*?\\\\\"teamScore\\\\\":\\\\\"(.*?)\\\\\"\}'
    sep_matches = list(re.finditer(sep_pattern, html))
    if not sep_matches:
        sep_pattern = r'\\\"timestamp\\\":(\d+),\\\"overSeparator\\\":\{[^}]*?\\\"overNumber\\\":(\d+),\\\"overSummary\\\":\\\"([^\\]+)\\\"[^}]*?\\\"overRuns\\\":(\d+)[^}]*?\\\"teamScore\\\":\\\"([^\\]+)\\\"'
        sep_matches = list(re.finditer(sep_pattern, html))
    for m in sep_matches:
        over_seps[int(m.group(1))] = {
            "over": int(m.group(2)), "summary": m.group(3),
            "runs": int(m.group(4)), "team_score": m.group(5)
        }

    entries = []
    for text, event_str, timestamp in comms:
        clean_text = re.sub(r'\\\\u003c[^>]*?\\\\u003e|\\u003c[^>]*?\\u003e', '', text)
        events = set(p.strip().strip('\\"').strip('"').replace('\\\\', '') for p in event_str.split(','))
        entry = {"text": clean_text, "events": events, "ts": int(timestamp)}
        if "over-break" in events and int(timestamp) in over_seps:
            entry["over_sep"] = over_seps[int(timestamp)]
        entries.append(entry)

    # Extract win probability (try double-escaped, then single)
    win_prob = ""
    wp = re.search(r'winProbability\\\\\":\{[^}]*?team1\\\\\":\{[^}]*?\\\\\"percent\\\\\":(\d+)[^}]*?\\\\\"shortName\\\\\":\\\\\"([^\\\\]+)[^}]*\}[^}]*?team2\\\\\":\{[^}]*?\\\\\"percent\\\\\":(\d+)[^}]*?\\\\\"shortName\\\\\":\\\\\"([^\\\\]+)', html)
    if not wp:
        wp = re.search(r'winProbability\\\":\{[^}]*?team1\\\":\{[^}]*?\\\"percent\\\":(\d+)[^}]*?\\\"shortName\\\":\\\"([^\\]+)[^}]*\}[^}]*?team2\\\":\{[^}]*?\\\"percent\\\":(\d+)[^}]*?\\\"shortName\\\":\\\"([^\\]+)', html)
    if wp:
        win_prob = f"{wp.group(2)} {wp.group(1)}% • {wp.group(4)} {wp.group(3)}%"

    return score, entries, win_prob


def run():
    """Main polling loop."""
    print("🏏 Cricket Live Agent starting...", flush=True)
    print(f"  Watching for: Rajasthan Royals & India", flush=True)

    seen_timestamps = set()
    current_match_id = None
    match_slug = None
    error_count = 0

    while True:
        try:
            # Find RR match if we don't have one
            if not current_match_id:
                mid, slug = find_rr_match()
                if mid:
                    current_match_id = mid
                    match_slug = slug
                    seen_timestamps.clear()
                    notify("🏏 Match Found!", slug.replace("-", " ").title())
                    print(f"  Tracking match {mid}: {slug}", flush=True)
                else:
                    print(f"  [{time.strftime('%H:%M:%S')}] No live match found", flush=True)
                    time.sleep(120)  # Check less frequently when no match
                    continue

            # Get commentary
            score, entries, win_prob = get_commentary(current_match_id)

            # Process new entries (newest first in page, so reverse for chronological)
            new_entries = [e for e in entries if e["ts"] not in seen_timestamps]
            for entry in reversed(new_entries):
                seen_timestamps.add(entry["ts"])
                events = entry["events"]
                text = entry["text"]

                # Filter for events we care about
                if "six" in events:
                    notify("💥 SIX!", text, score)
                elif "four" in events:
                    notify("4️⃣ FOUR!", text, score)
                elif "wicket" in events or "wkt" in events:
                    notify("🔴 WICKET!", text, score)
                elif "over-break" in events:
                    sep = entry.get("over_sep")
                    if sep:
                        summary = sep['summary'].strip()
                        # Notify missed sixes/wickets from over summary
                        balls = summary.split()
                        sixes = balls.count('6')
                        wickets = balls.count('W')
                        fours = balls.count('4')
                        if sixes:
                            notify("💥 SIX!", f"{sixes}x six in over {sep['over']}", score)
                        if wickets:
                            notify("🔴 WICKET!", f"Wicket fell in over {sep['over']}", score)
                        if fours:
                            notify("4️⃣ FOUR!", f"{fours}x four in over {sep['over']}", score)
                        msg = f"Over {sep['over']}: {summary} ({sep['runs']} runs) — {sep['team_score']}"
                        if win_prob:
                            msg += f" | {win_prob}"
                    else:
                        msg = text
                    notify("📊 End of Over", msg, score)

            # Check if match is still live
            if not new_entries and entries:
                # Match might have ended - recheck
                mid, _ = find_rr_match()
                if mid != current_match_id:
                    notify("🏏 Match Ended", f"Final: {score}")
                    current_match_id = None
                    match_slug = None

        except KeyboardInterrupt:
            print("\n  Shutting down.", flush=True)
            sys.exit(0)
        except Exception as e:
            error_count += 1
            backoff = min(POLL_INTERVAL * (2 ** error_count), MAX_BACKOFF)
            print(f"  [!] Error ({error_count}): {e} — retrying in {backoff}s", flush=True)
            time.sleep(backoff)
            continue

        error_count = 0
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
