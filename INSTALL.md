# Installation Guide

## Quick Start

```bash
git clone <repo-url> ~/terminal-setup
cd ~/terminal-setup
./install.sh
```

The install script handles: neovim, tmux, ripgrep, fd, node, git hooks, fonts, and AI steering files.

## AI Tools (manual install)

The install script copies steering/rules files for each tool if it detects them on the system. Install the tools themselves separately:

### Kiro

**macOS:**
```bash
brew install --cask kiro
```

**Ubuntu / WSL:**
```bash
# Download .deb from https://kiro.dev/downloads
sudo dpkg -i kiro_*.deb
```

**Fedora / Cosmic:**
```bash
# Download .rpm from https://kiro.dev/downloads
sudo dnf install ./kiro_*.rpm
```

### Claude Code

**macOS:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Ubuntu / WSL:**
```bash
sudo npm install -g @anthropic-ai/claude-code
```

**Fedora / Cosmic:**
```bash
sudo npm install -g @anthropic-ai/claude-code
```

### Antigravity (Google)

**macOS:**
```bash
npm install -g @google/antigravity
```

**Ubuntu / WSL:**
```bash
sudo npm install -g @google/antigravity
```

**Fedora / Cosmic:**
```bash
sudo npm install -g @google/antigravity
```

## AI Steering Files

After installing the tools and running `install.sh`, steering files are placed at:

| Tool | Location | Files |
|---|---|---|
| Kiro | `~/.kiro/steering/` | global-conventions, delegation-core, delegation-kiro-binding |
| Claude Code | `~/.claude/rules/` | global-conventions, delegation-core |
| Antigravity | `~/.gemini/` | global-conventions, delegation-core |

On-demand files (adapters, worker specs) are read from `~/terminal-setup/ai/delegation/` — no copying needed, the repo IS the source.

## WSL-Specific Notes

- **Font**: The install script detects WSL and copies JetBrainsMono Nerd Font to the Windows fonts directory automatically. Select "JetBrainsMono Nerd Font Mono" in Windows Terminal settings after install.
- **Path**: Clone the repo to `~/terminal-setup` directly (no symlink needed).
- **Node**: The script installs Node via `n` (LTS). If you have nvm/fnm, skip the `install_node` step.

## Reload (after config changes)

```bash
cd ~/terminal-setup
./reload.sh
```

Copies updated configs without reinstalling system packages. Also re-copies steering files.
