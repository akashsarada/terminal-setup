#!/usr/bin/env bash
#
# Install / remove auto-start-on-login for the live sports agents.
#
# Picks the right init mechanism for the host:
#   macOS  -> launchd LaunchAgent plists in ~/Library/LaunchAgents
#   Linux  -> systemd --user units in ~/.config/systemd/user
#   WSL    -> systemd --user when available, otherwise reports the manual command
#             (WSL has no systemd unless enabled in /etc/wsl.conf)
#
# Usage:
#   ./install-autostart.sh [agent...]      install + start (default: cricket worldcup f1)
#   ./install-autostart.sh --uninstall     stop + remove units
#   ./install-autostart.sh --status        show current state, change nothing
#   ./install-autostart.sh --dry-run       print the generated unit, write nothing
#
# 'wec' is a known agent but is NOT in the default set -- its timing feed is
# paywalled, so it only runs when named explicitly.

set -euo pipefail

AGENT_DIR="$HOME/.meshclaw/workspace/f1-agent"
KNOWN_AGENTS=(cricket worldcup f1 wec)
DEFAULT_AGENTS=(cricket worldcup f1)

# agent name -> python entrypoint basename (log file is <entrypoint>.log)
agent_script() {
  case "$1" in
    cricket)  echo "cricket_live" ;;
    worldcup) echo "worldcup_live" ;;
    f1)       echo "f1_live" ;;
    wec)      echo "wec_live" ;;
    *)        return 1 ;;
  esac
}

label_for()      { echo "local.$1-live-agent"; }
plist_path()     { echo "$HOME/Library/LaunchAgents/$(label_for "$1").plist"; }
systemd_unit()   { echo "$1-live-agent.service"; }
systemd_path()   { echo "$HOME/.config/systemd/user/$(systemd_unit "$1")"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then echo "wsl"; else echo "linux"; fi
      ;;
    *) echo "unsupported" ;;
  esac
}

has_systemd_user() {
  [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1
}

# --- unit content generators (pure stdout, no side effects) -------------------

render_plist() {
  local agent="$1" script; script="$(agent_script "$agent")"
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$(label_for "$agent")</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>exec env -u PYTHONPATH -u PYTHONHOME $AGENT_DIR/.venv/bin/python3 $AGENT_DIR/$script.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$AGENT_DIR/$script.log</string>
    <key>StandardErrorPath</key>
    <string>$AGENT_DIR/$script.log</string>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF
}

render_systemd() {
  local agent="$1" script; script="$(agent_script "$agent")"
  cat <<EOF
[Unit]
Description=$agent live notification agent
After=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'exec env -u PYTHONPATH -u PYTHONHOME $AGENT_DIR/.venv/bin/python3 $AGENT_DIR/$script.py'
Restart=always
RestartSec=30
StandardOutput=append:$AGENT_DIR/$script.log
StandardError=append:$AGENT_DIR/$script.log

[Install]
WantedBy=default.target
EOF
}

# --- preflight ---------------------------------------------------------------

check_agent_installed() {
  local agent="$1" script; script="$(agent_script "$agent")"
  if [ ! -f "$AGENT_DIR/$script.py" ]; then
    echo "❌ $agent: $AGENT_DIR/$script.py missing — run install.sh and pick the sports notifiers first"
    return 1
  fi
  if [ ! -x "$AGENT_DIR/.venv/bin/python3" ]; then
    echo "❌ $agent: $AGENT_DIR/.venv/bin/python3 missing — the agent venv has not been created"
    return 1
  fi
}

# --- per-OS install / uninstall / status -------------------------------------

install_macos() {
  local agent="$1" plist; plist="$(plist_path "$agent")"
  mkdir -p "$HOME/Library/LaunchAgents"
  launchctl bootout "gui/$(id -u)/$(label_for "$agent")" 2>/dev/null || true
  render_plist "$agent" > "$plist"
  launchctl bootstrap "gui/$(id -u)" "$plist"
  echo "✅ $agent: launchd job loaded ($plist)"
}

uninstall_macos() {
  local agent="$1" plist; plist="$(plist_path "$agent")"
  launchctl bootout "gui/$(id -u)/$(label_for "$agent")" 2>/dev/null || true
  rm -f "$plist"
  echo "🗑️  $agent: launchd job removed"
}

status_macos() {
  local agent="$1" state="not installed"
  [ -f "$(plist_path "$agent")" ] && state="plist present, not loaded"
  launchctl print "gui/$(id -u)/$(label_for "$agent")" >/dev/null 2>&1 && state="loaded"
  printf '  %-9s %s\n' "$agent" "$state"
}

install_systemd() {
  local agent="$1" unit; unit="$(systemd_unit "$agent")"
  mkdir -p "$HOME/.config/systemd/user"
  render_systemd "$agent" > "$(systemd_path "$agent")"
  systemctl --user daemon-reload
  systemctl --user enable --now "$unit"
  echo "✅ $agent: systemd user unit enabled ($unit)"
}

uninstall_systemd() {
  local agent="$1" unit; unit="$(systemd_unit "$agent")"
  systemctl --user disable --now "$unit" 2>/dev/null || true
  rm -f "$(systemd_path "$agent")"
  systemctl --user daemon-reload 2>/dev/null || true
  echo "🗑️  $agent: systemd user unit removed"
}

status_systemd() {
  local agent="$1" unit state="not installed"
  unit="$(systemd_unit "$agent")"
  if [ -f "$(systemd_path "$agent")" ]; then
    state="$(systemctl --user is-active "$unit" 2>/dev/null || true)/$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
    state="unit present (active/enabled: $state)"
  fi
  printf '  %-9s %s\n' "$agent" "$state"
}

manual_fallback_note() {
  echo ""
  echo "⚠️  No systemd --user available (typical on WSL without systemd enabled)."
  echo "    Enable it by adding this to /etc/wsl.conf, then 'wsl --shutdown':"
  echo "        [boot]"
  echo "        systemd=true"
  echo "    Until then, start agents manually:"
  for agent in "$@"; do
    case "$agent" in
      cricket)  echo "        $AGENT_DIR/cricketctl.sh start" ;;
      worldcup) echo "        $AGENT_DIR/wcctl.sh start" ;;
      f1)       echo "        $AGENT_DIR/f1ctl.sh start" ;;
      wec)      echo "        $AGENT_DIR/wecctl.sh start" ;;
    esac
  done
}

# --- main --------------------------------------------------------------------

main() {
  local mode="install" agents=()
  for arg in "$@"; do
    case "$arg" in
      --uninstall) mode="uninstall" ;;
      --status)    mode="status" ;;
      --dry-run)   mode="dry-run" ;;
      -h|--help)
        # Print the leading comment block, stopping at the first non-comment line
        awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
        return 0 ;;
      -*)          echo "Unknown flag: $arg" >&2; return 2 ;;
      *)
        if ! agent_script "$arg" >/dev/null 2>&1; then
          echo "Unknown agent: $arg (known: ${KNOWN_AGENTS[*]})" >&2
          return 2
        fi
        agents+=("$arg")
        ;;
    esac
  done
  [ ${#agents[@]} -eq 0 ] && agents=("${DEFAULT_AGENTS[@]}")

  local os; os="$(detect_os)"
  echo "🖥️  OS: $os   agents: ${agents[*]}"

  if [ "$os" = "unsupported" ]; then
    echo "❌ $(uname -s) is not supported by this script"
    return 1
  fi

  # status and dry-run never mutate anything
  if [ "$mode" = "status" ]; then
    if [ "$os" = "macos" ]; then
      for a in "${agents[@]}"; do status_macos "$a"; done
    elif has_systemd_user; then
      for a in "${agents[@]}"; do status_systemd "$a"; done
    else
      echo "  (no systemd --user; nothing to report)"
    fi
    return 0
  fi

  if [ "$mode" = "dry-run" ]; then
    for a in "${agents[@]}"; do
      echo ""
      if [ "$os" = "macos" ]; then
        echo "--- $(plist_path "$a") ---"; render_plist "$a"
      else
        echo "--- $(systemd_path "$a") ---"; render_systemd "$a"
      fi
    done
    return 0
  fi

  if [ "$mode" = "uninstall" ]; then
    for a in "${agents[@]}"; do
      if [ "$os" = "macos" ]; then uninstall_macos "$a"
      elif has_systemd_user; then uninstall_systemd "$a"
      else echo "⏩ $a: nothing to remove (no systemd --user)"; fi
    done
    return 0
  fi

  # install
  local failed=0
  for a in "${agents[@]}"; do check_agent_installed "$a" || failed=1; done
  [ "$failed" -eq 1 ] && return 1

  if [ "$os" = "macos" ]; then
    for a in "${agents[@]}"; do install_macos "$a"; done
  elif has_systemd_user; then
    # user units need lingering to survive logout / start at boot
    loginctl enable-linger "$USER" 2>/dev/null \
      || echo "⚠️  Could not enable-linger — agents will only run while you're logged in"
    for a in "${agents[@]}"; do install_systemd "$a"; done
  else
    manual_fallback_note "${agents[@]}"
    return 1
  fi

  echo ""
  echo "ℹ️  Check state any time with: $(basename "${BASH_SOURCE[0]}") --status"
}

# Only run when executed, so the render_* helpers can be sourced and tested.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
