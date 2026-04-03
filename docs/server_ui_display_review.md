# Server UI Display Review

## Purpose
`T-505` の会議メモとして、サーバー一覧画面と詳細画面で表示する内容、隠す内容、状態遷移中の見せ方を固定する。

## Scope
- サーバー一覧画面
- サーバー詳細画面
- 詳細画面の状態依存アクション表示
- 詳細画面の遷移中ポーリング時の見せ方

## Out of Scope
- 最終同期時刻の表示

プレイヤー数、recent logs、browser bounded RCON console は後続実装で扱い、その正本は [docs/player_observability_and_browser_console_contract.md](player_observability_and_browser_console_contract.md) とする。

起動設定の baseline surface は create、detail、bot で共有し、その正本は [docs/server_startup_settings_candidates.md](server_startup_settings_candidates.md) とする。

将来の詳細画面では、owner/admin 限定で structured bounded RCON action 群を持てる。ただし lifecycle 系コマンドと whitelist 系コマンドは専用 UI に分離し、`stop` などの forbidden command は自由入力経路から受け付けない。

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
- visible member 向けの recent logs パネル
- visible member 向けの起動設定表示
- owner / admin 向けの whitelist カード
- owner / admin 向けの structured RCON action 群

### Whitelist Placement And Warnings
- whitelist は詳細画面内で server operations より上に置く
- whitelist mode 切り替えは `有効 / 無効` の toggle-style control で扱う
- `有効 + entry 0件` は強い warning とし、`プレイヤーを追加` のページ内導線だけを出す
- `無効` は継続的な warning とし、誰でも接続できる状態であることを伝える
- warning の近くに追加フォームを密集させず、add-player UI はカード内の既存入力箇所へ scroll / focus で誘導する
- `有効 + entry 1件以上` では warning を出さない

### Index Primary Action
- 一覧の `詳細を見る` は card の primary action として明確に見える必要がある
- 小さい右寄せ text-button のままにしない
- 一覧では card 自体を詳細への primary action として扱う
- hover / focus で押下可能だと分かる視覚反応を出す
- `詳細を見る` は card 下端の supporting cue に留める

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
- 詳細画面は action 表示前に runtime 実状態へ寄せる。たとえば stale な `ready` が実際には停止済みなら、画面上は `stopped` 相当として `起動` を見せる
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
- `T-1120`: whitelist detail UX を toggle + warning guidance に寄せる
- `T-1121`: 一覧 card の `詳細を見る` primary action を再設計する

## Implemented Cleanup Notes
- 一覧では `応答状態` を出さず、`公開中 / 非公開` のみを見る
- 詳細では `応答状態`、`最終反映`、`最終ヘルスチェック` を出さない
- 詳細上段は `接続先` と `公開状態` に絞る
- 一覧では card 自体を primary action として扱い、hover / focus 反応と `詳細を見る` supporting cue で詳細導線を補強する
- 詳細中段は `種類`、`Minecraft バージョン`、`オーナー`、`アクセス権` を置く
- 補助情報は `hostname`、`fqdn`、`最終起動`、`連続稼働時間` に寄せる
- `直近エラー` はトラブル時のみ独立して強調する
- route 反映失敗は通常時には隠し、`failed` のときだけ一覧の警告バッジと詳細の警告枠で見せる
- 遷移中ポーリングは `reload` だけではなく backend sync を伴う
- route failure の警告には次の行動を 1 つだけ出し、権限がある場合はその場で `公開設定を再適用` できる
- whitelist は一覧には出さず、詳細画面だけに置く
- whitelist card は owner / admin のみ表示する
- running 中は即時反映、stopped 中は staged config として編集でき、次回起動時に反映する
- player count は一覧では available なときだけ補助情報として出し、詳細では lower-priority metadata より上に出す
- 詳細の player count は running 中だけ短い間隔で部分更新し、取得失敗時は静かに unavailable へ落とす
- startup settings は一覧には出さず、詳細画面で read-only 表示する
- startup settings は一覧には出さず、詳細画面では create-time の初期設定として read-only で見せる
- startup settings の live 変更は structured RCON action 側へ寄せる
