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

# Backup old configs
mv ~/.config/nvim/ ~/.config/old_nvim 2>/dev/null || true
mv ~/.tmux.conf ~/.old_tmux.conf 2>/dev/null || true
mv ~/.git-hooks ~/.old_git-hooks 2>/dev/null || true

# Copy new configs
cp -r "$SCRIPT_DIR/nvim" ~/.config/nvim
cp "$SCRIPT_DIR/tmux.conf" ~/.tmux.conf
cp -r "$SCRIPT_DIR/git-hooks" ~/.git-hooks
chmod +x ~/.git-hooks/*

# Verify nvim
if [ -f ~/.config/nvim/init.lua ] && [ -d ~/.config/nvim/lua/plugins ]; then
  echo "✅ nvim config copied successfully"
  rm -rf ~/.config/old_nvim
else
  echo "❌ nvim copy failed — restoring backup"
  rm -rf ~/.config/nvim
  mv ~/.config/old_nvim ~/.config/nvim
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
if command -v kiro &>/dev/null || [ -d ~/.kiro ]; then
  mkdir -p ~/.kiro/steering
  cp "$SCRIPT_DIR/ai/"*.md ~/.kiro/steering/
  echo "✅ AI steering files copied to ~/.kiro/steering/"
else
  echo "⏩ Skipped ~/.kiro/steering/ (kiro not installed)"
fi

if command -v claude &>/dev/null || [ -d ~/.claude ]; then
  mkdir -p ~/.claude/rules
  cp "$SCRIPT_DIR/ai/"*.md ~/.claude/rules/
  echo "✅ AI steering files copied to ~/.claude/rules/"
else
  echo "⏩ Skipped ~/.claude/rules/ (claude not installed)"
fi

# Install JetBrains Mono font
install_jetbrains_mono

# Reload tmux if running
if tmux info &>/dev/null; then
  tmux source-file ~/.tmux.conf
  echo "✅ tmux config reloaded"
fi

echo "🎉 Done. Restart nvim to pick up changes."
