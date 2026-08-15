#!/usr/bin/env bash

set -e

# Resolve script directory at start before any cd command is executed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
OS=""
ARCH=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
  ARCH="macos"
elif [[ -f /etc/lsb-release ]] || [[ -f /etc/os-release ]]; then
  if grep -qi ubuntu /etc/*release; then
    OS="ubuntu"
    ARCH="linux"
  elif grep -qi fedora /etc/*release || grep -qi cosmic /etc/*release || grep -qi pop /etc/*release; then
    OS="fedora"
    ARCH="linux"
  else
    echo "❌ Unsupported Linux Distribution (Only Ubuntu/Fedora/Cosmic supported)"
    exit 1
  fi
else
  echo "❌ Unsupported OS"
  exit 1
fi

echo "✅ Detected OS: $OS"
read

# AI tool selection
INSTALL_KIRO=false
INSTALL_CLAUDE=false
INSTALL_ANTIGRAVITY=false
INSTALL_SPORTS=false
SPORTS_AUTOSTART=false

# Live sports agents (F1 / cricket / World Cup) live in the MeshClaw workspace and
# share this cross-platform notification backend.
SPORTS_AGENT_DIR="$HOME/.meshclaw/workspace/f1-agent"

prompt_sports_notifiers() {
  echo ""
  read -rp "🏟️  Install sports notifiers? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_SPORTS=true
  # Only worth asking when the agents are actually going in
  if [[ "$INSTALL_SPORTS" == true ]]; then
    read -rp "  Start them automatically on login? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] && SPORTS_AUTOSTART=true
  fi
  return 0
}

install_sports_notifiers() {
  if [[ "$INSTALL_SPORTS" != true ]]; then
    echo "⏩ Skipped sports notifiers (not selected)"
    return
  fi
  echo "📦 Installing sports notifiers..."
  mkdir -p "$SPORTS_AGENT_DIR"

  cp "$SCRIPT_DIR/sports/notify_helper.py" "$SPORTS_AGENT_DIR/notify_helper.py"
  cp "$SCRIPT_DIR/sports/agents/"*.py "$SPORTS_AGENT_DIR/"
  cp "$SCRIPT_DIR/sports/agents/"*.sh "$SPORTS_AGENT_DIR/"
  chmod +x "$SPORTS_AGENT_DIR/"*.sh
  echo "✅ Agents + control scripts copied to $SPORTS_AGENT_DIR"

  # The ctl scripts all invoke $SPORTS_AGENT_DIR/.venv/bin/python3, and the F1/WEC
  # agents need websockets, so the venv has to exist before anything can start.
  if [ ! -x "$SPORTS_AGENT_DIR/.venv/bin/python3" ]; then
    python3 -m venv "$SPORTS_AGENT_DIR/.venv" || {
      echo "⚠️  Could not create the agent venv — ctl scripts won't run until it exists"
      return
    }
  fi
  if "$SPORTS_AGENT_DIR/.venv/bin/python3" -c "import websockets" 2>/dev/null; then
    echo "✅ Agent venv ready (websockets already present)"
  elif "$SPORTS_AGENT_DIR/.venv/bin/pip" install --quiet "websockets==14.2"; then
    echo "✅ Agent venv ready (installed websockets 14.2)"
  else
    echo "⚠️  websockets install failed — F1/WEC need it: $SPORTS_AGENT_DIR/.venv/bin/pip install websockets==14.2"
  fi

  if [[ "$SPORTS_AUTOSTART" == true ]]; then
    if "$SCRIPT_DIR/sports/install-autostart.sh"; then
      echo "✅ Auto-start on login configured"
    else
      echo "⚠️  Auto-start setup failed — agents are installed, start them manually:"
      echo "    $SPORTS_AGENT_DIR/cricketctl.sh start   (also wcctl / f1ctl / wecctl)"
    fi
  else
    echo "ℹ️  Start one with: $SPORTS_AGENT_DIR/cricketctl.sh start   (also wcctl / f1ctl / wecctl)"
    echo "ℹ️  Auto-start later with: $SCRIPT_DIR/sports/install-autostart.sh"
  fi
}

# Development tools selection
INSTALL_PYTHON_DEV=false

prompt_ai_tools() {
  echo ""
  echo "🤖 Which AI coding tools do you want to install + configure?"
  read -rp "  Kiro? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_KIRO=true
  read -rp "  Claude Code? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_CLAUDE=true
  read -rp "  Antigravity? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_ANTIGRAVITY=true
  # A trailing '[[ ]] && VAR=true' returns 1 when the test fails, which under
  # 'set -e' would abort the whole install. Always exit this function cleanly.
  return 0
}

prompt_dev_tools() {
  echo ""
  echo "🔧 Which development tools do you want to install?"
  echo "   Pyright: Python LSP for code intelligence (autocomplete, type checking)"
  echo "   Black/isort: Python code formatters (recommended for consistent style)"
  read -rp "  Python development tools (Pyright LSP + formatters)? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_PYTHON_DEV=true
}

install_ai_tools() {
  if [[ "$INSTALL_KIRO" == true ]]; then
    echo "📦 Installing Kiro CLI..."
    if command -v kiro &>/dev/null; then
      echo "✅ Kiro already installed — skipping"
    else
      curl -fsSL https://cli.kiro.dev/install | bash
    fi
    echo "ℹ️  For the Kiro IDE (GUI), download from https://kiro.dev/downloads"
  fi
  if [[ "$INSTALL_CLAUDE" == true ]]; then
    echo "📦 Installing Claude Code..."
    if command -v claude &>/dev/null; then
      echo "✅ Claude Code already installed — skipping"
    else
      npm install -g @anthropic-ai/claude-code || sudo npm install -g @anthropic-ai/claude-code
    fi
  fi
  if [[ "$INSTALL_ANTIGRAVITY" == true ]]; then
    echo "📦 Installing Antigravity CLI (agy)..."
    if command -v agy &>/dev/null; then
      echo "✅ Antigravity already installed — skipping"
    else
      curl -fsSL https://antigravity.google/cli/install.sh | bash
    fi
  fi
}

install_neovim_tarball() {
  # Distro repos (apt/dnf) lag behind — the config needs 0.11+. Install the
  # official release tarball, which is always the latest stable.
  if command -v nvim &>/dev/null && nvim --version | head -1 | grep -qE 'v0\.(1[1-9]|[2-9][0-9])'; then
    echo "✅ Neovim $(nvim --version | head -1 | awk '{print $2}') already installed — skipping"
    return
  fi
  local NVIM_ARCH="x86_64"
  if [[ "$(uname -m)" == "aarch64" ]] || [[ "$(uname -m)" == "arm64" ]]; then
    NVIM_ARCH="arm64"
  fi
  cd /tmp
  curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
  sudo mv "/opt/nvim-linux-${NVIM_ARCH}" /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -f "nvim-linux-${NVIM_ARCH}.tar.gz"
  echo "✅ Neovim $(nvim --version | head -1 | awk '{print $2}') installed to /opt/nvim"
}

install_common() {
  echo "📦 Installing common tools..."
  if [[ "$OS" == "mac" ]]; then
    brew install git curl ripgrep fd cmake python3 tmux neovim jq
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y git curl ripgrep fd-find python3-pip tmux cmake unzip jq
    install_neovim_tarball
    if ! command -v fd &> /dev/null; then
      mkdir -p ~/.local/bin
      if [ ! -e ~/.local/bin/fd ]; then
        ln -s "$(which fdfind)" ~/.local/bin/fd
      fi
    fi
  else
    sudo apt update
    sudo apt install -y git curl ripgrep fd-find python3-pip tmux cmake unzip libarchive-tools jq
    install_neovim_tarball
    if ! command -v fd &> /dev/null; then
      mkdir -p ~/.local/bin
      if [ ! -e ~/.local/bin/fd ]; then
        ln -s "$(which fdfind)" ~/.local/bin/fd
      fi
    fi
  fi
}

install_node() {
  echo "📦 Installing Node.js (LTS)..."
  if [[ "$OS" == "mac" ]]; then
    brew install node
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y nodejs npm
  else
    sudo apt install -y nodejs npm
    sudo npm install -g n
    sudo n lts
  fi
}

install_clang() {
  echo "📦 Installing Clang tools..."
  if [[ "$OS" == "mac" ]]; then
    brew install llvm
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y clang-tools-extra clang
  else
    sudo apt install -y clangd clang-format
  fi
}

install_lua() {
  echo "📦 Installing LuaJIT and Luarocks..."
  if [[ "$OS" == "mac" ]]; then
    brew install luajit luarocks
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y luajit luarocks
  else
    sudo apt install -y luajit luarocks
  fi
}

install_codelldb() {
  echo "📦 Installing codelldb..."
  if [[ "$OS" == "mac" ]]; then
    if command -v codelldb &>/dev/null || brew list --cask codelldb &>/dev/null; then
      echo "✅ codelldb already installed — skipping"
      return
    fi
    brew install --cask codelldb
  else
    if [ -x ~/.local/bin/codelldb ] || [ -x ~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb ]; then
      echo "✅ codelldb already installed — skipping"
      return
    fi
    mkdir -p ~/.local/bin
    cd /tmp
    local ARCH_SUFFIX="linux-x64"
    if [[ "$(uname -m)" == "aarch64" ]] || [[ "$(uname -m)" == "arm64" ]]; then
      ARCH_SUFFIX="linux-arm64"
    fi
    curl -L -o codelldb.vsix "https://github.com/vadimcn/codelldb/releases/latest/download/codelldb-${ARCH_SUFFIX}.vsix"
    mkdir -p ~/.local/share/nvim/mason/packages/codelldb/extension
    unzip -o codelldb.vsix -d ~/.local/share/nvim/mason/packages/codelldb/extension
    ln -sf ~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb ~/.local/bin/codelldb
  fi
}

install_pyright() {
  if [[ "$INSTALL_PYTHON_DEV" != true ]]; then
    return
  fi
  
  echo "📦 Installing Pyright (Python LSP)..."
  
  # Check if pyright is available as a command
  if command -v pyright &>/dev/null; then
    echo "✅ Pyright already installed — skipping"
    return
  fi
  
  # Check if pip3 is available
  if ! command -v pip3 &>/dev/null; then
    echo "⚠️  pip3 is not available. Installing pip3 first..."
    if [[ "$OS" == "mac" ]]; then
      brew install python3
    elif [[ "$OS" == "fedora" ]]; then
      sudo dnf install -y python3-pip
    else
      sudo apt install -y python3-pip
    fi
  fi
  
  echo "Installing Pyright via pip..."
  if [[ "$OS" == "mac" ]]; then
    pip3 install pyright
  else
    # Use pip3 with sudo if needed, but try user install first
    if pip3 install --user pyright; then
      echo "✅ Pyright installed to user directory"
    else
      echo "⚠️  User install failed, trying system install..."
      sudo pip3 install pyright
    fi
  fi
  
  # Check installation
  if command -v pyright &>/dev/null; then
    echo "✅ Pyright installed successfully"
    pyright --version || echo "Pyright command available"
  elif command -v pyright-langserver &>/dev/null; then
    echo "✅ Pyright langserver installed (as pyright-langserver)"
  else
    echo "⚠️  Pyright installation may have succeeded but not in PATH"
    echo "    Try adding ~/.local/bin to your PATH:"
    echo "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    echo "    source ~/.bashrc"
  fi
}

install_python_formatters() {
  if [[ "$INSTALL_PYTHON_DEV" != true ]]; then
    return
  fi
  
  echo "📦 Installing Python formatters (black, isort)..."
  
  # Check if pip3 is available
  if ! command -v pip3 &>/dev/null; then
    echo "⚠️  pip3 is not available. Skipping Python formatters."
    return
  fi
  
  # Check if black is already installed
  if pip3 list | grep -i black &>/dev/null; then
    echo "✅ Black already installed — skipping"
  else
    echo "Installing black..."
    if [[ "$OS" == "mac" ]]; then
      pip3 install black
    else
      pip3 install --user black || sudo pip3 install black
    fi
    echo "✅ Black installed"
  fi
  
  # Check if isort is already installed
  if pip3 list | grep -i isort &>/dev/null; then
    echo "✅ isort already installed — skipping"
  else
    echo "Installing isort..."
    if [[ "$OS" == "mac" ]]; then
      pip3 install isort
    else
      pip3 install --user isort || sudo pip3 install isort
    fi
    echo "✅ isort installed"
  fi
  
  echo "✅ Python formatters installed"
}

install_verible() {
  echo "📦 Installing Verible..."
  if command -v verible-verilog-ls &>/dev/null || [ -x /usr/local/bin/verible-verilog-ls ]; then
    echo "✅ Verible already installed — skipping"
    return
  fi
  cd /tmp

  VERSION=$(curl -s https://api.github.com/repos/chipsalliance/verible/releases/latest | grep tag_name | cut -d '"' -f4)
  
  local FILENAME
  if [[ "$OS" == "mac" ]]; then
    FILENAME="verible-${VERSION}-macOS.tar.gz"
  else
    local ARCH_SUFFIX="linux-static-x86_64"
    if [[ "$(uname -m)" == "aarch64" ]] || [[ "$(uname -m)" == "arm64" ]]; then
      ARCH_SUFFIX="linux-static-arm64"
    fi
    FILENAME="verible-${VERSION}-${ARCH_SUFFIX}.tar.gz"
  fi

  curl -LO "https://github.com/chipsalliance/verible/releases/download/${VERSION}/${FILENAME}"
  tar -xzf "$FILENAME"

  echo "🔧 Copying Verible binaries to /usr/local/bin..."
  sudo cp "verible-${VERSION}/bin/"* /usr/local/bin/
  sudo chmod +x /usr/local/bin/verible*

  # Cleanup
  rm -f "$FILENAME"
  rm -rf "verible-${VERSION}"

  echo "✅ Verible installed to /usr/local/bin"
}

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

  # WSL: also install to Windows side so the terminal emulator can use it
  if grep -qi microsoft /proc/version 2>/dev/null; then
    local WIN_USER
    WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [[ -n "$WIN_USER" ]]; then
      local WIN_FONT_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Fonts"
      mkdir -p "$WIN_FONT_DIR"
      cp "$SCRIPT_DIR/font/"*.ttf "$WIN_FONT_DIR/"
      echo "✅ Also installed to Windows fonts ($WIN_FONT_DIR)"
      echo "ℹ️  Select 'JetBrainsMono Nerd Font Mono' in Windows Terminal settings"
    else
      echo "⚠️  WSL detected but couldn't determine Windows user. Install fonts manually:"
      echo "   cp font/*.ttf /mnt/c/Users/<YOU>/AppData/Local/Microsoft/Fonts/"
    fi
  fi
}

bootstrap_lazy() {
  echo "📁 Checking Lazy.nvim installation..."
  if [ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    echo "🚀 Bootstrapping Lazy.nvim..."
    git clone https://github.com/folke/lazy.nvim.git "$HOME/.local/share/nvim/lazy/lazy.nvim"
  else
    echo "✅ Lazy.nvim already installed."
  fi
}

sync_plugins() {
  echo "🔄 Running Lazy sync..."
  nvim --headless "+Lazy! sync" +qa
  echo "✅ Lazy.nvim plugins synced successfully"
}

copy_dotfiles() {
  echo "📂 Preparing to copy Neovim config and tmux.conf..."

  # Handle ~/.config/nvim
  if [ -e "$HOME/.config/nvim" ]; then
    read -rp "⚠️  ~/.config/nvim already exists. Overwrite it? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm -rf "$HOME/.config/nvim"
      mkdir -p "$HOME/.config"
      cp -r "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
      echo "✅ Overwrote ~/.config/nvim"
    else
      echo "⏩ Skipped ~/.config/nvim"
    fi
  else
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
    echo "✅ Copied nvim config to ~/.config/nvim"
  fi

  # Handle ~/.git-hooks
  if [ -e "$HOME/.git-hooks" ]; then
    read -rp "⚠️  ~/.git-hooks already exists. Overwrite it? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm -rf "$HOME/.git-hooks"
      cp -r "$SCRIPT_DIR/git-hooks" "$HOME/.git-hooks"
      echo "✅ Overwrote ~/.git-hooks"
    else
      echo "⏩ Skipped ~/.git-hooks"
    fi
  else
    cp -r "$SCRIPT_DIR/git-hooks" "$HOME/.git-hooks"
    echo "✅ Copied git-hooks to ~/.git-hooks"
  fi
  chmod +x "$HOME/.git-hooks/"*
  git config --global core.hooksPath "$HOME/.git-hooks"
  echo "✅ Set global git hooksPath to ~/.git-hooks"

  # Handle ~/.tmux.conf
  if [ -e "$HOME/.tmux.conf" ]; then
    read -rp "⚠️  ~/.tmux.conf already exists. Overwrite it? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
      echo "✅ Overwrote ~/.tmux.conf"
    else
      echo "⏩ Skipped ~/.tmux.conf"
    fi
  else
    cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Copied tmux config to ~/.tmux.conf"
  fi
  # Handle AI steering files (for selected tools or already-installed ones)
  if [[ "$INSTALL_KIRO" == true ]] || command -v kiro &>/dev/null || [ -d "$HOME/.kiro" ]; then
    mkdir -p "$HOME/.kiro/steering"
    cp "$SCRIPT_DIR/ai/global-conventions.md" "$HOME/.kiro/steering/"
    cp "$SCRIPT_DIR/ai/code-conventions.md" "$HOME/.kiro/steering/"
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.kiro/steering/delegation-core.md"
    cp "$SCRIPT_DIR/ai/delegation/adapters/kiro-binding.md" "$HOME/.kiro/steering/delegation-kiro-binding.md"
    echo "✅ Copied AI steering files to ~/.kiro/steering/"
  else
    echo "⏩ Skipped ~/.kiro/steering/ (kiro not selected/installed)"
  fi

  if [[ "$INSTALL_CLAUDE" == true ]] || command -v claude &>/dev/null || [ -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude/rules"
    cp "$SCRIPT_DIR/ai/global-conventions.md" "$HOME/.claude/rules/"
    cp "$SCRIPT_DIR/ai/code-conventions.md" "$HOME/.claude/rules/"
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.claude/rules/delegation-core.md"
    echo "✅ Copied AI steering files to ~/.claude/rules/"
  else
    echo "⏩ Skipped ~/.claude/rules/ (claude not selected/installed)"
  fi

  if [[ "$INSTALL_ANTIGRAVITY" == true ]] || command -v agy &>/dev/null || [ -d "$HOME/.gemini" ]; then
    mkdir -p "$HOME/.gemini/skills/delegation-core"
    mkdir -p "$HOME/.gemini/agents"
    cp "$SCRIPT_DIR/ai/global-conventions.md" "$HOME/.gemini/"
    cp "$SCRIPT_DIR/ai/code-conventions.md" "$HOME/.gemini/"
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.gemini/delegation-core.md"
    cp "$SCRIPT_DIR/ai/delegation/workers/skill/SKILL.md" "$HOME/.gemini/skills/delegation-core/SKILL.md"
    cp "$SCRIPT_DIR/ai/delegation/workers/antigravity/"*.json "$HOME/.gemini/agents/"
    echo "✅ Copied AI steering, skill, and agent files to ~/.gemini/"
  else
    echo "⏩ Skipped ~/.gemini/ (antigravity not selected/installed)"
  fi
}

# Run all steps
prompt_ai_tools
prompt_sports_notifiers
prompt_dev_tools
echo "⏎ Click enter to proceed with full installation"
install_common
install_node
install_ai_tools
install_clang
install_lua
install_codelldb
install_verible
install_pyright
install_python_formatters
install_jetbrains_mono
install_sports_notifiers
copy_dotfiles
bootstrap_lazy
sync_plugins

echo "🎉 Full Neovim environment setup complete."
