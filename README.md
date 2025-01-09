# dotfiles

KJR020 dotfiles 

## 特徴

- 🚀 ワンライナーでの環境構築
- 📦 Homebrewによるパッケージ管理
- 🛠 Oh My Zshベースの強力なシェル環境
- 🔧 整理された設定ファイル群
- 🔍 fuzzy finderによる高速な検索
- 🐳 Docker関連のエイリアスと設定

## 構成

```
dotfiles/
├── install.sh          # インストールスクリプト
├── README.md           # このファイル
├── Brewfile            # Homebrewパッケージリスト
├── config/
│   ├── git/           # Git関連の設定
│   │   ├── .gitconfig
│   │   ├── .gitignore_global
│   │   └── .gitmessage
│   ├── zsh/           # Zsh関連の設定
│   │   ├── .zshrc
│   │   └── aliases.zsh
│   └── vim/           # Vim関連の設定
│       └── .vimrc
└── scripts/           # その他のスクリプト
```

## インストール

```bash
# リポジトリのクローン
git clone https://github.com/KJR020/dotfiles.git ~/dotfiles

# インストールスクリプトの実行
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 主な機能

### Zsh設定
- Oh My Zshベースの設定
- 便利なエイリアス群
- 補完機能の強化
- シンタックスハイライト
- コマンド履歴の改善

### Git設定
- 便利なエイリアス
- コミットメッセージテンプレート
- グローバルな.gitignore
- 日本語ファイル名の文字化け防止

### ツール

- fzf: ファジーファインダー
- zoxide: スマートなディレクトリ移動
- ghq: リポジトリ管理
- Volta: Node.jsバージョン管理
- uv: 高速なPythonパッケージマネージャー

## カスタマイズ

- 各設定ファイルは`config/`ディレクトリ以下で管理する

### Brewfile更新

- 新しいパッケージを追加した後は以下のコマンドで更新する

```bash
brew bundle dump --force
```

## トラブルシューティング

### シンボリックリンクの問題

- 既存のdotfilesがある場合は、バックアップを取ってから削除する

```bash
mv ~/.zshrc ~/.zshrc.backup
```

### Homebrew関連の問題
- Homebrewのインストールに失敗する場合

```bash
# Homebrewの診断
brew doctor

# キャッシュのクリア
brew cleanup
```

### Oh My Zsh関連の問題

- プラグインが正しく動作しない場合

```bash
# キャッシュのクリア
rm -rf ~/.zcompdump*
```
