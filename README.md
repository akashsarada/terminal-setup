# terminal-setup

Neovim + tmux + git hooks + AI steering files — portable across macOS, Ubuntu, and WSL.

## What's included

- **nvim/** — Neovim config (Lazy.nvim, 45 plugins, LSP, treesitter, telescope, gitsigns)
- **tmux.conf** — tmux config (vim nav, cyan/purple theme, OSC 52 clipboard, copy-mode binds)
- **git-hooks/** — pre-commit (auto-rebase)
- **font/** — JetBrainsMono Nerd Font
- **ai/** — AI steering files and delegation framework (Kiro, Claude Code, Antigravity)
- **sports/** — live sports notification agents (cross-platform desktop notifications)

## Setup

See [INSTALL.md](INSTALL.md) for full instructions.

```bash
git clone <repo-url> ~/terminal-setup
cd ~/terminal-setup
./install.sh
```
