# Research & Design Decisions

---
**Purpose**: claude-code-security-dotfiles のディスカバリーフェーズで得た調査結果と設計判断を記録する。
---

## Summary
- **Feature**: `claude-code-security-dotfiles`
- **Discovery Scope**: Extension（既存の `home/dot_claude/settings.json` を拡張）
- **Key Findings**:
  - `disableBypassPermissionsMode` は managed settings 専用設定であり、`~/.claude/settings.json` では効果がない
  - Claude Code の permission 評価順序は deny → ask → allow（deny が常に最優先）
  - Bash パターンは glob ベース、Read/Edit パターンは gitignore 仕様に準拠

## Research Log

### Claude Code permissions.deny のフォーマット
- **Context**: settings.json の deny リスト構文を正確に把握する必要がある
- **Sources Consulted**: [Claude Code Permissions Docs](https://code.claude.com/docs/en/permissions)
- **Findings**:
  - `Bash(command *)` 形式でワイルドカード使用可能
  - `*` の前のスペースが重要: `Bash(ls *)` は `ls -la` にマッチするが `lsof` にはマッチしない
  - `Bash(ls*)` はスペースなしで両方にマッチ
  - Read/Edit は gitignore 仕様: `~/path`（ホームディレクトリ）, `//path`（絶対パス）, `/path`（プロジェクトルート相対）
- **Implications**: deny リストの各パターンは公式フォーマットに厳密に従う必要がある

### disableBypassPermissionsMode の制約
- **Context**: 要件 1.2 で bypass 防止を設定する必要がある
- **Sources Consulted**: [Claude Code Settings Docs](https://code.claude.com/docs/en/settings), [Claude Code Permissions Docs](https://code.claude.com/docs/en/permissions)
- **Findings**:
  - `disableBypassPermissionsMode` は "Managed-only settings" テーブルに記載
  - managed settings ファイルの場所: `/Library/Application Support/ClaudeCode/managed-settings.json`（macOS）
  - user settings (`~/.claude/settings.json`) に記述しても効果なし
  - 個人マシンではユーザーが admin 権限を持つため、managed settings ファイルの作成は可能
- **Implications**: chezmoi で管理するファイルが2つに分かれる: user settings + managed settings

### enableAllProjectMcpServers の適用レベル
- **Context**: MCP 自動許可の無効化がどのレベルで有効か確認
- **Sources Consulted**: [Claude Code Settings Docs](https://code.claude.com/docs/en/settings)
- **Findings**:
  - user scope (`~/.claude/settings.json`) で設定可能
  - project scope, local scope でも有効
  - デフォルト値は未設定（UI で個別承認）
- **Implications**: 要件 1.1 は `~/.claude/settings.json` で実現可能

### 既存の settings.json 構成
- **Context**: 既存設定との互換性を確認
- **Sources Consulted**: `home/dot_claude/settings.json`（現在の管理ファイル）
- **Findings**:
  - 現在の構成: `env`, `permissions.allow`, `enabledPlugins`
  - deny リストは未設定
  - `enableAllProjectMcpServers` は未設定
- **Implications**: 既存の allow リストを維持しつつ deny を追加する形で拡張

### Bats テストインフラ
- **Context**: テスト戦略の設計に必要
- **Sources Consulted**: `tests/zsh.bats`, `Makefile`
- **Findings**:
  - 既存テストは `tests/*.bats` パターンで `make test` から実行
  - テスト命名規則: `Given ... then ...` 形式
  - jq コマンドでの JSON 検証が標準的アプローチ
- **Implications**: `tests/claude.bats` を追加し、jq で JSON キーを検証するテストを書く

### CVE-2025-59536 / CVE-2026-21852: Claude Code 設定ファイル経由の RCE
- **Context**: 2026年2月に CheckPoint が公開した Claude Code の重大な脆弱性
- **Sources Consulted**: [CheckPoint Research](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/)
- **Findings**:
  - **Hooks-Based RCE**: `.claude/settings.json` の `hooks` 設定で任意シェルコマンドが確認なしに実行される
  - **MCP User Consent Bypass**: `enableAllProjectMcpServers` と `enabledMcpjsonServers` の連携で信頼ダイアログ前に MCP が発火
  - **ANTHROPIC_BASE_URL 窃取**: 環境変数で API エンドポイントをリダイレクトし、認証ヘッダーから API キーを傍受
  - すべてパッチ済みだが、clone したリポジトリの `.claude/` ディレクトリが攻撃面になる
- **Implications**: deny リストでは防御不可。パッチ適用 + リポジトリ clone 時の `.claude/` 検査を運用ルールとして ADR に記載すべき

### Claude Code 公式セキュリティページの sandbox 推奨
- **Context**: deny リスト単体の限界を把握する必要がある
- **Sources Consulted**: [Claude Code Security Docs](https://code.claude.com/docs/en/security)
- **Findings**:
  - 公式が「Sandboxed bash tool」を組み込み保護として紹介。`/sandbox` でファイルシステム・ネットワーク隔離を実現
  - 「Write access restriction」により Claude Code は起動ディレクトリのサブフォルダにのみ書き込み可能
  - `ConfigChange` hooks でセッション中の設定変更を監査・ブロック可能
  - WebFetch は「Isolated context windows」で隔離されたコンテキストで実行される
- **Implications**: deny リストは攻撃コスト引き上げの手段であり、sandbox との併用が公式推奨。Non-Goals として明記しつつ将来検討事項に記録

### MCP セキュリティ: OWASP MCP Top 10 と Tool Poisoning
- **Context**: MCP ツール悪用の最新の脅威モデルを把握する必要がある
- **Sources Consulted**: [MCP Playground - OWASP Top 10](https://mcpplaygroundonline.com/blog/mcp-security-tool-poisoning-owasp-top-10-mcp-scan), [Securing MCP Defense-First](https://christian-schneider.net/blog/securing-mcp-defense-first-architecture/)
- **Findings**:
  - Tool Poisoning が MCP 攻撃の #1。ツール description に隠し指示を埋め込み、AI が従うがユーザーには見えない
  - Defense-in-Depth の 4 層: sandbox、認可境界、ツール整合性検証、ランタイム監視
  - Tool Pinning: 初回スキャン時にツール description をハッシュ化し、変更を検出（rug pull 攻撃対策）
  - Per-tool approval: 書き込み・削除・送信を行うツールには個別承認を有効にすべき
- **Implications**: `enableAllProjectMcpServers: false` は最低限の対策。Tool Pinning や Per-tool approval は将来検討事項

### クレデンシャル受け渡し: op run + dotenvx の使い分け
- **Context**: deny リストでクレデンシャルファイルをブロックすると、正当な API キー利用も影響を受ける。「守る」と「使う」の両方を設計する必要がある
- **Sources Consulted**: [1Password - Securing MCP servers](https://1password.com/blog/securing-mcp-servers-with-1password-stop-credential-exposure-in-your-agent), [Claude Code Issue #23642 - op:// support](https://github.com/anthropics/claude-code/issues/23642), [Claude Code Issue #29910 - Built-in secrets management](https://github.com/anthropics/claude-code/issues/29910), [Knostic - Claude loads secrets without permission](https://www.knostic.ai/blog/claude-loads-secrets-without-permission)
- **Findings**:
  - `op run` はシークレットをメモリ上の環境変数としてのみ注入し、プロセス終了時に破棄する
  - `op://` 参照を `.env.op` に記載すれば、Claude Code が読んでも vault 参照しか見えない
  - Claude Code の settings.json `env` セクションでの `op://` ネイティブサポートは未実装（Issue #23642）
  - `dotenvx` は `.env` を暗号化してリポジトリにコミット可能。復号キー（`DOTENV_PRIVATE_KEY`）の管理が課題
  - Knostic の調査により、Claude Code は `.claudeignore` に書いても `.env` を自動読み込みする挙動がある
- **Design Decision**: 個人クレデンシャルは `op`、リポジトリ/サービスキーは `dotenvx` で管理。`dotenvx` の復号キーも `op` で管理し、信頼の根を 1Password に一本化
- **Implications**: 平文の `.env` がディスク上に存在しない構成が実現可能。deny ルールは二重防御として機能する

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| A. user settings のみ | `~/.claude/settings.json` に全設定 | 管理ファイルが1つ、シンプル | `disableBypassPermissionsMode` が効かない | 要件 1.2 を満たせない |
| B. user + managed settings | 2ファイルを chezmoi で管理 | 全要件を満たせる | managed settings は sudo 必要、chezmoi apply で権限問題 | 推奨 |
| C. user settings + 手動 managed | user settings のみ chezmoi 管理、managed は手動 | chezmoi の権限問題を回避 | managed settings の版管理・自動展開ができない | 妥協案 |

## Design Decisions

### Decision: managed settings の管理方針
- **Context**: `disableBypassPermissionsMode` は managed settings 専用
- **Alternatives Considered**:
  1. Option A: user settings のみ管理（bypass 防止を諦める）
  2. Option B: chezmoi の run_onchange スクリプトで sudo コピー
  3. Option C: managed settings は手動セットアップ + ADR に手順記載
- **Selected Approach**: Option C - managed settings は初回手動セットアップ
- **Rationale**: chezmoi の apply で毎回 sudo を要求するのはユーザー体験として不適切。managed settings は初回のみ設定すれば変更頻度が極めて低い
- **Trade-offs**: 自動展開は諦めるが、ADR とセットアップスクリプトで手順を明文化
- **Follow-up**: setup.sh に managed settings の初期配置を追加することを検討

### Decision: deny リストの粒度
- **Context**: python3/node が HTTP 通信可能なため、curl 禁止だけでは不十分
- **Alternatives Considered**:
  1. ネットワークコマンドのみ deny
  2. python3/node も含めて deny
  3. ネットワークコマンド deny + python3/node は allow パターンを制限
- **Selected Approach**: Option 1 + 注意喚起
- **Rationale**: python3/node を全面禁止すると開発作業に大きな支障。allow で `python3 --version` 等に限定する運用を ADR で推奨
- **Trade-offs**: python3/node 経由の情報漏洩リスクは残るが、攻撃コストは上がる
- **Follow-up**: allow リストのベストプラクティスを ADR の Security Considerations に記載

## Risks & Mitigations
- **managed settings の権限問題** — 初回セットアップスクリプトと ADR で手順を明文化
- **deny パターンのバイパス** — python3/node 経由の通信は完全には防げない。攻撃コスト引き上げの姿勢を維持
- **chezmoi apply での設定上書き** — 既存の allow リスト・env・plugins を必ず保持するよう静的 JSON を使用（テンプレート不要）
- **jq 依存** — テストで jq を使用するが、Homebrew で管理済みか確認が必要

### deny パターンの実機動作検証 (Task 1.2)
- **Context**: 設定した deny パターンが実際に Claude Code セッション内でブロックされるか検証
- **検証日**: 2026-03-07
- **検証結果**:
  - `Bash(curl *)`: `curl https://example.com` → ブロック確認 (Permission denied)
  - `Bash(* ~/.ssh/*)`: `cat ~/.ssh/id_rsa` → ブロック確認 (Permission denied)
  - `Edit(~/.zshrc)`: Edit ツールで `~/.zshrc` を編集 → ブロック確認 ("File is in a directory that is denied")
  - `Read(~/.zshrc)` は deny に含まれていないため読み取り可能（意図通り）
- **構文の確認**: `Bash(curl *)` 形式（スペース + `*`）で正しくマッチ。`Bash(curl:*)` のコロン形式は不要
- **Implications**: deny パターンは期待通りに機能している

## References
- [Claude Code Permissions Docs](https://code.claude.com/docs/en/permissions) — deny/allow/ask の公式フォーマット
- [Claude Code Settings Docs](https://code.claude.com/docs/en/settings) — managed settings の場所と優先順位
- [Claude Code Security Docs](https://code.claude.com/docs/en/security) — sandbox、hooks、MCP セキュリティの公式推奨
- [CheckPoint CVE-2025-59536 / CVE-2026-21852](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) — Hooks/MCP/環境変数経由の RCE と API キー窃取
- [MCP Security - OWASP MCP Top 10](https://mcpplaygroundonline.com/blog/mcp-security-tool-poisoning-owasp-top-10-mcp-scan) — Tool Poisoning 対策と Defense-in-Depth
- [Securing MCP Defense-First Architecture](https://christian-schneider.net/blog/securing-mcp-defense-first-architecture/) — 4 層防御モデル
- [Zenn 記事: Claude Code + MCP セキュリティ事例](https://zenn.dev/ytksato/articles/057dc7c981d304) — 攻撃ベクトルの詳細
- [1Password - Securing MCP servers](https://1password.com/blog/securing-mcp-servers-with-1password-stop-credential-exposure-in-your-agent) — op run による MCP サーバーのクレデンシャル保護
- [Claude Code Issue #23642](https://github.com/anthropics/claude-code/issues/23642) — settings.json env での op:// 参照サポート要望
- [Knostic - Claude loads secrets without permission](https://www.knostic.ai/blog/claude-loads-secrets-without-permission) — Claude Code の .env 自動読み込み挙動
