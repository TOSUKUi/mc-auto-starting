# Access Policy and Quota Contract

## Purpose

This document fixes the global user-type model, server-membership role model, server-create quota rules, invitation authority, and read/write access expectations for the next authorization pass.

## Scope

- グローバルなユーザー種別の正本
- サーバー単位 membership role の正本
- サーバー作成上限
- 招待可能範囲
- 閲覧権限と運用権限の境界
- controller レベルでの認証・認可強制

## Canonical Global User Types

アプリ全体のユーザー種別は server membership role とは別に、以下を正本とする。

- `admin`
- `operator`
- `reader`

## Canonical Server Membership Roles

サーバー単位の membership role は、global user type とは別に以下を正本とする。

- `viewer`
- `manager`

`manager` は「そのサーバーに限った lifecycle 操作担当」を意味し、global user type の `operator` とは別物として扱う。

## Global User-Type Semantics

### `admin`

- サーバー作成制限なし
- 招待制限なし
- 全サーバーの閲覧可能
- 全サーバーの lifecycle 操作可能
- 全サーバーの削除可能
- 全サーバーの membership 管理可能
- 将来の browser command / Discord bot write 操作も許可候補

### `operator`

- 自分が所有するサーバーの合計 `memory_mb` が `5120 MB` までサーバー作成可能
  ここでの `memory_mb` は Docker 上限ではなく Minecraft JVM `Xms` / `Xmx` 入力値を指す
- 招待は `reader` のみ可能
- owner のサーバーは閲覧 / lifecycle 操作 / 削除 / membership 管理が可能
- 他人のサーバーでも membership があれば、その membership に従って閲覧 / 操作が可能
- 他人のサーバーの削除と membership 管理は不可

### `reader`

- サーバー作成不可
- 招待不可
- 削除不可
- 接続情報の共有可能
- owner 権限は持たない
- membership があるサーバーだけ閲覧または操作可能
- 将来の Discord bot / browser read 系操作のみ許可候補

## Server Membership Semantics

### `viewer`

- そのサーバーの閲覧のみ可能
- 接続情報、状態、詳細メタデータの確認が可能
- lifecycle 操作は不可

### `manager`

- そのサーバーの閲覧可能
- そのサーバーの lifecycle 操作が可能
- 削除は不可
- membership 管理は不可

## Server Creation Quota

### Fixed Limit

- `operator` は、自分が所有する Minecraft サーバーの合計 `memory_mb` が `5120 MB` を超えない範囲でのみ作成できる。
  判定対象は Docker container memory ではなく Minecraft JVM メモリ入力値
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

- 招待作成時に対象 global user type を選べるようにする。
- 発行者が招待できない user type は UI に出さない。
- server-side でも target user type を必ず再検証する。

## Authorization Matrix

### `show`

- `admin` は全サーバー可
- owner は可
- membership `viewer` は可
- membership `manager` は可

### `start` / `stop` / `restart` / `sync`

- `admin` は全サーバー可
- owner は可
- membership `manager` は可
- membership `viewer` は不可

global user type が `reader` でも `operator` でも、server membership が `manager` ならそのサーバーの lifecycle 操作は可能とする。

### `destroy`

- `admin` は全サーバー可
- owner は可
- membership `manager` では不可
- membership `viewer` では不可

削除権限は ownership もしくは global `admin` に限定する。

### `manage_members`

- `admin` は全サーバー可
- owner は可
- membership `manager` では不可
- membership `viewer` では不可

### `create`

- `admin` は可
- global `operator` は quota 内で可
- global `reader` は不可

## Controller-Level Authorization Requirement

- UI でボタンを隠すだけでは不十分とする。
- create / invite / lifecycle / member-management / bot endpoints は controller レベルで認証・認可を必須化する。
- unauthorized request は controller で即時に reject する。
- policy 判定は global user type と対象 server の ownership/membership の両方を加味する。

## Relationship to Server Membership

- server membership は「そのサーバーを見えるか / 操作できるか」を決める局所的な権限として扱う。
- global user type は「アプリ全体で何ができるか」を決める大域的な権限として扱う。
- `viewer` と `manager` は global `reader` / `operator` のどちらにも付与可能とする。
- 最終的な authorize は、action ごとに global user type と ownership/membership を合成して判定する。

## Future Discord Bot / Browser Read Policy

- `reader` は将来の Discord bot read 系 endpoint を利用できる。
- `reader` は write 系 bot endpoint を利用できない。
- browser 側でも `reader` は read 系画面を基本とするが、membership `manager` のサーバーに限って lifecycle 操作は許可可能とする。
- bot path でも Rails 側で acting user の user type を解決して認可する。

## Current Gap to Close

現行コードではこの仕様はまだ未実装である。特に global user type 導入、server membership `manager` への rename、create/invite/lifecycle/destroy の controller/policy 再整理が必要である。

## Follow-up Implementation Tasks

- `users` に global user type を導入する
- `server_members.role` の `operator` を `manager` へ移行する
- create policy を `admin unrestricted` / `operator quota-limited` / `reader denied` に更新する
- invite policy を `admin unrestricted` / `operator -> reader only` / `reader denied` に更新する
- lifecycle policy を `admin or owner or membership manager` に更新する
- destroy / member-management policy を `admin or owner only` に更新する
- controller で create / invite / lifecycle / destroy / read-only endpoint を明示的に認可する
- Discord bot contract を `reader basic read-only + membership manager lifecycle` 前提へ更新する
