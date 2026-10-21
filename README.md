# terminal-setup

A portable, modular developer terminal environment for macOS, Ubuntu, and WSL, featuring Neovim, tmux, git hooks, cross-platform live sports notifications, and AI steering files for Kiro, Claude Code, and Antigravity CLI.

## Repository Architecture

| Component | Path | Description |
| :--- | :--- | :--- |
| Neovim | `nvim/` | Modular Neovim configuration powered by Lazy.nvim, LSP, Treesitter, Telescope, and Git integration |
| tmux | `tmux.conf` | Terminal multiplexer configuration with vim keybindings, cyan/purple styling, OSC 52 clipboard, and TPM |
| Git Hooks | `git-hooks/` | Global pre-commit hook enforcing branch hygiene and automated rebasing |
| AI Framework | `ai/` | Agent definitions, delegation workflows, digital team pipeline, and global conventions |
| Sports Daemons | `sports/` | Background notification agents and notification helper for live match updates |
| Font Assets | `font/` | JetBrainsMono Nerd Font TTF files for glyph and symbol rendering |
| Helper Scripts | `scripts/` | Automation utilities such as AI configuration synchronization (`sync-ai.sh`) |

## Quick Start

For complete prerequisites and system package setup, see [INSTALL.md](INSTALL.md).

```bash
git clone <repo-url> ~/terminal-setup
cd ~/terminal-setup
./install.sh
```

The installation script automates setup across macOS, Ubuntu, and WSL, installing Neovim, tmux, core CLI utilities (`ripgrep`, `fd`, `node`), fonts, and AI steering configurations.

## AI Steering & Delegation

The `ai/` directory provides unified instruction sets and structured execution pipelines compatible across multiple AI assistants:

- Kiro: CLI (`cli.kiro.dev`) and IDE configurations synced to `~/.kiro/steering/`
- Claude Code: CLI tool synced to `~/.claude/rules/` and `~/.claude/skills/`
- Antigravity CLI: Tooling (`agy`) synced to `~/.gemini/` and `~/.gemini/skills/`

### Modular Skills & Workflows

- Digital Team (`ai/digital-team/`): Phased feature delivery pipeline with planning, adversarial challenge, decoupled TDD, and independent code review.
- Delegation Core (`ai/delegation/`): Working-set rules and sentinel briefs (`[WORKER-BRIEF v1]`) for subagent dispatch.
- Systematic Debugging (`ai/debugging/`): 4-step root-cause reproduction, isolation, minimal fix, and regression verification protocol.
- Humanizer (`ai/humanizer/`): On-demand skill stripping machine writing tropes and buzzwords from documentation and PR summaries.
- Ponytail Heuristics: Simplicity ladder and anti-overengineering checks integrated directly into `worker-standard`, `reviewer`, and code conventions.

### AI Prerequisites

Install the AI tools independently prior to or after running the repository installer:

```bash
# Kiro CLI
curl -fsSL https://cli.kiro.dev/install | bash

# Claude Code
npm install -g @anthropic-ai/claude-code

# Antigravity CLI
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

## Runtime Maintenance

When modifying configurations or pulling updates from the repository, apply changes without reinstalling system dependencies using `reload.sh`:

```bash
cd ~/terminal-setup
./reload.sh
```

The reload script:
1. Backs up active configurations (`nvim`, `tmux`, `git-hooks`).
2. Copies updated configurations and verifies syntax integrity before removing backups.
3. Synchronizes AI steering and rules files via `scripts/sync-ai.sh`.
4. Refreshes active sports agents in `~/.meshclaw/workspace/f1-agent`.
5. Updates font caches and bootstraps TPM (`tmux`) plugins.

## WSL-Specific Notes

- Font Configuration: On WSL, `install.sh` and `reload.sh` copy JetBrainsMono Nerd Font directly to the Windows font catalog. Configure `JetBrainsMono Nerd Font Mono` in Windows Terminal settings.
- Repository Location: Keep repository clones inside the Linux filesystem (`~/terminal-setup` or `/home/<user>/...`) rather than Windows mount paths (`/mnt/c/...`) for optimal I/O performance.

## Acknowledgments

- [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail): Simplicity ladder and anti-overengineering heuristic ("the best code is the code you never wrote") integrated into implementation and review workflows.
- [obra/superpowers](https://github.com/obra/superpowers): Systematic debugging methodology adapted for `ai/debugging/`.
- [blader/humanizer](https://github.com/blader/humanizer): Behavioral rules for detecting and eliminating AI writing tropes adapted for `ai/humanizer/`.

