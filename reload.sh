#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup old configs
mv ~/.config/nvim/ ~/.config/old_nvim 2>/dev/null || true
mv ~/.tmux.conf ~/.old_tmux.conf 2>/dev/null || true

# Copy new configs
cp -r "$SCRIPT_DIR/nvim" ~/.config/nvim
cp "$SCRIPT_DIR/tmux.conf" ~/.tmux.conf

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

# Reload tmux if running
if tmux info &>/dev/null; then
  tmux source-file ~/.tmux.conf
  echo "✅ tmux config reloaded"
fi

echo "🎉 Done. Restart nvim to pick up changes."
