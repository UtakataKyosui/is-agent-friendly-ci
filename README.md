# is-agent-friendly-ci

CLIを開発する際に、それがAI-Friendly / AI-Readyかどうか確かめるためのCIです。

[AIエージェントフレンドリーなCLI設計の8原則](https://zenn.dev/assign/articles/b3d1d07d385b87) に基づいたチェックを GitHub Actions として提供します。

## チェック内容

| # | チェック項目 | 重要度 |
|---|---|---|
| 01 | 構造化出力 — `schema_version` + `kind` を持つ JSON を stdout に出力 | required |
| 02 | セマンティック終了コード — 0 (成功) / 2 (引数エラー) / 3 (未発見) | required |
| 03 | 非対話モード — TTY・stdin なしで完了、インタラクティブプロンプトなし | required |
| 04 | Noun-Verb 文法 — `<cli> <名詞> <動詞>` の形式に従う | required |
| 05 | スキーマ自己記述 — `describe` コマンドで引数構造を JSON 返却 | recommended |
| 06 | アクション可能エラー — エラー JSON に `next_step` / `candidates` フィールドを含む | recommended |
| 07 | 冪等操作 (`--dry-run`) — `--dry-run` フラグをサポート | recommended |
| 08 | コンポーザビリティ — `--format json` / `--format tsv` フラグをサポート | recommended |

## 使い方

> **バージョン固定を推奨:** 本番ワークフローでは `@main` ではなく、リリースタグ (例: `@v1.0.0`) を
> 指定してください。タグがまだない場合はコミット SHA で固定することで予期しない破壊的変更を防げます。

### 最小構成

```yaml
# .github/workflows/agent-friendly-check.yml
name: Agent Friendly Check

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # CLI のビルド・インストールをここで行う
      # - run: go build -o ./bin/mycli ./...

      - uses: UtakataKyosui/is-agent-friendly-ci@v1.0.0
        with:
          cli-command: './bin/mycli'  # テスト対象の CLI コマンド
          resource: 'task'            # テストに使うリソース名詞
```

### 全オプション

```yaml
- uses: UtakataKyosui/is-agent-friendly-ci@v1.0.0
  with:
    # 必須
    cli-command: './bin/mycli'   # テスト対象の CLI コマンド
    resource: 'task'             # テストに使うリソース名詞 (例: task, project, user)

    # 動詞のカスタマイズ (デフォルト値あり)
    list-verb: 'list'            # 一覧取得の動詞 (デフォルト: list)
    create-verb: 'create'        # 作成の動詞 (デフォルト: create)
    create-args: ''              # create コマンドへの追加引数 (デフォルト: 空)
    get-verb: 'get'              # 単一取得の動詞 (デフォルト: get)
    describe-verb: 'describe'    # スキーマ自己記述の動詞 (デフォルト: describe)

    # エラーケースのカスタマイズ
    # デフォルトは存在しないことが確実なランダム文字列が設定されています
    invalid-args: '--no-such-flag'       # exit 2 を返すべき引数
    nonexistent-id: 'no-such-id-99999'  # exit 3 を返すべき存在しない ID

    # CI 失敗の閾値
    # "required"    — 必須チェックのみで失敗 (デフォルト)
    # "recommended" — 必須 + 推奨チェックで失敗
    # "all"         — 重要度に関わらず全チェックで失敗
    severity: 'recommended'
```

### outputs の利用

```yaml
- uses: UtakataKyosui/is-agent-friendly-ci@v1.0.0
  id: check
  with:
    cli-command: './bin/mycli'
    resource: 'task'

- run: echo "passed=${{ steps.check.outputs.passed }}, failed=${{ steps.check.outputs.failed }}"
```

## severity について

`severity` で CI を失敗させる基準を調整できます。

```
required     → 必須4項目のみチェック (最初の導入に推奨)
recommended  → 必須 + 推奨4項目 (合計8項目)
all          → 全項目 (重要度に関わらずすべてのチェック失敗でエラー)
```

まず `severity: required` から始めて、徐々に `recommended` へ引き上げるのがおすすめです。

## 動作確認済み環境

- `ubuntu-latest`
- `macos-latest` (`timeout` コマンド不在時はチェック03のタイムアウトなしで実行されます。CLI が入力待ちでハングする場合は `brew install coreutils` で GNU timeout を導入してください)
- 事前条件: `jq` がインストールされていること (GitHub Actions の ubuntu/macos ランナーには標準搭載)

