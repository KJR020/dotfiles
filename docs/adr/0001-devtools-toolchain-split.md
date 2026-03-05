# ADR-0001: devtoolsでのツール管理分離

dotfilesで開発ツール（Homebrew / Volta / uv）を責務分離して管理するための意思決定記録。

- Status: Accepted
- Date: 2026-03-05

## Context

このリポジトリでは、これまでHomebrew中心でツール管理していた。
一方で、次の課題があった。

- Node.js製グローバルCLI（例: `agent-browser`）の管理責務が曖昧
- Python製CLIとNode.js製CLIが同じ管理軸で混在
- 「実際に入っているツール」と「dotfiles上の定義」のズレが起きやすい

再現性の高い開発環境を維持するため、管理境界を明確化する必要がある。

## Decision

開発ツール管理は `devtools/` に集約し、以下の責務分離を採用する。

- Homebrew: OS/システムパッケージ、GUIアプリ、周辺ツール
- Volta: Node.js製グローバルCLI
- uv tool: Python製グローバルCLI

管理ファイル（Source of Truth）は次の4つ。

- `devtools/brew/profile1.Brewfile`
- `devtools/brew/profile2.Brewfile`
- `devtools/volta/packages.txt`
- `devtools/uv/tools.txt`

同期コマンドは個別に実行する（`devtools-sync` は作らない）。

- `make brew-sync BREW_PROFILE=profile1`
- `make brew-dump BREW_PROFILE=profile1`
- `make volta-sync`
- `make uv-sync`

## Consequences

### Positive

- ツール種別ごとに管理責務が明確になる
- `agent-browser` のようなNode.js CLIをVoltaで一貫運用できる
- Python CLIをuv toolで分離でき、依存衝突の影響範囲を抑えられる
- 定義ファイルを見れば「何を管理しているか」がすぐ分かる

### Negative

- 管理ファイルが複数になるため、初見では把握コストが増える
- ツール追加時に「どこへ書くか」の判断が必要になる

## Operational Rules

- 新規CLI追加時は、実行前にSoTファイルへ追記する
- 1つのCLIを複数マネージャで重複管理しない
- 定期的に実環境との差分を確認し、SoTへ同期する
- 例外運用が必要な場合は、このADRを更新して意思決定を残す

## Alternatives Considered

### A. Homebrew一本化

- メリット: 管理先が1つで単純
- デメリット: Node/Python CLIの責務分離が弱く、バージョン運用が曖昧になりやすい

### B. miseへ統合

- メリット: 多言語ツール管理を1つへ統一可能
- デメリット: 既存運用（brew + volta + uv）からの移行コストが高い

現時点では、既存構成との整合性と運用コストのバランスから、`brew + volta + uv` 分離を採用する。

## Related Files

- [Makefile](../../Makefile)
- [README.md](../../README.md)
- [profile1.Brewfile](../../devtools/brew/profile1.Brewfile)
- [profile2.Brewfile](../../devtools/brew/profile2.Brewfile)
- [packages.txt](../../devtools/volta/packages.txt)
- [tools.txt](../../devtools/uv/tools.txt)
