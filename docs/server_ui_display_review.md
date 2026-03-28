# Server UI Display Review

## Purpose
`T-505` の会議メモとして、サーバー一覧画面と詳細画面で表示する内容、隠す内容、状態遷移中の見せ方を固定する。

## Scope
- サーバー一覧画面
- サーバー詳細画面
- 詳細画面の状態依存アクション表示
- 詳細画面の遷移中ポーリング時の見せ方

## Out of Scope
- プレイヤー数表示
- RCON ベースの状態取得
- ログビューア
- ブラウザからのコマンド実行
- 最終同期時刻の表示

プレイヤー数は重要だが、`RCON` 周りの後続実装で扱う。現時点の UI 契約には含めない。

将来の詳細画面では、owner/admin 限定で bounded RCON command 入力欄を持てる。ただし lifecycle 系コマンドと whitelist 系コマンドは専用 UI に分離し、`stop` などの forbidden command は自由入力経路から受け付けない。

## Server Index
一覧画面では「今つながるか」「誰のサーバーか」「自分がどこまで触れるか」を短時間で判断できることを優先する。

### Show
- サーバー名
- 接続先
- 現在の状態
- 公開状態
- Minecraft バージョン
- Type (`Paper` / `Vanilla`)
- オーナー表示名
- 自分の権限 (`owner` / `manager` / `viewer`)

### Hide
- email address
- Docker の内部識別子
- backend 名
- volume 名
- 応答状態
- 最終ヘルスチェック時刻
- 最終反映時刻
- 最終同期時刻

### Owner Display
オーナー表示名は以下の優先順にする。

1. `discord_global_name`
2. `discord_username`
3. fallback の固定文字列

一覧画面では email を表示しない。

## Server Detail
詳細画面では「接続先」「現在の状態」「次にできる操作」を最優先に置く。

### Top Section
- サーバー名
- 接続先
- 現在の状態
- 公開状態
- 主要操作ボタン

### Middle Section
- Minecraft バージョン
- Type
- アクセス権
- オーナー表示名
- 最終起動
- 連続稼働時間

### Lower-Priority Section
- hostname
- fqdn
- 最終起動
- 連続稼働時間
- 直近エラー
- owner / admin 向けの whitelist カード

### Hide
- Docker の内部識別子
- 通常運用で不要な backend 情報
- 応答状態
- 最終反映
- 最終ヘルスチェック
- 最終同期時刻

### Abnormal-Only
- route apply / route audit failure の警告
- `last_error_message` を伴う直近エラー
- authorized user 向けの `公開設定を再適用` action

## Lifecycle Actions
権限判定は `policy` を維持した上で、画面では現在状態に対して妥当な次の操作だけを出す。

### Action Contract
- `ready`: `停止`, `再起動`, `同期`
- `stopped`: `起動`, `同期`
- `starting`: `同期` のみ
- `stopping`: `同期` のみ
- `restarting`: `同期` のみ
- `degraded`: `同期` を主操作にし、起動/停止の扱いは実装時に現在の runtime 状態と整合させる
- `failed`: `同期` を主操作にする
- `deleting`: 操作なし

running 中に `起動` を見せ続けるような重複操作は許容しない。

## Transition Feedback
状態遷移中の見せ方は簡素にする。

### Polling Scope
- `starting`
- `stopping`
- `restarting`

これらの状態にある間だけ詳細画面の `server` 情報を再取得する。安定状態に戻ったら自動更新を止める。

### UI Feedback
- 更新中であることはスピナー系アイコンで示す
- 秒数表示や経過時間表示は出さない
- 最終同期時刻は出さない
- ポーリング中は backend 側で `sync` 相当の再調整を行い、安定状態へ収束した結果を返す

## Follow-up Tasks
- `T-504`: 一覧のオーナー表示を Discord identity ベースへ変更
- `T-506`: 詳細画面の状態依存アクション制御
- `T-507`: 詳細画面の遷移中ポーリング
- `T-508`: 一覧/詳細の重複情報を整理し、connection / action / ownership / technical metadata の配置を見直す
- `T-1023`: owner / admin 向けの whitelist 操作 UI

## Implemented Cleanup Notes
- 一覧では `応答状態` を出さず、`公開中 / 非公開` のみを見る
- 詳細では `応答状態`、`最終反映`、`最終ヘルスチェック` を出さない
- 詳細上段は `接続先` と `公開状態` に絞る
- 詳細中段は `種類`、`Minecraft バージョン`、`オーナー`、`アクセス権` を置く
- 補助情報は `hostname`、`fqdn`、`最終起動`、`連続稼働時間` に寄せる
- `直近エラー` はトラブル時のみ独立して強調する
- route 反映失敗は通常時には隠し、`failed` のときだけ一覧の警告バッジと詳細の警告枠で見せる
- 遷移中ポーリングは `reload` だけではなく backend sync を伴う
- route failure の警告には次の行動を 1 つだけ出し、権限がある場合はその場で `公開設定を再適用` できる
- whitelist は一覧には出さず、詳細画面だけに置く
- whitelist card は owner / admin のみ表示する
- running 中は即時反映、stopped 中は staged config として編集でき、次回起動時に反映する
