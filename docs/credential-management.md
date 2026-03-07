# Claude Code クレデンシャル管理ガイド

Claude Code の deny リストで `.env` ファイルへのアクセスをブロックしているため、API キーなどのシークレットは平文ファイル以外の方法で安全に渡す必要がある。

## 使い分け

| 分類 | 管理方法 | 特徴 | 例 |
|------|---------|------|-----|
| 個人クレデンシャル | `op run` (1Password) | Vault から環境変数として注入。プロセス終了時に破棄 | ANTHROPIC_API_KEY, GITHUB_TOKEN |
| リポジトリ/サービスキー | `dotenvx` | 暗号化 .env をリポジトリにコミット。復号キーは op で管理 | STRIPE_SECRET_KEY, DATABASE_URL |

## 信頼チェーン

```
1Password Vault (信頼の根)
├── 個人キー
│   └── op run --env-file=.env.op -- claude
│       └── $ANTHROPIC_API_KEY, $GITHUB_TOKEN (メモリ上のみ)
│
└── DOTENV_PRIVATE_KEY
    └── dotenvx run -- <command>
        └── $STRIPE_SECRET_KEY, $DATABASE_URL (メモリ上のみ)
```

## 1. op run による個人クレデンシャル管理

### .env.op テンプレート

プロジェクトルートに `.env.op` を作成し、`op://` 参照を記述する。

```bash
# 個人クレデンシャル（op:// 参照のみ、平文なし）
ANTHROPIC_API_KEY=op://Development/Anthropic/credential
GITHUB_TOKEN=op://Development/GitHub-PAT/credential
```

### 起動方法

```bash
# 1Password から環境変数を注入して Claude Code を起動
op run --env-file=.env.op -- claude
```

- `op run` はシークレットをメモリ上の環境変数としてのみ注入
- プロセス終了時にシークレットは破棄される
- `.env.op` にはプレーンテキストのシークレットが含まれないため、リポジトリにコミット可能

## 2. dotenvx によるリポジトリキー管理

### 初期セットアップ

```bash
# 1. .env を作成
echo "STRIPE_SECRET_KEY=sk_live_xxx" > .env

# 2. 暗号化
dotenvx encrypt

# 3. .env (平文) を gitignore に追加済みであることを確認
echo ".env" >> .gitignore

# 4. .env.encrypted をリポジトリにコミット
git add .env.encrypted .env.keys
git commit -m "Add encrypted environment variables"
```

### 復号キーを 1Password で管理

```bash
# DOTENV_PRIVATE_KEY を 1Password に保存
op item create \
  --category=password \
  --title="ProjectX DOTENV_PRIVATE_KEY" \
  --password="$(cat .env.keys | grep DOTENV_PRIVATE_KEY | cut -d= -f2)"
```

### 実行時

```bash
# op で復号キーを注入し、dotenvx で .env を復号して Claude Code を起動
DOTENV_PRIVATE_KEY=$(op read "op://Development/ProjectX DOTENV_PRIVATE_KEY/password") \
  dotenvx run -- claude
```

または、`.env.op` に `DOTENV_PRIVATE_KEY` の op 参照を含めて一括で:

```bash
# .env.op に追記
# DOTENV_PRIVATE_KEY=op://Development/ProjectX-DOTENV_PRIVATE_KEY/password

op run --env-file=.env.op -- dotenvx run -- claude
```

## deny ルールとの関係

- `Read(**/.env*)` で平文 `.env` へのアクセスをブロック（既存 deny）
- `op://` 参照の `.env.op` は平文シークレットを含まないため deny の影響なし
- `.env.encrypted` は暗号化済みのため読まれても安全
- 仮にプロンプトインジェクションで `echo $SECRET` → 外部送信を試みても、`Bash(curl *)` 等のネットワーク deny でブロック

## 関連ドキュメント

- [ADR-0002](adr/0002-claude-code-security-settings.md)
- [settings.json](../home/dot_claude/settings.json)
