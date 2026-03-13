# Claude Settings and Configuration

このファイルはClaude AI との対話に関する設定とガイドラインを記載します。

## プロジェクト設定

### 基本設定
- **言語**: 日本語
- **コーディングスタイル**: Google Style Guide準拠
- **ドキュメント形式**: Markdown

### 開発環境
- **OS**: macOS
- **Shell**: zsh
- **エディタ**: VS Code
- **パッケージマネージャ**: Homebrew

## 対話ルール

### ユーザー確認
- 選択肢がある場合や方針を決定する必要がある場合は、`AskUserQuestion` ツールを使用してユーザーに確認する
- 勝手に判断せず、ユーザーの意思決定を尊重する

### フィードバック（ユーザーの成長を促す）
- ユーザーの指示が曖昧・矛盾している場合は、そのまま進めず具体的に何が不明確かを指摘して確認する
- 用語の誤用や技術的に不正確な発言があれば、正しい概念と合わせて丁寧に訂正する
- 設定やファイル構成にベストプラクティスからの逸脱があれば、理由とともに指摘する
- 単に作業を代行するのではなく、判断の背景や考え方を共有してユーザーの理解を深める


<claude-mem-context>
# Recent Activity

### Feb 8, 2026

| ID | Time | T | Title | Read |
|----|------|---|-------|------|
| #41 | 11:28 AM | ✅ | Created Symlink for Skills Directory | ~320 |
| #40 | 11:27 AM | ✅ | Created Symlink for CLAUDE.md Configuration | ~282 |
| #7 | 11:26 AM | 🔵 | Current Claude Configuration File Contents | ~318 |

### Feb 18, 2026

| ID | Time | T | Title | Read |
|----|------|---|-------|------|
| #391 | 10:22 PM | 🔵 | Claude Code MCP Config Uses ~/.claude.json Not claude_code_config.json | ~336 |
| #390 | 10:21 PM | 🔵 | MCP Servers Configured in claude_code_config.json Not settings.json | ~278 |
| #389 | " | 🔵 | claude_code_config.json Exists as Separate Config File | ~189 |
| #387 | 10:20 PM | 🔵 | Current Claude Settings.json Contents Before Exa Addition | ~234 |
| #386 | " | ✅ | Exa MCP Server Added to Claude Settings | ~204 |
</claude-mem-context>