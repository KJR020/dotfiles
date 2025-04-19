#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$DOTFILES_DIR/config"

echo "🚀 Starting dotfiles installation..."

# Homebrewのインストールチェックとインストール
if ! command -v brew >/dev/null 2>&1; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed"
fi

# Brewfileからパッケージをインストール
echo "📦 Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Oh My Zshのインストール
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🛠 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "✅ Oh My Zsh is already installed"
fi

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo "🔌 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo "🔌 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# echo "🔗 Creating symbolic links..."

# Git設定のシンボリックリンク
ln -sf "$CONFIG_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$CONFIG_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
ln -sf "$CONFIG_DIR/git/.gitmessage" "$HOME/.gitmessage"

# Zsh設定のシンボリックリンク
ln -sf "$CONFIG_DIR/zsh/.zprofile" "$HOME/.zprofile"
ln -sf "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config/zsh"
ln -sf "$CONFIG_DIR/zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh"

# Bash設定のシンボリックリンク
ln -sf "$CONFIG_DIR/bash/.bash_profile" "$HOME/.bash_profile"
ln -sf "$CONFIG_DIR/bash/.bashrc" "$HOME/.bashrc"


# Vim設定のシンボリックリンク
ln -sf "$CONFIG_DIR/vim/.vimrc" "$HOME/.vimrc"

# MCP設定のシンボリックリンク
echo "🔗 Creating MCP configuration symbolic links..."
# VSCode用MCP設定
mkdir -p "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
ln -sf "$CONFIG_DIR/mcp/vscode.json" "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"

# Windsurf用MCP設定
mkdir -p "$HOME/.codeium/windsurf"
ln -sf "$CONFIG_DIR/mcp/windsurf.json" "$HOME/.codeium/windsurf/mcp_config.json"

# Claude Desktop用MCP設定
mkdir -p "$HOME/Library/Application Support/Claude"
ln -sf "$CONFIG_DIR/mcp/claude.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# fzfのインストール
if [ ! -f "$HOME/.fzf.zsh" ]; then
    echo "🔍 Installing fzf..."
    $(brew --prefix)/opt/fzf/install --all
fi

echo "✨ Installation complete! Please restart your terminal."
