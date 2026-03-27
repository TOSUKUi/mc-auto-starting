# Access Policy and Quota Contract

## Purpose

This document fixes the user-type model, server-create quota rules, invitation authority, and read-only access expectations for the next authorization pass.

## Scope

- ユーザー種別の正本
- サーバー作成上限
- 招待可能範囲
- read-only user の許可範囲
- controller レベルでの認証・認可強制

## Canonical User Types

アプリ全体のユーザー種別は server membership role とは別に、以下を正本とする。

- `admin`
- `operator`
- `reader`

`operator` が server member role の `operator` と紛らわしい場合は、実装時に別名へ変更してよい。ただし、意味はこの doc を正本とする。

## User-Type Semantics

### `admin`

- サーバー作成制限なし
- 招待制限なし
- サーバー情報の閲覧可能
- lifecycle 操作可能
- 将来の browser command / Discord bot write 操作も許可候補

### `operator`

- 自分が所有するサーバーの合計 `memory_mb` が `5120 MB` までサーバー作成可能
- 招待は `reader` のみ可能
- サーバー情報の閲覧可能
- lifecycle 操作可能

### `reader`

- サーバー情報の閲覧のみ可能
- 接続情報の共有可能
- サーバー作成不可
- lifecycle 操作不可
- 招待不可
- 将来の Discord bot / browser read 系操作のみ許可可能

## Server Creation Quota

### Fixed Limit

- `operator` は、自分が所有する Minecraft サーバーの合計 `memory_mb` が `5120 MB` を超えない範囲でのみ作成できる。
- `admin` にはこの quota を適用しない。
- `reader` は作成不可のため quota 対象外である。

### Ownership Rule

- quota 判定の主体は `minecraft_servers.owner_id` である。
- 判定は件数ではなく、所有中サーバーの `memory_mb` 合計で行う。
- 新規 requested `memory_mb` を加えた合計で判定する。

### Enforcement Expectations

- create form では現在使用量と残量を見える形にする。
- create request では server-side で必ず再判定する。
- quota 超過時は `5120 MB` 上限に達したことが分かるエラーメッセージを返す。

## Invitation Authority

### Fixed Rules

- `admin` は user type の制限なく招待可能
- `operator` は `reader` のみ招待可能
- `reader` は招待不可

### Invite UI Expectations

- 招待作成時に対象 user type を選べるようにする。
- 発行者が招待できない user type は UI に出さない。
- server-side でも target user type を必ず再検証する。

## Read-Only Surface for `reader`

### Allowed

- サーバー一覧 / 詳細の閲覧
- 接続情報の確認
- 状態の確認
- 将来の player count 確認
- 将来の recent logs 閲覧
- 将来の Discord bot read 系操作

### Forbidden

- サーバー作成
- start / stop / restart / sync
- command 実行
- 招待発行
- 権限変更

## Controller-Level Authorization Requirement

- UI でボタンを隠すだけでは不十分とする。
- create / invite / lifecycle / member-management / bot endpoints は controller レベルで認証・認可を必須化する。
- unauthorized request は controller で即時に reject する。
- policy 判定は user type と対象 server の ownership/membership の両方を加味する。

## Relationship to Server Membership

- server membership は「そのサーバーを見えるか / 操作できるか」を決める局所的な権限として扱う。
- user type は「アプリ全体で何ができるか」を決める大域的な権限として扱う。
- 最終的な authorize は、user type と server membership の両方を満たしたときだけ通す。

## Future Discord Bot / Browser Read Policy

- `reader` は将来の Discord bot read 系 endpoint を利用できる。
- `reader` は write 系 bot endpoint を利用できない。
- browser 側でも `reader` は read 系画面のみ利用可能とする。
- bot path でも Rails 側で acting user の user type を解決して認可する。

## Current Gap to Close

現行コードではこの仕様はまだ未実装である。特に create/invite/lifecycle の controller/policy は、この user-type モデルへ合わせて再整理が必要である。

## Follow-up Implementation Tasks

- `users` に user type を導入する
- create policy を `admin unrestricted` / `operator quota-limited` / `reader denied` に更新する
- invite policy を `admin unrestricted` / `operator -> reader only` / `reader denied` に更新する
- controller で create / invite / lifecycle / read-only endpoint を明示的に認可する
- Discord bot contract を `reader read-only` 前提へ更新する
