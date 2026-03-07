# Implementation Plan

- [x] 1. settings.json にセキュリティ設定を追加する
- [x] 1.1 deny リストと MCP 制御を既存の settings.json に追加する
  - 既存の `home/dot_claude/settings.json` を開き、`enableAllProjectMcpServers: false` をトップレベルに追加する
  - `permissions.deny` 配列を追加し、ネットワーク通信コマンド（curl, wget, nc, ncat, telnet）の Bash deny パターンを設定する
  - 破壊的操作コマンド（rm -rf, rmdir, shred, git push --force, git push -f, git reset --hard）の Bash deny パターンを設定する
  - 特権昇格コマンド（sudo, su, ssh, scp）の Bash deny パターンを設定する
  - macOS 固有コマンド（osascript, security, pbcopy, pbpaste）の Bash deny パターンを設定する
  - 機密ファイルアクセスの Bash deny パターン（.env, ~/.ssh/*, ~/.aws/*）をカレントディレクトリ参照とパス付き参照の両方で設定する
  - 機密ファイルの Read deny パターン（~/.env*, **/.env*）を設定する
  - dotfiles 保護の Edit deny パターン（~/.zshrc, ~/.bashrc, ~/.zprofile, ~/.gitconfig, ~/.ssh/**, ~/.aws/**）を設定する
  - 開発者ツールクレデンシャルの Read/Edit deny パターン（~/.gnupg/**, ~/.docker/config.json, ~/.npmrc, ~/.pypirc, ~/.git-credentials, ~/.config/gh/**）を設定する
  - macOS クレデンシャルストアの Read deny パターン（~/Library/Keychains/**）を設定する
  - 既存の env, permissions.allow, enabledPlugins 設定が保持されていることを確認する
  - _Requirements: 1.1, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 4.1, 4.4_

- [x] 1.2 deny パターンの実機動作検証
  - Claude Code セッションで `curl https://example.com` を実行し、deny によりブロックされることを確認する
  - `cat ~/.ssh/id_rsa` 等の機密ファイルアクセスがブロックされることを確認する
  - `Bash(curl *)` と `Bash(curl:*)` のマッチ挙動の差異を確認し、正しい構文を採用する
  - Edit ツールで `~/.zshrc` への書き込みがブロックされることを確認する
  - 検証結果を research.md に記録する
  - _Requirements: 2.1-2.7, 3.1-3.4_

- [x] 2. (P) managed-settings.json のセットアップ手順を setup.sh に追加する
  - setup.sh に managed-settings.json を `/Library/Application Support/ClaudeCode/` に配置するコマンドを追加する
  - managed-settings.json の内容として `disableBypassPermissionsMode: "disable"` を設定する
  - ディレクトリが存在しない場合の作成処理を含める
  - sudo が必要な旨のコメントを追加する
  - 既に managed-settings.json が存在する場合はスキップする条件分岐を追加する
  - _Requirements: 1.2_

- [x] 3. (P) ADR-0002 を作成する
  - `docs/adr/0002-claude-code-security-settings.md` を ADR-0001 と同一フォーマットで作成する
  - Context セクションに AI エージェント環境の 7 つの攻撃ベクトル（既存4件 + CVE-2025-59536/CVE-2026-21852 由来3件）を記述する
  - Decision セクションに settings.json の deny リスト、MCP 制御、managed settings による bypass 防止を記述する
  - Consequences セクションに Positive（攻撃面縮小、版管理、テスト検証）と Negative（managed settings の手動セットアップ、python3/node バイパスリスク）を記述する
  - Security Considerations セクションに攻撃ベクトルと deny パターンの対応表を記述する
  - Operational Rules セクションに deny リスト変更時のレビュー手順、clone 時の `.claude/` ディレクトリ検査手順、WebFetch allow の技術的根拠を記述する
  - Future Considerations セクションに `/sandbox` モードとの統合、`ConfigChange` hooks、PreToolUse hooks による python3/node 通信検出を記述する
  - Related Files セクションに settings.json, claude.bats, managed-settings.json へのリンクを含める
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 4. Bats テストを作成する
- [x] 4.1 settings.json の検証テストを作成する
  - `tests/claude.bats` を作成し、jq の存在確認（未インストール時は skip）を前提条件として設定する
  - settings.json が有効な JSON 形式であることを検証するテストを追加する
  - `enableAllProjectMcpServers` が `false` であることを検証するテストを追加する
  - deny リストにネットワーク通信コマンド（curl）が含まれていることを検証するテストを追加する
  - deny リストに破壊的操作コマンド（rm -rf）が含まれていることを検証するテストを追加する
  - deny リストに dotfiles 保護パターン（Edit ~/.zshrc）が含まれていることを検証するテストを追加する
  - テスト命名規則は既存の `Given ... then ...` パターンに従う
  - _Requirements: 5.1, 5.2, 5.4, 5.5_

- [x] 4.2 managed-settings.json の検証テストを作成する
  - `tests/claude.bats` に managed-settings.json の存在確認テストを追加する
  - managed-settings.json が有効な JSON 形式であることを検証するテストを追加する
  - `disableBypassPermissionsMode` が `"disable"` であることを検証するテストを追加する
  - managed-settings.json が存在しない場合は skip して警告メッセージを出力する
  - _Requirements: 5.3_

- [x] 5. (P) クレデンシャル受け渡しのドキュメントとテンプレートを作成する
  - `.env.op` テンプレートファイルを作成し、`op://` 参照の記述例（ANTHROPIC_API_KEY, GITHUB_TOKEN 等）を含める
  - `op run --env-file=.env.op -- claude` の起動手順をドキュメント化する
  - `dotenvx` によるリポジトリ/サービスキーの暗号化・復号手順をドキュメント化する
  - `DOTENV_PRIVATE_KEY` を `op` で管理する手順を記載する
  - ADR-0002 に `op`（個人） + `dotenvx`（リポジトリ）の使い分け判断根拠を記述する
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 6. 統合検証を実行する
  - `chezmoi apply` を実行し、`~/.claude/settings.json` が正しく展開されることを確認する
  - `chezmoi diff` を実行し、展開後に差分がないことを確認する
  - `make test` を実行し、既存テスト（zsh.bats）と新規テスト（claude.bats）が全て通ることを確認する
  - 既存の `home/dot_claude/` ディレクトリ構成（prompts/, skills/）が維持されていることを確認する
  - _Requirements: 4.2, 4.3, 4.4, 5.5_
