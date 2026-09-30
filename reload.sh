#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
OS=""
ARCH=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ -f /etc/lsb-release ]] || [[ -f /etc/os-release ]]; then
  if grep -qi ubuntu /etc/*release; then
    OS="ubuntu"
  elif grep -qi fedora /etc/*release; then
    OS="fedora"
  fi
fi

install_jetbrains_mono() {
  echo "📦 Installing JetBrains Mono Nerd Font..."
  local FONT_DIR
  if [[ "$OS" == "mac" ]]; then
    FONT_DIR="$HOME/Library/Fonts"
  else
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
  fi
  cp "$SCRIPT_DIR/font/"*.ttf "$FONT_DIR/"

  echo "🔄 Reloading font cache..."
  if [[ "$OS" == "mac" ]]; then
    atsutil databases -remove && atsutil server -ping
  else
    fc-cache -f -v
  fi
  echo "✅ JetBrains Mono Nerd Font installed to $FONT_DIR"
}

HARD_RELOAD=false

for arg in "$@"; do
  case "$arg" in
    --hard|--sync)
      HARD_RELOAD=true
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --hard, --sync   Hard reload: 1-to-1 sync of nvim config (removes unmanaged plugins)"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo "Usage: $0 [--hard|--sync]"
      exit 1
      ;;
  esac
done

# Backup old configs
rm -rf ~/.config/old_nvim
[ -d ~/.config/nvim ] && cp -r ~/.config/nvim ~/.config/old_nvim
mv ~/.tmux.conf ~/.old_tmux.conf 2>/dev/null || true
mv ~/.git-hooks ~/.old_git-hooks 2>/dev/null || true

# Deploy nvim configuration
if [ "$HARD_RELOAD" = true ]; then
  echo "⚠️  Performing hard reload (1:1 sync)..."
  if command -v rsync &>/dev/null; then
    mkdir -p ~/.config/nvim
    rsync -av --delete "$SCRIPT_DIR/nvim/" ~/.config/nvim/
  else
    rm -rf ~/.config/nvim
    cp -r "$SCRIPT_DIR/nvim" ~/.config/nvim
  fi
else
  echo "🧠 Performing smart reload for nvim configs..."
  mkdir -p ~/.config/nvim/lua/plugins ~/.config/nvim/lua/vim-options ~/.config/nvim/spell

  for file in init.lua lazy-lock.json; do
    if [ -f "$SCRIPT_DIR/nvim/$file" ]; then
      if [ ! -f ~/.config/nvim/"$file" ] || ! cmp -s "$SCRIPT_DIR/nvim/$file" ~/.config/nvim/"$file"; then
        cp "$SCRIPT_DIR/nvim/$file" ~/.config/nvim/"$file"
        echo "  🔄 Updated base file: $file"
      fi
    fi
  done

  if [ -d "$SCRIPT_DIR/nvim/lua/vim-options" ]; then
    cp -r "$SCRIPT_DIR/nvim/lua/vim-options/"* ~/.config/nvim/lua/vim-options/ 2>/dev/null || true
  fi
  if [ -d "$SCRIPT_DIR/nvim/spell" ]; then
    cp -r "$SCRIPT_DIR/nvim/spell/"* ~/.config/nvim/spell/ 2>/dev/null || true
  fi

  SRC_PLUGINS="$SCRIPT_DIR/nvim/lua/plugins"
  DST_PLUGINS="$HOME/.config/nvim/lua/plugins"
  mkdir -p "$DST_PLUGINS"

  updated_plugins=0
  added_plugins=0
  unchanged_plugins=0
  preserved_plugins=0

  for src_path in "$SRC_PLUGINS"/*; do
    [ -e "$src_path" ] || continue
    name="$(basename "$src_path")"
    dst_path="$DST_PLUGINS/$name"

    if [ ! -e "$dst_path" ]; then
      cp -r "$src_path" "$dst_path"
      added_plugins=$((added_plugins + 1))
      echo "  ➕ Added plugin: $name"
    elif [ -d "$src_path" ]; then
      if ! diff -r -q "$src_path" "$dst_path" &>/dev/null; then
        rm -rf "$dst_path"
        cp -r "$src_path" "$dst_path"
        updated_plugins=$((updated_plugins + 1))
        echo "  🔄 Updated plugin directory: $name"
      else
        unchanged_plugins=$((unchanged_plugins + 1))
      fi
    elif ! cmp -s "$src_path" "$dst_path"; then
      cp "$src_path" "$dst_path"
      updated_plugins=$((updated_plugins + 1))
      echo "  🔄 Updated plugin: $name"
    else
      unchanged_plugins=$((unchanged_plugins + 1))
    fi
  done

  for dst_path in "$DST_PLUGINS"/*; do
    [ -e "$dst_path" ] || continue
    name="$(basename "$dst_path")"
    if [ ! -e "$SRC_PLUGINS/$name" ]; then
      preserved_plugins=$((preserved_plugins + 1))
      echo "  🛡️  Preserved custom plugin: $name"
    fi
  done

  echo "  📊 Plugins: $added_plugins added, $updated_plugins updated, $unchanged_plugins unchanged, $preserved_plugins preserved."
fi

# Copy other configs
cp "$SCRIPT_DIR/tmux.conf" ~/.tmux.conf
cp -r "$SCRIPT_DIR/git-hooks" ~/.git-hooks
chmod +x ~/.git-hooks/*
if [ -f "$SCRIPT_DIR/ghostty/config" ]; then
  mkdir -p ~/.config/ghostty
  cp "$SCRIPT_DIR/ghostty/config" ~/.config/ghostty/config

  # Sync to Windows AppData if running inside WSL
  if command -v cmd.exe &>/dev/null && command -v wslpath &>/dev/null; then
    for env_var in "LOCALAPPDATA" "APPDATA"; do
      win_path=$(cmd.exe /c "echo %${env_var}%" < /dev/null 2>/dev/null | tr -d '\r')
      if [ -n "$win_path" ] && [[ "$win_path" != "%"* ]]; then
        wsl_dest=$(wslpath "$win_path" 2>/dev/null)
        if [ -d "$wsl_dest" ]; then
          mkdir -p "$wsl_dest/ghostinthewsl"
          cp "$SCRIPT_DIR/ghostty/config" "$wsl_dest/ghostinthewsl/config.ghostinthewsl"
          cp "$SCRIPT_DIR/ghostty/config" "$wsl_dest/ghostinthewsl/config"
        fi
      fi
    done
  fi
fi

# Verify nvim
if [ -f ~/.config/nvim/init.lua ] && [ -d ~/.config/nvim/lua/plugins ]; then
  echo "✅ nvim config deployed successfully"
  rm -rf ~/.config/old_nvim
else
  echo "❌ nvim deployment failed — restoring backup"
  rm -rf ~/.config/nvim
  [ -d ~/.config/old_nvim ] && mv ~/.config/old_nvim ~/.config/nvim
  exit 1
fi

# Verify tmux
if [ -f ~/.tmux.conf ] && grep -q "colour81" ~/.tmux.conf; then
  echo "✅ tmux.conf copied successfully"
  rm -f ~/.old_tmux.conf
else
  echo "❌ tmux.conf copy failed — restoring backup"
  mv ~/.old_tmux.conf ~/.tmux.conf
  exit 1
fi

# Verify git-hooks
if [ -d ~/.git-hooks ] && [ -x ~/.git-hooks/pre-commit ]; then
  echo "✅ git-hooks copied successfully"
  rm -rf ~/.old_git-hooks
  git config --global core.hooksPath ~/.git-hooks
  echo "✅ Set global git hooksPath to ~/.git-hooks"
else
  echo "❌ git-hooks copy failed — restoring backup"
  rm -rf ~/.git-hooks
  mv ~/.old_git-hooks ~/.git-hooks 2>/dev/null || true
  exit 1
fi

# Copy AI steering files (only if the tool is installed)
# shellcheck source=scripts/sync-ai.sh
source "$SCRIPT_DIR/scripts/sync-ai.sh"
sync_ai_configs "$SCRIPT_DIR"

# Refresh the sports agents (only if they're already installed)
SPORTS_AGENT_DIR="$HOME/.meshclaw/workspace/f1-agent"
if [ -d "$SPORTS_AGENT_DIR" ]; then
  cp "$SCRIPT_DIR/sports/notify_helper.py" "$SPORTS_AGENT_DIR/notify_helper.py"
  cp "$SCRIPT_DIR/sports/agents/"*.py "$SPORTS_AGENT_DIR/"
  cp "$SCRIPT_DIR/sports/agents/"*.sh "$SPORTS_AGENT_DIR/"
  chmod +x "$SPORTS_AGENT_DIR/"*.sh
  echo "✅ Sports agents refreshed in $SPORTS_AGENT_DIR (restart any running agent to pick this up)"
else
  echo "⏩ Skipped sports agents (not installed)"
fi

# Install JetBrains Mono font
install_jetbrains_mono

# Ensure TPM and plugins are installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "🚀 Bootstrapping TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
  tmux start-server 2>/dev/null || true
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  echo "✅ Tmux plugins installed/updated"
fi

# Reload tmux if running
if tmux info &>/dev/null; then
  tmux source-file ~/.tmux.conf
  echo "✅ tmux config reloaded"
fi

echo "🎉 Done. Restart nvim to pick up changes."
