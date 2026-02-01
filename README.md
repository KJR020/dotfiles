# dotfiles

KJR020 dotfiles - chezmoi管理

## 管理対象

### シェル環境
- **Zsh設定** (`.zshrc`, `.zprofile`)
  - Oh My Zshの設定
  - プラグイン設定（zsh-autosuggestions、zsh-syntax-highlighting）
  - エイリアス
  - 履歴設定
  - 補完設定
  - Terraform補完
  - Homebrew PATH設定
  - コンテナランタイム別PATH管理（Docker Desktop / Rancher Desktop）

### エディタ・開発ツール
- **Vim設定** (`.vimrc`)
- **Git設定** (`.gitconfig`, `.gitignore_global`, `.gitmessage`)
  - ユーザー情報（テンプレート化）
  - エイリアス
  - OS別の認証情報ヘルパー設定

### パッケージ管理
- **Homebrew** (`Brewfile`)
  - CLIツール
  - GUIアプリケーション（Cask）
  - VSCode拡張機能

### 秘密情報
- **環境変数** (`.env`)
  - APIキー、トークンなど（Git管理外）

### 管理の仕組み
- **chezmoi**: テンプレート機能でOS別・環境別の設定を動的に生成
- **Bats**: dotfilesの動作をテストで保証

## 構成

```
dotfiles/
├── home/                    # chezmoiで管理するdotfiles
│   ├── .chezmoi.toml.tmpl  # chezmoi設定(環境変数)
│   ├── .chezmoiignore      # 無視するファイル
│   ├── dot_gitconfig.tmpl  # テンプレート化された.gitconfig
│   ├── dot_zshrc.tmpl      # テンプレート化された.zshrc
│   ├── dot_vimrc           # Vim設定
│   └── private_dot_env.tmpl # 秘密情報(.env)
├── install/                 # インストールスクリプト
│   ├── install-all.sh
│   ├── install-homebrew.sh
│   └── install-oh-my-zsh.sh
├── tests/                   # Batsテストスクリプト
│   ├── git.bats
│   └── zsh.bats
├── config/                  # レガシー設定(互換性のため残存)
├── Brewfile                 # Homebrewパッケージリスト
├── Makefile                 # タスクランナー
├── task.md                  # タスク管理
└── README.md                # このファイル
```

## インストール

### 新規インストール

```bash
# 1. リポジトリのクローン
git clone https://github.com/KJR020/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. 全てをインストール (Homebrew + Oh My Zsh + dotfiles適用)
make install
```

### 既存環境からの移行

```bash
# 1. chezmoiとBatsをインストール
make install-homebrew

# 2. chezmoiを初期化
make init

# 3. 差分を確認
make diff

# 4. dotfilesを適用
make apply
```

## 使い方

### 基本コマンド

#### dotfilesの管理

```bash
make init       # chezmoiを初期化
make apply      # chezmoiでdotfilesを適用
make update     # chezmoiでdotfilesを更新
make diff       # chezmoiで差分を確認
```

#### パッケージ管理

```bash
make update-brew   # Brewfileを現在の環境に合わせて更新
make cleanup-brew  # Homebrewのクリーンアップ
```

#### テスト

```bash
make test       # Batsで全テストを実行

# 特定のテストのみ実行
bats tests/git.bats
bats tests/zsh.bats
```

#### その他

```bash
make help          # ヘルプを表示
```

### カスタマイズ

#### 環境変数の設定

chezmoiの環境変数をカスタマイズする場合:

```bash
export CHEZMOI_NAME="Your Name"
export CHEZMOI_EMAIL="your.email@example.com"
export CHEZMOI_GHQ_ROOT="/path/to/ghq/root"
```

#### 新しいdotfileの追加

1. `home/` ディレクトリに追加
   - ドットファイルは `dot_` プレフィックスを使用
   - テンプレートファイルは `.tmpl` 拡張子を追加
   - 秘密情報は `private_` プレフィックスを使用

例:
```bash
# 静的ファイル
home/dot_vimrc → ~/.vimrc

# テンプレートファイル
home/dot_gitconfig.tmpl → ~/.gitconfig

# 秘密情報
home/private_dot_env → ~/.env (gitで管理しない)
```

2. テストを作成 (`tests/` ディレクトリ)

3. chezmoiを適用
```bash
make apply
```

#### Brewfileの更新

新しいパッケージを追加した後:

```bash
make update-brew
```

### 診断とメンテナンス

#### chezmoi

```bash
# chezmoiの状態確認
chezmoi doctor

# 管理対象ファイルの一覧
chezmoi managed

# 差分の詳細確認
chezmoi diff
```

#### Homebrew

```bash
# Homebrewの診断
brew doctor

# キャッシュのクリア
brew cleanup
```

#### Oh My Zsh

```bash
# キャッシュのクリア
rm -rf ~/.zcompdump*

# プラグインの再インストール
make install-oh-my-zsh
```

## ドキュメント

- 詳細なドキュメントは以下を参照
  - [chezmoi運用ガイド](docs/chezmoi.md)

## 参考

- [chezmoi公式ドキュメント](https://www.chezmoi.io/)
- [Bats公式ドキュメント](https://bats-core.readthedocs.io/)
- [テスト可能なdotfiles管理をchezmoiで実現する](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
