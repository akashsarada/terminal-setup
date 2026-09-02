# Installation & Setup Guide

A complete guide for installing, configuring, and maintaining the developer environment, development toolchains, AI steering workflows, and background sports daemons across macOS, Ubuntu/Debian, Fedora/Pop/Cosmic, and WSL.

---

## Quick Start

Clone the repository directly into your home directory and run the interactive installer:

```bash
git clone <repo-url> ~/terminal-setup
cd ~/terminal-setup
./install.sh
```

The installer detects your operating system and walks you through interactive prompts:
- AI coding tools selection (Kiro CLI, Claude Code, Antigravity CLI).
- Live sports notification agents and auto-start service registration.
- Python development toolchain (Pyright LSP, `black`, and `isort`).

---

## Installation & Sync Scripts

The repository provides two lifecycle scripts: `install.sh` for complete initial setup and `reload.sh` for fast incremental synchronization.

### 1. Full Installation (`./install.sh`)

Executes the full bootstrap sequence:
- **OS & Package Management**: Identifies platform (macOS via Homebrew, Ubuntu/Debian via `apt`, Fedora/Pop!_OS/Cosmic via `dnf`, or WSL) and installs essential system packages.
- **Language Toolchains & Compilers**: Builds or installs Neovim 0.11+, Clang/LLVM, LuaJIT, Luarocks, CodeLLDB, and Verible.
- **Python Tooling**: Configures Pyright LSP, `black`, and `isort` if opted in.
- **Typography**: Installs JetBrains Mono Nerd Font to host system font directories (including Windows font registry when running inside WSL).
- **Dotfile Configuration**: Safely deploys `~/.config/nvim`, `~/.tmux.conf`, and `~/.git-hooks`.
- **Plugin Bootstrapping**: Clones and synchronizes Lazy.nvim plugins and Tmux Plugin Manager (TPM) plugins (`tmux-resurrect`, `tmux-continuum`).
- **AI Steering & Rules**: Deploys multi-agent steering files and skills via `scripts/sync-ai.sh`.
- **Sports Daemons**: Sets up the virtual environment in `~/.meshclaw/workspace/f1-agent/` and registers background service daemons (`launchd` or `systemd --user`).

### 2. Fast Incremental Sync (`./reload.sh`)

Applies updates after modifying configuration files or pulling latest Git commits without reinstalling system packages:

```bash
cd ~/terminal-setup
./reload.sh
```

The reload script:
1. Creates safe backups of existing configurations (`~/.config/old_nvim`, `~/.old_tmux.conf`, `~/.old_git-hooks`).
2. Copies updated configurations and verifies syntax and file integrity before removing backups.
3. Synchronizes AI steering and rule definitions across installed AI assistants.
4. Refreshes sports agent source files and control scripts in `~/.meshclaw/workspace/f1-agent/`.
5. Updates font caches and bootstraps any new TPM plugins.
6. Reloads the active tmux session dynamically (`tmux source-file ~/.tmux.conf`).

---

## Tools & Toolchains Installed

| Component | Target Location | Description |
| :--- | :--- | :--- |
| Neovim (v0.11+) | `/opt/nvim` or `/usr/local/bin/nvim` | Latest stable Neovim release with Lazy.nvim, Mason, and Treesitter |
| tmux & TPM | `~/.tmux.conf`, `~/.tmux/plugins/tpm` | Terminal multiplexer with resurrect and continuum session persistence |
| Git Hooks | `~/.git-hooks/pre-commit` | Global pre-commit hook enforcing branch hygiene and automated rebasing |
| Clang / LLVM | System paths | `clangd` language server and `clang-format` code formatter |
| Lua / Luarocks | System paths | LuaJIT runtime and Luarocks package manager |
| CodeLLDB | `~/.local/bin/codelldb` | LLDB-based debugging adapter for C, C++, and Rust |
| Verible | `/usr/local/bin/verible*` | SystemVerilog language server and formatter suite |
| Python Dev Tools | User/System Python | Pyright language server, `black` formatter, and `isort` import sorter |
| Node.js (LTS) | System paths | Node runtime and npm package manager (bootstrapped via `n` on Ubuntu/WSL) |
| CLI Utilities | System paths | `ripgrep`, `fd` (or `fdfind`), `jq`, `cmake`, `cargo`/`rust` |
| Nerd Fonts | System font directory | JetBrains Mono Nerd Font TTF files |

### Global Git Hook

The installer configures `core.hooksPath` to point to `~/.git-hooks`:

```bash
git config --global core.hooksPath ~/.git-hooks
```

The included `pre-commit` hook automatically checks upstream remote status before every commit:
- Verifies if the local branch is up to date or ahead of origin.
- Rejects commits if branches have diverged, preventing accidental overwrites.
- Stashes unstaged changes and runs `git rebase` automatically if local is simply behind upstream.

---

## AI Tooling & Steering Architecture

The repository provides unified instructions, digital team conventions, delegation protocols, and agent definitions across Kiro, Claude Code, and Google Antigravity CLI.

### Manual Installation of AI CLIs

AI tools can be selected during `./install.sh` or installed manually:

#### 1. Kiro (CLI & IDE)
- **CLI (Primary delegation & steering target):**
  ```bash
  curl -fsSL https://cli.kiro.dev/install | bash
  ```
- **IDE (GUI editor, optional):** Download platform packages from [kiro.dev/downloads](https://kiro.dev/downloads).

#### 2. Claude Code
- **macOS:**
  ```bash
  npm install -g @anthropic-ai/claude-code
  ```
- **Ubuntu / Debian / Fedora / WSL:**
  ```bash
  sudo npm install -g @anthropic-ai/claude-code
  ```

#### 3. Antigravity CLI (Google `agy`)
- **Universal installer:**
  ```bash
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  ```
- **macOS (Homebrew cask alternative):**
  ```bash
  brew install --cask antigravity-cli
  ```
- Note: Ensure `~/.local/bin` is exported in your `PATH`.

### AI Configuration & Steering Layout

Running `./install.sh` or `scripts/sync-ai.sh` deploys steering files to the respective configuration directories:

| Tool | Target Path | Deployed Files |
| :--- | :--- | :--- |
| Kiro | `~/.kiro/steering/` | `global-conventions.md`, `code-conventions.md`, `delegation-core.md`, `delegation-kiro-binding.md`, `digital-team.md` |
| Claude Code | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | `CLAUDE.md` (from `ai/AGENTS.md`), `global-conventions.md`, `code-conventions.md`, `delegation-core.md`, `digital-team.md` |
| Antigravity CLI | `~/.gemini/` | `GEMINI.md`, `global-conventions.md`, `code-conventions.md`, `delegation-core.md`, `digital-team.md`, skills in `~/.gemini/skills/`, subagents in `~/.gemini/config/agents/` |

### Antigravity Skills & Subagents Layout

- **Skills (`~/.gemini/skills/`)**:
  - `~/.gemini/skills/delegation-core/SKILL.md`
  - `~/.gemini/skills/digital-team/SKILL.md`
- **Subagents (`~/.gemini/config/agents/`)**:
  - `challenger/agent.md`
  - `reviewer/agent.md`
  - `worker-cheap/agent.md`
  - `worker-standard/agent.md`

Shared templates, adapters, and prompt definitions reside in the repository under `ai/delegation/`, `ai/digital-team/`, and `ai/agents/`.

---

## Background Sports Daemons

The `sports/` directory provides background notification agents for real-time match tracking and race telemetry.

### Agent Directory & Environment

Sports agents are installed into:
```text
~/.meshclaw/workspace/f1-agent/
```

The installer configures a dedicated Python virtual environment at `~/.meshclaw/workspace/f1-agent/.venv` with `websockets` (v14.2) for WebSocket streaming feeds.

### Available Agents & Control Scripts

| Agent | CLI Control Script | Python Entrypoint | Description |
| :--- | :--- | :--- | :--- |
| Cricket | `cricketctl.sh` | `cricket_live.py` | Live match tracking and score notifications |
| World Cup | `wcctl.sh` | `worldcup_live.py` | Live tournament and World Cup match updates |
| Formula 1 | `f1ctl.sh` | `f1_live.py` | Live session telemetry, sector timings, and race events |
| WEC | `wecctl.sh` | `wec_live.py` | World Endurance Championship timing (optional feed) |

Control scripts support standard daemon lifecycle commands:

```bash
~/.meshclaw/workspace/f1-agent/f1ctl.sh start
~/.meshclaw/workspace/f1-agent/f1ctl.sh status
~/.meshclaw/workspace/f1-agent/f1ctl.sh logs
~/.meshclaw/workspace/f1-agent/f1ctl.sh stop
```

### Autostart Management (`sports/install-autostart.sh`)

Background agents can be registered as system login services using `sports/install-autostart.sh`:

- **macOS (`launchd`)**: Generates LaunchAgent property lists in `~/Library/LaunchAgents/local.<agent>-live-agent.plist` and loads them via `launchctl bootstrap`.
- **Linux & WSL (`systemd --user`)**: Generates user service units in `~/.config/systemd/user/<agent>-live-agent.service`, enables persistent lingering via `loginctl enable-linger`, and starts units via `systemctl --user enable --now`.

#### Autostart Commands

```bash
# Install and start default agents (cricket, worldcup, f1)
./sports/install-autostart.sh

# Install specific agents (including optional WEC agent)
./sports/install-autostart.sh f1 cricket wec

# Check daemon registration and execution status
./sports/install-autostart.sh --status

# Preview generated launchd plist or systemd unit without modifying system
./sports/install-autostart.sh --dry-run

# Stop and unregister all background sports services
./sports/install-autostart.sh --uninstall
```

---

## Platform-Specific Notes & Requirements

### macOS
- **Package Manager**: Homebrew (`brew`) is required.
- **Font Directory**: Fonts are copied to `~/Library/Fonts` and font databases are reloaded via `atsutil`.
- **Daemons**: Autostart utilizes native `launchd` user agents.

### Ubuntu / Debian
- **Package Manager**: `apt` is used for base packages.
- **Neovim**: Distro packages in apt lag behind; `install.sh` downloads the official Neovim v0.11+ pre-compiled release tarball to `/opt/nvim` and links `/usr/local/bin/nvim`.
- **Node.js**: Bootstrapped to the latest LTS version using `n`.
- **`fd` binary**: Debian packages name the binary `fdfind`. The installer links `fdfind` to `~/.local/bin/fd`.

### Fedora / Pop!_OS / Cosmic
- **Package Manager**: `dnf` is used for base dependencies.
- **Neovim**: Installed via the official v0.11+ tarball to ensure compatibility with modern Lazy.nvim plugins.
- **`fd` binary**: Symlinked from `fdfind` to `~/.local/bin/fd` if necessary.

### Windows Subsystem for Linux (WSL)
- **Repository Location**: Clone the repository inside the Linux filesystem (`~/terminal-setup`) rather than Windows mount points (`/mnt/c/...`) to ensure fast I/O performance and correct file permissions.
- **Font Configuration**:
  - `install.sh` and `reload.sh` detect WSL and automatically copy JetBrains Mono Nerd Font files to the Windows host font catalog (`%LOCALAPPDATA%\Microsoft\Fonts`).
  - Open **Windows Terminal Settings > Profiles (WSL) > Appearance > Font face** and select `JetBrainsMono Nerd Font Mono`.
- **Systemd Background Services**:
  - `systemd --user` units require WSL systemd support to be active.
  - Add the following configuration to `/etc/wsl.conf` (requires root privileges):
    ```ini
    [boot]
    systemd=true
    ```
  - Restart WSL from PowerShell or Command Prompt:
    ```powershell
    wsl --shutdown
    ```
  - Once enabled, background sports daemons and user linger (`loginctl enable-linger`) run seamlessly across WSL terminal sessions.
