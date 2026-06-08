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
  elif grep -qi fedora /etc/*release; then
    OS="fedora"
    ARCH="linux"
  else
    echo "❌ Unsupported Linux Distribution (Only Ubuntu/Fedora supported)"
    exit 1
  fi
else
  echo "❌ Unsupported OS"
  exit 1
fi

echo "✅ Detected OS: $OS"
echo "⏎ Click enter to proceed with full installation"
read

install_common() {
  echo "📦 Installing common tools..."
  if [[ "$OS" == "mac" ]]; then
    brew install git curl ripgrep fd cmake python3 tmux neovim
  elif [[ "$OS" == "fedora" ]]; then
    sudo dnf install -y neovim git curl ripgrep fd-find python3-pip tmux cmake unzip
    if ! command -v fd &> /dev/null; then
      mkdir -p ~/.local/bin
      if [ ! -e ~/.local/bin/fd ]; then
        ln -s "$(which fdfind)" ~/.local/bin/fd
      fi
    fi
  else
    sudo apt update
    sudo apt remove -y neovim || true
    sudo add-apt-repository ppa:neovim-ppa/stable -y
    sudo apt update
    sudo apt install -y neovim git curl ripgrep fd-find python3-pip tmux cmake unzip libarchive-tools
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
    brew install --cask codelldb
  else
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
      cp -r "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
      echo "✅ Overwrote ~/.config/nvim"
    else
      echo "⏩ Skipped ~/.config/nvim"
    fi
  else
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
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
}

# Run all steps
install_common
install_node
install_clang
install_lua
install_codelldb
install_verible
copy_dotfiles
bootstrap_lazy
sync_plugins

echo "🎉 Full Neovim environment setup complete."
