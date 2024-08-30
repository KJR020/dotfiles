# OSを判別
OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
	echo "Running on macOS"
	VSCODE_SETTINGS_PATH=~/Library/Application\ Support/Code/User
elif [[ "$OS" == "Linux" ]]; then
	echo "Running on Linux"
	VSCODE_SETTINGS_PATH=~/.config/Code/User
else
	echo "Running on Windows"
	VSCODE_SETTINGS_PATH="$APPDATA/Code/User"
fi

# VS Codeの設定を変更（macOSのみ）
if [[ "$OS" == "Darwin" ]]; then
	echo "Setting VS Code preferences..."
	defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
fi

# VS Codeの拡張機能をインストール
echo "Installing VS Code extensions..."
code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension esbenp.prettier-vscode

# 必要な設定ファイルをシンボリックリンクとして作成
echo "Creating symbolic links for configuration files..."
ln -sf "$(pwd)/settings.json" "$VSCODE_SETTINGS_PATH/settings.json"
ln -sf "$(pwd)/keybindings.json" "$VSCODE_SETTINGS_PATH/keybindings.json"

echo "VS Code setup completed!"
