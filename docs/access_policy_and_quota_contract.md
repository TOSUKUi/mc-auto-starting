# Access Policy and Quota Contract

## Purpose

This document fixes the next-stage requirements for server creation quota, membership roles, invitation authority, and future Discord bot read capabilities.

## Scope

- サーバー作成可能量の上限
- ローカル membership role の意味
- 招待を発行できる主体と招待可能な role
- 将来の Discord Bot / browser-side read 操作の権限境界

## Non-Goals

- 監査ログ設計
- Discord slash-command UX 詳細
- 複数組織 / 複数 tenant の導入

## Server Creation Quota

### Fixed Limit

- 1 人が所有できる Minecraft サーバーの合計 `memory_mb` は 5GB を上限とする。
- この上限は件数ベースではなく、所有中サーバーの `memory_mb` 合計値ベースで判定する。
- 5GB は実装上 `5120 MB` を正本とする。

### Ownership Rule

- quota 判定の主体は `minecraft_servers.owner_id` を持つ所有者である。
- `reader` はサーバーを作成できないため quota 消費主体にならない。
- `operator` も初期方針ではサーバー作成不可とする。

### Enforcement Expectations

- サーバー作成画面では現在の使用量と残量を見える形にする。
- 作成リクエストでは必ず server-side で再検証する。
- 既存所有サーバーの `memory_mb` 合計 + 新規 requested `memory_mb` が `5120 MB` を超える場合、作成を拒否する。
- 上限超過時は「件数」ではなく「合計メモリ上限」に達したことが分かるメッセージにする。

## Membership Roles

### Canonical Roles

- `owner`
- `operator`
- `reader`

`viewer` は今後の active terminology としては使わず、`reader` に寄せる。

### Role Semantics

- `owner`
  - サーバーの所有者
  - サーバー作成可能
  - full lifecycle 操作可能
  - membership 管理可能
  - `operator` / `reader` の招待発行可能
- `operator`
  - 運用担当
  - 参加中サーバーの lifecycle 操作可能
  - 自分が owner ではないサーバーの ownership/membership structure は変更不可
  - 招待は `reader` のみ発行可能
  - `operator` は招待不可
- `reader`
  - 閲覧主体
  - サーバー詳細、接続情報、状態、今後の player count / logs など read 系情報の参照が可能
  - lifecycle 操作不可
  - サーバー作成不可
  - 他者招待不可

## Invitation Authority

### Fixed Rules

- `owner` は `operator` と `reader` の両方を招待できる。
- `operator` は `reader` のみ招待できる。
- `reader` は招待できない。
- 自分自身を `owner` 以外の role へ昇格させる経路は作らない。
- `owner` の移譲や複数 owner 化は現時点では scope 外とする。

### Invite UI Expectations

- 招待作成時に target role を明示的に選べるようにする。
- acting user が発行可能でない role は選択肢に出さない。
- 招待一覧でも対象 role が分かるようにする。

## Create Permission Boundary

- サーバー作成は `owner` に限定する。
- `reader` はサーバー作成不可。
- `operator` はデフォルトではサーバー作成不可とする。
- したがって初期版の quota 対象は owner ごとの所有メモリ合計となる。

If the product later needs self-service create for non-owner users, that should be treated as a new policy change rather than inferred from the current role names.

## Future Discord Bot and Browser Read Capabilities

### Reader-Allowed Read Surface

- `reader` は将来的に Discord Bot から read 系操作を実行できる。
- `reader` は browser-side UI でも read 系画面を閲覧できる。
- read 系の例:
  - サーバー状態確認
  - 接続情報確認
  - player count 確認
  - recent logs の閲覧

### Reader-Forbidden Write Surface

- `reader` は lifecycle 操作不可
- `reader` は command 実行不可
- `reader` は membership 変更不可
- `reader` はサーバー作成不可

### Bot Boundary Note

- Discord Bot は Rails authorization を迂回しない。
- Bot read endpoint でも acting Discord user の local role を解決する。
- `reader` に許可するのは read 系 endpoint のみで、write 系 endpoint への権限拡張は行わない。

## Follow-up Implementation Tasks

- quota 判定の domain/service 実装
- `viewer` から `reader` への terminology 移行
- 招待 model / UI / policy への target role 導入
- create 権限を `owner` 限定に寄せる policy 更新
- bot API contract を `reader` read-only 前提へ更新
