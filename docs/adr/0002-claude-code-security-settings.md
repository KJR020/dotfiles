# ADR-0002: Claude Code セキュリティ設定を dotfiles で管理する

Claude Code の権限設定（deny リスト、MCP 制御、bypass 防止）を chezmoi dotfiles で管理するための意思決定記録。

- Status: Accepted
- Date: 2026-03-07

## Context

Claude Code は AI エージェントがローカルのシェルコマンドを自由に実行できる環境である。以下の攻撃ベクトルが確認されている。

| # | 攻撃ベクトル | 出典 |
|---|-------------|------|
| 1 | 間接プロンプトインジェクション | CLAUDE.md、外部ドキュメント経由 |
| 2 | プロンプトサプライチェーン | 悪意ある CLAUDE.md、MCP ツール |
| 3 | MCP ツール悪用（Tool Poisoning） | OWASP MCP Top 10 |
| 4 | クレデンシャルリーク | .env、~/.ssh/ 等への無許可アクセス |
| 5 | Hooks-Based RCE | CVE-2025-59536 |
| 6 | MCP Consent Bypass | CVE-2026-21852 |
| 7 | APIキー窃取（ANTHROPIC_BASE_URL） | CVE-2025-59536 |

Claude Code にはセキュリティ設定のデフォルトが不十分であり、個人で deny リストを設計・管理する必要がある。設定を dotfiles で管理することで、版管理・再現性・テスト検証を実現する。

## Decision

### 1. settings.json に deny リストと MCP 制御を追加

`~/.claude/settings.json` に以下を設定する。

- `enableAllProjectMcpServers: false` — MCP の自動許可を無効化
- `permissions.deny` — 危険なコマンドパターンを deny リストで定義

deny リストのカテゴリ:

| カテゴリ | 代表パターン | 件数 |
|---------|-------------|------|
| ネットワーク通信 | `Bash(curl *)`, `Bash(wget *)` | 5 |
| 破壊的操作 | `Bash(rm -rf *)`, `Bash(git push --force *)` | 6 |
| 特権昇格 | `Bash(sudo *)`, `Bash(ssh *)` | 4 |
| macOS 固有 | `Bash(osascript *)`, `Bash(pbcopy*)` | 4 |
| 機密ファイル | `Bash(* .env*)`, `Read(**/.env*)` | 6 |
| dotfiles 保護 | `Edit(~/.zshrc)`, `Edit(~/.ssh/**)` | 6 |
| 開発者ツール認証 | `Read(~/.gnupg/**)`, `Edit(~/.npmrc)` | 12 |
| macOS クレデンシャル | `Read(~/Library/Keychains/**)` | 1 |

### 2. managed-settings.json で bypass 防止

`/Library/Application Support/ClaudeCode/managed-settings.json` に `disableBypassPermissionsMode: "disable"` を設定する。sudo が必要なため chezmoi の自動展開対象外とし、`setup.sh` に手動セットアップ手順を記載する。

### 3. 安全なクレデンシャル受け渡し

| 分類 | 管理方法 | 例 |
|------|---------|-----|
| 個人クレデンシャル | `op run` (1Password) | ANTHROPIC_API_KEY, GITHUB_TOKEN |
| リポジトリ/サービスキー | `dotenvx` (暗号化 .env) | STRIPE_SECRET_KEY, DATABASE_URL |

信頼の根は 1Password に一本化。`dotenvx` の復号キー (`DOTENV_PRIVATE_KEY`) も `op` で管理する。

## Consequences

### Positive

- deny → ask → allow の評価順により、deny に入れたパターンは allow で上書きされない
- chezmoi で版管理されるため、設定の再現性が保証される
- Bats テストで deny リストの退行を自動検知できる
- 平文の .env がディスク上に存在しない構成が実現可能

### Negative

- managed-settings.json は手動セットアップが必要（sudo）
- python3/node 経由のネットワーク通信は deny で完全には防げない（攻撃コスト差は数秒程度）
- deny パターンは既知のパターンに基づくため、定期的な見直しが必要

## Security Considerations

### 攻撃ベクトルと deny パターンの対応

| 攻撃ベクトル | 対策 | 限界 |
|-------------|------|------|
| 間接プロンプトインジェクション | `Bash(curl *)` 等のネットワーク deny | python3/node バイパス |
| MCP ツール悪用 | `enableAllProjectMcpServers: false` | 手動許可した MCP は制御外 |
| クレデンシャルリーク | `Read(**/.env*)`, `Bash(* ~/.ssh/*)` 等 | 環境変数経由の漏洩 |
| dotfiles 改竄 | `Edit(~/.zshrc)`, `Edit(~/.ssh/**)` 等 | — |
| Hooks-Based RCE (CVE-2025-59536) | パッチ適用 + clone 時の `.claude/` 検査 | deny では防御不可 |
| MCP Consent Bypass (CVE-2026-21852) | `enableAllProjectMcpServers: false` + パッチ | パッチ未適用環境で突破 |

### WebFetch の allow 判断

deny リストでネットワーク通信コマンド（curl, wget）をブロックしつつ `WebFetch` を allow している。WebFetch は隔離されたコンテキストウィンドウで実行されるため（公式: "Isolated context windows"）、プロンプトインジェクションのリスクは軽減される。

## Operational Rules

- **deny リスト変更時**: 変更理由を PR に記載し、`make test` で退行がないことを確認する
- **clone 時の `.claude/` 検査**: 新しいリポジトリを clone した際は `.claude/settings.json` の `hooks` と `env` セクションを手動確認する
- **パッチ適用**: Claude Code のアップデートを定期的に適用し、CVE 対策を最新に保つ

## Future Considerations

- `/sandbox` モードとの統合（OS レベルのファイルシステム・ネットワーク隔離）
- `ConfigChange` hooks による設定変更の監査・ブロック
- PreToolUse hooks による python3/node ネットワーク通信の検出
- Tool Pinning（MCP ツール description のハッシュ検証）

## Alternatives Considered

### A. user settings のみ（managed settings なし）

- メリット: 管理ファイルが 1 つでシンプル
- デメリット: `disableBypassPermissionsMode` が効かず、bypass 防止ができない

### B. chezmoi で managed settings も自動展開

- メリット: 全自動セットアップ
- デメリット: `chezmoi apply` のたびに sudo を要求され、ユーザー体験が悪い

### C. python3/node も全面 deny

- メリット: ネットワーク通信のバイパスを防げる
- デメリット: 開発作業に大きな支障が出る

現時点では、B/C の運用コストとリスクのバランスから、user settings + 手動 managed settings + ネットワークコマンドのみ deny を採用する。

## Related Files

- [settings.json](../../home/dot_claude/settings.json)
- [claude.bats](../../tests/claude.bats)
- [setup.sh](../../setup.sh)
