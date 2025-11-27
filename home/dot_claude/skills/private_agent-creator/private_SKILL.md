---
name: agent-creator
description: Claude Agent SDKを使用したSubagentの設計・作成ガイド。新しいエージェントを作成する場合、カスタムサブエージェントを設定する場合、エージェントのシステムプロンプトを最適化する場合に使用。
---

# Agent Creator - Claude Agent SDK

Claude Agent SDKを使用して、専門化されたSubagentを設計・作成するためのガイドです。

## When to Use This Skill

- 新しいSubagentを作成したい
- 既存のエージェントをカスタマイズしたい
- エージェントのシステムプロンプトを最適化したい
- 複数のエージェントを連携させたい
- エージェントのツールアクセスを制御したい

## Core Concepts

### Subagentとは

Subagentは、独立した専門化されたAIアシスタントです：

- **コンテキスト分離**: 各Subagentが独立して動作し、メイン会話を汚さない
- **専門化**: 特定ドメイン向けの詳細な指示で微調整可能
- **ツール制御**: 各エージェントに異なる権限レベルを割り当て

### 組み込みSubagents

| Subagent | 用途 | 特徴 |
|----------|------|------|
| **General-purpose** | 複雑な多段階タスク | ファイル修正と探索の両方が可能 |
| **Explore** | コード検索・分析 | 読み取り専用で高速 |
| **Plan** | 計画・設計フェーズ | Plan Modeで動作 |

## Directory Structure

```
.claude/agents/           # プロジェクトスコープ（Git共有）
~/.claude/agents/         # ユーザースコープ（個人用）
```

## Agent Configuration Schema

```json
{
  "name": "agent-name",
  "description": "エージェントの説明（いつ使用するかを含む）",
  "model": "claude-opus-4-1",
  "system_prompt": "詳細な指示...",
  "tools": ["Tool1", "Tool2"],
  "max_iterations": 10
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | 小文字、ハイフン、数字のみ（最大64文字） |
| `description` | string | 何をするか＋いつ使用するか |
| `system_prompt` | string | エージェントへの詳細な指示 |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | 親から継承 | 使用するClaudeモデル |
| `tools` | array | 全ツール | 許可するツール一覧 |
| `max_iterations` | int | 10 | 最大イテレーション数 |

## Available Tools

```yaml
tools:
  - Bash              # シェルコマンド実行
  - Glob              # ファイルパターンマッチング
  - Grep              # テキスト検索
  - Read              # ファイル読み取り
  - Write             # ファイル書き込み
  - Edit              # ファイル編集
  - WebFetch          # Webコンテンツ取得
  - WebSearch         # Web検索
  - Task              # サブタスク実行
  - TodoWrite         # タスク管理
```

## Instructions

### Step 1: エージェントの目的を定義

1. エージェントが解決する問題を明確化
2. 対象ドメイン・技術スタックを特定
3. 期待される入力と出力を定義

### Step 2: システムプロンプトを設計

効果的なシステムプロンプトの構成：

```markdown
## Role Definition
あなたは[専門分野]の専門家です。

## Core Responsibilities
1. [責任1]
2. [責任2]
3. [責任3]

## Approach
- [アプローチ1]
- [アプローチ2]

## Output Format
[期待される出力形式]

## Constraints
- [制約1]
- [制約2]
```

### Step 3: ツールアクセスを設定

**読み取り専用エージェント**:
```json
"tools": ["Glob", "Grep", "Read"]
```

**フル機能エージェント**:
```json
"tools": ["Bash", "Glob", "Grep", "Read", "Write", "Edit"]
```

**Web調査エージェント**:
```json
"tools": ["WebFetch", "WebSearch", "Read"]
```

### Step 4: 設定ファイルを作成

```bash
# プロジェクトスコープ
mkdir -p .claude/agents
touch .claude/agents/my-agent.json

# ユーザースコープ
mkdir -p ~/.claude/agents
touch ~/.claude/agents/my-agent.json
```

## Examples

### Example 1: Code Review Agent

```json
{
  "name": "code-reviewer",
  "description": "TypeScript/JavaScriptコードの品質レビュー。コードレビュー、品質チェック、ベストプラクティス確認時に使用。",
  "model": "claude-sonnet-4-5-20250929",
  "system_prompt": "あなたは経験豊富なシニアエンジニアです。\n\n## レビュー観点\n1. **セキュリティ**: インジェクション、XSS、認証/認可の問題\n2. **パフォーマンス**: N+1クエリ、メモリリーク、不要な再レンダリング\n3. **可読性**: 命名規則、関数の長さ、コメントの適切さ\n4. **型安全性**: any型の使用、型ガードの欠如\n\n## 出力形式\n- 問題の重要度: Critical / Warning / Info\n- ファイル:行番号\n- 問題の説明\n- 修正案",
  "tools": ["Glob", "Grep", "Read"],
  "max_iterations": 15
}
```

### Example 2: Test Generator Agent

```json
{
  "name": "test-generator",
  "description": "包括的なテストケースを生成。テスト作成、テストカバレッジ改善、TDD実践時に使用。",
  "model": "claude-sonnet-4-5-20250929",
  "system_prompt": "あなたはテスト設計の専門家です。\n\n## テスト設計手法\n1. 同値分割法\n2. 境界値分析\n3. デシジョンテーブル\n4. 状態遷移テスト\n\n## 出力要件\n- 100%分岐カバレッジを目指す\n- エッジケースを網羅\n- モック/スタブを適切に使用\n- AAA(Arrange-Act-Assert)パターンに従う\n\n## 使用フレームワーク\nプロジェクトの既存テストに合わせる（Jest, Vitest, pytest等）",
  "tools": ["Glob", "Grep", "Read", "Write", "Edit"],
  "max_iterations": 20
}
```

### Example 3: Documentation Agent

```json
{
  "name": "doc-generator",
  "description": "APIドキュメント、README、技術文書を生成。ドキュメント作成、API仕様書生成時に使用。",
  "model": "claude-sonnet-4-5-20250929",
  "system_prompt": "あなたはテクニカルライターです。\n\n## ドキュメント種類\n1. **README**: プロジェクト概要、セットアップ、使用方法\n2. **API Docs**: エンドポイント仕様、リクエスト/レスポンス例\n3. **Architecture**: システム構成、データフロー図\n\n## 品質基準\n- 簡潔で明確な文章\n- 実行可能なコード例を含む\n- 最新のコードベースと一致\n- 日本語で記述（コード例は英語）",
  "tools": ["Glob", "Grep", "Read", "Write"],
  "max_iterations": 10
}
```

### Example 4: Security Audit Agent

```json
{
  "name": "security-auditor",
  "description": "セキュリティ脆弱性を検出・報告。セキュリティ監査、脆弱性スキャン、OWASP Top 10チェック時に使用。",
  "model": "claude-opus-4-1",
  "system_prompt": "あなたはセキュリティ専門家です。\n\n## 検出対象\n1. SQLインジェクション\n2. XSS（クロスサイトスクリプティング）\n3. CSRF\n4. 認証/認可の欠陥\n5. 機密情報の露出\n6. 安全でない依存関係\n\n## レポート形式\n- 脆弱性の種類\n- 重要度: Critical / High / Medium / Low\n- 影響範囲\n- 再現手順\n- 修正推奨事項",
  "tools": ["Glob", "Grep", "Read"],
  "max_iterations": 25
}
```

## Best Practices

### 1. 単一責任の原則

```
✅ GOOD: 1つのエージェント = 1つの専門分野
- code-reviewer: コードレビュー専門
- test-generator: テスト生成専門
- doc-generator: ドキュメント生成専門

❌ BAD: 複数の責任を持つエージェント
- developer-helper: 何でもやる（曖昧）
```

### 2. 詳細なシステムプロンプト

```
✅ GOOD:
"あなたはReact/TypeScriptの専門家です。
コンポーネントのパフォーマンス最適化を行います。
具体的には：
1. useMemo/useCallbackの適切な使用
2. React.memoによる再レンダリング防止
3. 仮想化による大量リストの最適化"

❌ BAD:
"コードを改善してください"
```

### 3. 適切なツール制限

```
✅ GOOD: 必要最小限のツール
- 読み取り専用分析: ["Glob", "Grep", "Read"]
- ファイル生成: ["Glob", "Read", "Write"]

❌ BAD: 不必要に広い権限
- 全ツール許可（セキュリティリスク）
```

### 4. 明確な出力形式

システムプロンプトで期待される出力形式を指定：

```markdown
## Output Format
```json
{
  "findings": [
    {
      "severity": "high",
      "file": "src/auth.ts",
      "line": 42,
      "issue": "...",
      "recommendation": "..."
    }
  ]
}
```
```

## Common Patterns

### Pattern 1: Analysis Pipeline

```
[Explore Agent] → コード検索
       ↓
[Analyze Agent] → 問題特定
       ↓
[Report Agent] → レポート生成
```

### Pattern 2: Generate-Review Cycle

```
[Generator Agent] → 初期生成
       ↓
[Reviewer Agent] → レビュー・改善提案
       ↓
[Generator Agent] → 修正版生成
```

### Pattern 3: Research-Implement

```
[Research Agent] → 調査・情報収集
       ↓
[Plan Agent] → 計画策定
       ↓
[Implement Agent] → 実装
```

## Troubleshooting

**Issue**: エージェントが起動しない
**Solution**:
- 設定ファイルのJSON構文を確認
- `name`が小文字・ハイフン・数字のみか確認
- ファイルパスが正しいか確認

**Issue**: エージェントが期待通り動作しない
**Solution**:
- システムプロンプトをより具体的に
- 例示を追加
- 出力形式を明確に指定

**Issue**: ツールが使用できない
**Solution**:
- `tools`配列にツール名が正確に記載されているか確認
- ツール名の大文字小文字を確認

## AI Assistant Instructions

このスキルが呼び出された場合：

1. **目的の確認**: ユーザーが作成したいエージェントの目的を明確化
2. **要件の収集**: 対象ドメイン、必要なツール、出力形式を確認
3. **設計の提案**: システムプロンプトのドラフトを作成
4. **設定ファイル生成**: 完全なJSON設定ファイルを生成
5. **テスト提案**: エージェントのテスト方法を提案

Always:
- 単一責任の原則に従う
- ツールアクセスは最小限に
- システムプロンプトは具体的に
- 日本語で説明、コード例は英語

Never:
- 曖昧な説明文を書かない
- 不必要なツールを許可しない
- テストなしでデプロイを推奨しない

## Additional Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Agent SDK Guide](https://docs.anthropic.com/en/docs/claude-code/agent-sdk)
