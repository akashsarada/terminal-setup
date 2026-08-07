# sports

Live sports notification agents — long-running pollers that fire native desktop
notifications for match events. Portable across macOS, Linux, and WSL.

## Layout

```
sports/
├── notify_helper.py        # shared cross-platform notification backend
├── install-autostart.sh    # sets up auto-start-on-login per OS
└── agents/
    ├── cricket_live.py     cricketctl.sh
    ├── worldcup_live.py    wcctl.sh
    ├── f1_live.py          f1ctl.sh
    └── wec_live.py         wecctl.sh
```

Everything installs into `~/.meshclaw/workspace/f1-agent/` — that is the runtime
directory the agents, control scripts, and init units all reference. This repo is
the source of truth; `install.sh` and `reload.sh` **overwrite** the runtime copies,
so edit files here, not there.

### The agents

| Agent | Control script | Source | Polling |
|---|---|---|---|
| cricket | `cricketctl.sh` | Cricbuzz scrape | every 15s |
| worldcup | `wcctl.sh` | ESPN public API | every 30s |
| f1 | `f1ctl.sh` | F1 SignalR live timing | streaming |
| wec | `wecctl.sh` | Alkamelsystems DDP WebSocket | streaming |

cricket tracks Rajasthan Royals and India only. worldcup tracks all matches.
wec is disabled by default — its Hypercar/LMP2/LMGT3 timing is paywalled behind
FIAWEC+, so only support races come through.

### notify_helper.py

One `send()` entry point that detects the host at import and dispatches to whichever
backend exists. Never raises — a missing notifier degrades to a silent no-op, since
each agent already writes its own notification log.

| Host | Backend | Notes |
|---|---|---|
| macOS | `terminal-notifier`, falling back to `osascript` | supports click-to-open |
| Linux | `notify-send` | no sound, no click-to-open |
| WSL with WSLg | `notify-send` | preferred when present |
| WSL / Windows | Windows toast via `powershell.exe` | needs Windows PowerShell 5.1, not `pwsh` |

## Getting started

### 1. Install

```bash
cd ~/terminal-setup
./install.sh          # answer y to "Install sports notifiers?"
```

This copies the helper, agents, and control scripts into the runtime directory,
creates `.venv` there, and installs `websockets` (required by f1 and wec). Saying yes
also asks whether to start the agents on login — answering yes there runs
`install-autostart.sh` for you, so step 3 is already done.

To install without a full `install.sh` run:

```bash
mkdir -p ~/.meshclaw/workspace/f1-agent
cp sports/notify_helper.py sports/agents/* ~/.meshclaw/workspace/f1-agent/
chmod +x ~/.meshclaw/workspace/f1-agent/*.sh
python3 -m venv ~/.meshclaw/workspace/f1-agent/.venv
~/.meshclaw/workspace/f1-agent/.venv/bin/pip install websockets==14.2
```

Confirm the notification backend resolved on this machine:

```bash
cd ~/.meshclaw/workspace/f1-agent && python3 -c \
  'import notify_helper; print(notify_helper.backend_name())'
```

### 2. Start an agent

Each control script takes `start`, `stop`, `status`, or `restart`:

```bash
~/.meshclaw/workspace/f1-agent/cricketctl.sh start
~/.meshclaw/workspace/f1-agent/cricketctl.sh status
```

### 3. Start on login (optional)

`install-autostart.sh` writes the right init unit for the host — launchd on macOS,
systemd `--user` on Linux and on WSL when systemd is enabled. It preflights that the
agent and venv exist before touching any init system.

```bash
./sports/install-autostart.sh              # default set: cricket worldcup f1
./sports/install-autostart.sh cricket      # just one
./sports/install-autostart.sh --dry-run    # print the unit, write nothing
./sports/install-autostart.sh --status     # report state, change nothing
./sports/install-autostart.sh --uninstall  # stop and remove units
```

`wec` is excluded from the default set and only installs when named explicitly.

On WSL **without** systemd there is no auto-start mechanism; the script says so and
prints the manual `*ctl.sh start` commands. To enable systemd, add to `/etc/wsl.conf`
and run `wsl --shutdown`:

```ini
[boot]
systemd=true
```

## Logs

Two logs per agent, both in `~/.meshclaw/workspace/f1-agent/`:

| File | Contents |
|---|---|
| `<agent>_live.log` | stdout/stderr — startup, poll errors, backoff |
| `<agent>_notifications.log` | notification history (f1 uses `notifications.log`) |

On macOS clicking a notification opens its notification log.

## Updating

`reload.sh` refreshes the runtime copies from this repo, but only if the runtime
directory already exists:

```bash
cd ~/terminal-setup && ./reload.sh
```

A running agent keeps executing its old code — restart it to pick changes up:

```bash
~/.meshclaw/workspace/f1-agent/cricketctl.sh restart
```

## Troubleshooting

**No notifications, but the log shows events.** The backend didn't resolve. Check
`backend_name()` (above); `none` means no notifier was found. Install
`terminal-notifier` on macOS or `libnotify-bin` on Linux.

**Agent exits immediately.** Usually a missing venv or `websockets`. Re-run the venv
steps in step 1 — the control scripts invoke `.venv/bin/python3` specifically, not
whatever `python3` is on `PATH`.

**Repeated network errors in the log.** Expected after sleep/wake. Each agent applies
exponential backoff (30s doubling to a 300s cap, reset on success) rather than
hammering the source, so it recovers on its own.

**Notifications stopped mid-match.** The Cricbuzz scraper is the fragile one — it
alternates between single- and double-escaped JSON, and the parser tries both. If
commentary looks truncated or empty, the page format likely changed again.
