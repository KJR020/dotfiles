# Requirements Document

## Introduction

Claude Code / MCP環境では、AIエージェントがローカル環境のシェルコマンドを実行できるため、「AIに渡した権限 = 攻撃面」となる。本仕様では、`~/.claude/settings.json` にセキュリティ設定（deny リスト、MCP制御、バイパス防止）を追加し、chezmoi dotfiles で版管理・展開する。既存の `home/dot_claude/settings.json` を拡張し、ADRで意思決定を記録する。

### 攻撃ベクトル（背景）

1. **間接プロンプトインジェクション** - Webページやコードコメントに隠し指示を埋め込む
2. **プロンプトサプライチェーン攻撃** - 共有されたCLAUDE.md/MCP設定に悪意あるコマンドが混入
3. **MCPツール悪用 (Tool Poisoning)** - 悪意あるMCPサーバーによるOSコマンド実行・データ送信
4. **クレデンシャルリーク** - .envやログからのAPIキー漏洩
5. **Hooks-Based RCE (CVE-2025-59536)** - `.claude/settings.json`のhooks設定で任意シェルコマンドを確認なしに実行。cloneしたリポジトリの`.claude/`ディレクトリが攻撃面になる
6. **MCP User Consent Bypass (CVE-2026-21852)** - `enableAllProjectMcpServers`と`enabledMcpjsonServers`の連携により、信頼ダイアログ表示前にMCPサーバーが実行される
7. **APIキー窃取 (ANTHROPIC_BASE_URL)** - 環境変数`ANTHROPIC_BASE_URL`でAPIエンドポイントを攻撃者サーバーにリダイレクトし、認証ヘッダーからAPIキーを傍受する

### セキュリティ原則

- **最小権限**: 必要最小限のコマンドのみ許可
- **攻撃コストの引き上げ**: 完璧な防御ではなく、攻撃の実行コストを上げることに焦点
- **外部入力は信用しない**: Web、GitHub、Slack、MCP、CLAUDE.md すべて検証対象

## Requirements

### Requirement 1: セキュリティ基盤設定

**Objective:** As a 開発者, I want Claude Codeのグローバル設定でMCP自動許可とパーミッションバイパスを無効化したい, so that 未承認のMCPサーバーや全権限バイパスによる攻撃面を縮小できる

#### Acceptance Criteria

1. The settings.json shall `enableAllProjectMcpServers` を `false` に設定する
2. The managed-settings.json shall macOS の `/Library/Application Support/ClaudeCode/managed-settings.json` に `disableBypassPermissionsMode` を `"disable"` に設定する（managed settings 専用設定のため）
3. When chezmoi apply を実行した場合, the settings.json shall 既存の `env` および `enabledPlugins` 設定を保持したまま、セキュリティ設定を追加する

### Requirement 2: 危険コマンドのdenyリスト

**Objective:** As a 開発者, I want AIエージェントが実行できる危険なコマンドをdenyリストで制限したい, so that ネットワーク送信・破壊的操作・機密ファイルアクセスによる情報漏洩を防止できる

#### Acceptance Criteria

1. The settings.json shall ネットワーク通信コマンド（`curl`, `wget`, `nc`, `ncat`, `telnet`）をdenyリストに含める
2. The settings.json shall 破壊的操作コマンド（`rm -rf`, `rmdir`, `shred`, `git push --force`, `git reset --hard`）をdenyリストに含める
3. The settings.json shall 特権昇格・リモートアクセスコマンド（`sudo`, `su`, `ssh`, `scp`）をdenyリストに含める
4. The settings.json shall macOS固有の脅威コマンド（`osascript`, `security`, `pbcopy`, `pbpaste`）をdenyリストに含める
5. The settings.json shall 機密ファイルパスへのアクセス（`~/.ssh/*`, `~/.aws/*`, `*.env*`）をBash denyおよびRead denyリストに含める（パス付き参照もカバーする）
6. The settings.json shall 開発者ツールのクレデンシャルファイル（`~/.gnupg/*`, `~/.docker/config.json`, `~/.npmrc`, `~/.pypirc`, `~/.git-credentials`, `~/.config/gh/*`）をRead denyおよびEdit denyリストに含める
7. The settings.json shall macOS固有のクレデンシャルストア（`~/Library/Keychains/*`）をRead denyリストに含める

### Requirement 3: dotfiles保護ルール

**Objective:** As a 開発者, I want AIエージェントがdotfilesの重要ファイルを変更できないようにdenyルールを設定したい, so that 永続バックドアの埋め込みやシェル設定の改ざんを防止できる

#### Acceptance Criteria

1. The settings.json shall `~/.zshrc`, `~/.bashrc` への書き込みコマンドをdenyリストに含める
2. The settings.json shall `~/.gitconfig` への書き込みコマンドをdenyリストに含める
3. The settings.json shall `~/.ssh/*`, `~/.aws/*` への書き込みコマンドをdenyリストに含める
4. The settings.json shall `~/.zprofile` への書き込みコマンドをdenyリストに含める

### Requirement 4: chezmoi dotfiles管理

**Objective:** As a 開発者, I want settings.jsonをchezmoi dotfilesで管理し、複数マシン間で一貫したセキュリティ設定を展開したい, so that 設定の版管理・再現性・差分検知が可能になる

#### Acceptance Criteria

1. The dotfiles shall `home/dot_claude/settings.json` にセキュリティ設定を含むsettings.jsonを配置する
2. When `chezmoi apply` を実行した場合, the dotfiles shall `~/.claude/settings.json` にファイルを展開する
3. When `chezmoi diff` を実行した場合, the dotfiles shall セキュリティ設定の差分を検知・表示する
4. The dotfiles shall 既存の `home/dot_claude/` ディレクトリ構成（prompts/, skills/）を維持する

### Requirement 5: 設定検証テスト

**Objective:** As a 開発者, I want settings.jsonのセキュリティ設定が正しく適用されているかテストで検証したい, so that 設定ミスや退行を自動検知できる

#### Acceptance Criteria

1. The テスト shall settings.jsonが有効なJSON形式であることを検証する
2. The テスト shall `enableAllProjectMcpServers` が `false` であることを検証する
3. The テスト shall managed-settings.json が存在し `disableBypassPermissionsMode` が `"disable"` であることを検証する
4. The テスト shall denyリストに必須のコマンドパターンが含まれていることを検証する
5. When `make test` を実行した場合, the テスト shall 既存のBatsテストと統合して実行できる

### Requirement 6: ADR文書作成

**Objective:** As a 開発者, I want Claude Codeセキュリティ設定をdotfilesで管理する意思決定をADRとして記録したい, so that 設計判断の背景・理由・影響を将来参照できる

#### Acceptance Criteria

1. The ADR shall `docs/adr/0002-claude-code-security-settings.md` に作成する
2. The ADR shall Context（AIエージェント環境のセキュリティリスク）を記述する
3. The ADR shall Decision（settings.jsonでのセキュリティ設定とdotfiles管理）を記述する
4. The ADR shall Consequences（Positive/Negative）を記述する
5. The ADR shall Security Considerations（攻撃ベクトルと対策の対応関係）を記述する
6. The ADR shall 既存のADRフォーマット（ADR-0001）と一貫した形式で記述する

### Requirement 7: 安全なクレデンシャル受け渡し

**Objective:** As a 開発者, I want Claude Codeに平文のAPIキーを渡さずに、必要な認証情報を安全に利用したい, so that denyリストでクレデンシャルファイルをブロックしつつ正当な開発作業を妨げない

#### 背景

denyリストで`.env`や`~/.config/gh/`へのアクセスをブロックすると、正当にAPIキーが必要な処理（MCP認証、外部API呼び出し等）も影響を受ける。「守る」と「使う」の両方を設計する必要がある。

#### クレデンシャルの分類

| 分類 | 管理ツール | 例 | 理由 |
|------|-----------|-----|------|
| 個人クレデンシャル | `op` (1Password) | Anthropic API Key, GitHub PAT, Slack Token | 個人に紐づく。マシンを変えても同じ Vault から取得 |
| リポジトリ/サービスキー | `dotenvx` | Stripe Secret Key, DB接続文字列, 外部API Key | プロジェクトに紐づく。暗号化してリポジトリにコミット可能 |

#### Acceptance Criteria

1. The dotfiles shall 個人クレデンシャルの受け渡しに `op run` を使用し、1Password Vault から環境変数としてシークレットを注入する手順をドキュメント化する
2. The dotfiles shall `.env.op`（`op://` 参照のみを含むファイル）のテンプレートを提供する。平文のシークレットを含まないこと
3. The dotfiles shall リポジトリ/サービスキーの受け渡しに `dotenvx` を使用し、暗号化された `.env` でプロジェクト固有のシークレットを管理する手順をドキュメント化する
4. The dotfiles shall `dotenvx` の復号キー（`DOTENV_PRIVATE_KEY`）を `op` で管理し、信頼の根を 1Password に一本化する手順を記載する
5. The ADR shall クレデンシャル受け渡し方式の選択（`op` + `dotenvx` の使い分け vs 平文`.env`）の判断根拠を記述する
