# chezmoi運用ガイド

- このリポジトリでのchezmoi運用方法をまとめたドキュメント

## クイックスタート

### 基本コマンド

| コマンド                  | 説明                      |
|-----------------------|---------------------------|
| `chezmoi init KJR020` | 初期化（最初の1回のみ）        |
| `chezmoi apply`       | dotfilesをホームディレクトリに適用   |
| `chezmoi update`      | リポジトリの更新と適用を同時に実行 |

---

## 基本的な運用フロー

### パターン1: dotfilesで編集（推奨）

```bash
# 1. dotfilesで編集
cd ~/dotfiles
vim home/dot_gitconfig.tmpl

# 2. 反映
make apply

# 3. コミット
git add home/dot_gitconfig.tmpl
git commit -m "🔧 設定を更新"
```

### パターン2: ホームで編集（実験時）

```bash
# 1. ホームで編集
vim ~/.zshrc

# 2. 動作確認
source ~/.zshrc

# 3. dotfilesに反映
chezmoi re-add ~/.zshrc

# 4. コミット
cd ~/dotfiles
git add home/dot_zshrc.tmpl
git commit -m "🔧 設定を更新"
```

---

## このリポジトリの構成

### ファイル命名規則

| dotfiles内             | ホーム内                 | 説明         |
|------------------------|-----------------------|--------------|
| `dot_gitconfig.tmpl`   | `~/.gitconfig`        | テンプレート処理あり |
| `dot_vimrc`            | `~/.vimrc`            | 静的ファイル     |
| `private_dot_env.tmpl` | `~/.env`              | Git管理外    |
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | ディレクトリ       |

### テンプレート変数

このリポジトリで使える変数は[home/.chezmoi.toml.tmpl](../home/.chezmoi.toml.tmpl)で定義：

```toml
{{ .name }}         # KJR020
{{ .email }}        # johnjiro1114@gmail.com
{{ .ghq_root }}     # /Users/kjr020/work/
{{ .chezmoi.os }}   # darwin / linux
```

使用例:
```ini
# dot_gitconfig.tmpl
[user]
    email = {{ .email }}
    name = {{ .name }}
```

---

## コマンドリファレンス

### ファイル管理

| コマンド                    | 説明                            |
|-------------------------|---------------------------------|
| `chezmoi add <file>`    | 新しいファイルを管理に追加              |
| `chezmoi re-add <file>` | 既存ファイルを再取り込み（ホームで編集した後） |
| `chezmoi managed`       | 管理中のファイル一覧を表示            |

### 確認・差分

| コマンド                                | 説明                   |
|-------------------------------------|------------------------|
| `chezmoi diff`                      | 差分を確認              |
| `chezmoi cat <file>`                | テンプレート展開結果を表示    |
| `chezmoi doctor`                    | 診断を実行              |
| `chezmoi apply --dry-run --verbose` | dry-run（実際には適用しない） |

### 適用・更新

| コマンド             | 説明                      |
|------------------|---------------------------|
| `chezmoi apply`  | dotfilesをホームディレクトリに適用   |
| `chezmoi update` | リポジトリの更新と適用を同時に実行 |

### Makefileコマンド

| コマンド               | 説明           |
|--------------------|----------------|
| `make init`        | chezmoiを初期化 |
| `make apply`       | dotfilesを適用  |
| `make diff`        | 差分を確認      |
| `make update-brew` | Brewfileを更新  |
| `make test`        | Batsテスト実行    |

---

## 参考リンク

- [chezmoi公式ドキュメント](https://www.chezmoi.io/)
- [chezmoiクイックスタート](https://www.chezmoi.io/quick-start/)
- [Go Template構文](https://pkg.go.dev/text/template)
