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
echo "⏎ Click enter to proceed with full installation"
read

# AI tool selection
INSTALL_KIRO=false
INSTALL_CLAUDE=false
INSTALL_ANTIGRAVITY=false

prompt_ai_tools() {
  echo ""
  echo "🤖 Which AI coding tools do you want to install + configure?"
  read -rp "  Kiro? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_KIRO=true
  read -rp "  Claude Code? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_CLAUDE=true
  read -rp "  Antigravity? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_ANTIGRAVITY=true
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
    echo "📦 Installing Antigravity..."
    if command -v agy &>/dev/null; then
      echo "✅ Antigravity already installed — skipping"
    else
      npm install -g @google/antigravity || sudo npm install -g @google/antigravity
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
    brew install git curl ripgrep fd cmake python3 tmux neovim
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y git curl ripgrep fd-find python3-pip tmux cmake unzip
    install_neovim_tarball
    if ! command -v fd &> /dev/null; then
      mkdir -p ~/.local/bin
      if [ ! -e ~/.local/bin/fd ]; then
        ln -s "$(which fdfind)" ~/.local/bin/fd
      fi
    fi
  else
    sudo apt update
    sudo apt install -y git curl ripgrep fd-find python3-pip tmux cmake unzip libarchive-tools
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
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.kiro/steering/delegation-core.md"
    cp "$SCRIPT_DIR/ai/delegation/adapters/kiro-binding.md" "$HOME/.kiro/steering/delegation-kiro-binding.md"
    echo "✅ Copied AI steering files to ~/.kiro/steering/"
  else
    echo "⏩ Skipped ~/.kiro/steering/ (kiro not selected/installed)"
  fi

  if [[ "$INSTALL_CLAUDE" == true ]] || command -v claude &>/dev/null || [ -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude/rules"
    cp "$SCRIPT_DIR/ai/global-conventions.md" "$HOME/.claude/rules/"
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.claude/rules/delegation-core.md"
    echo "✅ Copied AI steering files to ~/.claude/rules/"
  else
    echo "⏩ Skipped ~/.claude/rules/ (claude not selected/installed)"
  fi

  if [[ "$INSTALL_ANTIGRAVITY" == true ]] || command -v agy &>/dev/null || [ -d "$HOME/.gemini" ]; then
    mkdir -p "$HOME/.gemini"
    cp "$SCRIPT_DIR/ai/global-conventions.md" "$HOME/.gemini/"
    cp "$SCRIPT_DIR/ai/delegation/core.md" "$HOME/.gemini/delegation-core.md"
    echo "✅ Copied AI steering files to ~/.gemini/"
  else
    echo "⏩ Skipped ~/.gemini/ (antigravity not selected/installed)"
  fi
}

# Run all steps
prompt_ai_tools
install_common
install_node
install_ai_tools
install_clang
install_lua
install_codelldb
install_verible
install_jetbrains_mono
copy_dotfiles
bootstrap_lazy
sync_plugins

echo "🎉 Full Neovim environment setup complete."
