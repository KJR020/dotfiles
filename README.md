# dotfiles

KJR020 dotfiles - chezmoi管理

## 管理対象

### シェル環境
- **Zsh設定** (`.zshrc`, `.zprofile`)
  - プラグイン設定（Homebrew配布の `zsh-autosuggestions` / `zsh-syntax-highlighting`）
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
- **devtools** (`devtools/`)
  - Homebrew定義（`devtools/brew/*.Brewfile`）
  - Node.js製CLI定義（`devtools/volta/packages.txt`）
  - Python製CLI定義（`devtools/uv/tools.txt`）

### 秘密情報
- **環境変数** (`.env`)
  - APIキー、トークンなど（Git管理外）

### 管理の仕組み
- **chezmoi**: テンプレート機能でOS別・環境別の設定を動的に生成
- **Bats**: dotfilesの動作をテストで保証

## 構成

```
dotfiles/
├── devtools/               # 開発ツールの定義（SoT）
│   ├── brew/              # Homebrew Bundle定義
│   ├── volta/             # Volta管理CLI定義
│   └── uv/                # uv tool管理CLI定義
├── home/                    # chezmoiで管理するdotfiles
│   ├── .chezmoi.toml.tmpl  # chezmoi設定(環境変数)
│   ├── .chezmoiignore      # 無視するファイル
│   ├── dot_gitconfig.tmpl  # テンプレート化された.gitconfig
│   ├── dot_zshrc.tmpl      # テンプレート化された.zshrc
│   ├── dot_vimrc           # Vim設定
│   └── private_dot_env.tmpl # 秘密情報(.env)
├── tests/                   # Batsテストスクリプト
│   ├── git.bats
│   └── zsh.bats
├── docs/                    # 運用ドキュメント
│   ├── chezmoi.md
│   └── adr/
├── Makefile                 # タスクランナー
└── README.md                # このファイル
```

## インストール

### 新規インストール

```bash
# 1. リポジトリのクローン
git clone https://github.com/KJR020/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. chezmoiを初期化してdotfilesを適用
make install
```

### 既存環境からの移行

```bash
# 1. 必要ツールをインストール
brew install chezmoi bats-core

# 2. chezmoiを初期化
make init

# 3. 差分を確認
make diff

# 4. dotfilesを適用
make apply
```

### Ubuntuで使う場合

- Ubuntuでも `chezmoi` テンプレートは利用可能です（`home/` 配下はOS分岐対応）。
- パッケージ同期コマンド（`make brew-sync` など）は Homebrew/Linuxbrew の導入を前提にしています。
- Git credential helper はOSごとに自動分岐されます（macOS: `osxkeychain` / Linux: `cache --timeout=36000`）。

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
make brew-sync BREW_PROFILE=profile1  # profile1のBrewfileを適用
make brew-dump BREW_PROFILE=profile1  # 現在のbrew状態を定義へ反映
make volta-sync                        # Volta定義を同期
make uv-sync                           # uv tool定義を同期
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
make brew-dump BREW_PROFILE=profile1
```

#### 開発ツール管理ポリシー

- Homebrew: システムパッケージとGUIアプリを管理
- Volta: Node.js製グローバルCLIを管理（例: `agent-browser`）
- uv tool: Python製グローバルCLIを管理
- 同一CLIを複数のツールマネージャで重複管理しない
- 管理ファイルを唯一の定義（SoT）として運用する

詳細な背景と判断理由はADRを参照:

```bash
docs/adr/0001-devtools-toolchain-split.md
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

#### Zsh

```bash
# キャッシュのクリア
rm -rf ~/.zcompdump*
```

## ドキュメント

- 詳細なドキュメントは以下を参照
  - [chezmoi運用ガイド](docs/chezmoi.md)
  - [ADR-0001: devtoolsでのツール管理分離](docs/adr/0001-devtools-toolchain-split.md)

## 参考

- [chezmoi公式ドキュメント](https://www.chezmoi.io/)
- [Bats公式ドキュメント](https://bats-core.readthedocs.io/)
- [テスト可能なdotfiles管理をchezmoiで実現する](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
