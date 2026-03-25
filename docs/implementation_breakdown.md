# Minecraft サーバー単一ホスト管理基盤 実装設計ドラフト

## 1. 前提

- 本ドキュメントは、Rails 8 + Inertia.js + React + Mantine を使って、単一ホスト上の Minecraft サーバーを直接 Docker 管理するための実装設計である。
- 既存の `Pterodactyl Panel + Wings` / `mc-router` 前提のコードと文書は履歴として残るが、今後の正本設計ではない。
- Rails アプリは `/var/run/docker.sock` をマウントされた単一ホスト control plane として振る舞う。
- 初期版の実行イメージは `itzg/minecraft-server` 系を前提とする。
- 公開方式は「サーバーごとにホストの公開 TCP ポートを 1 つ払い出す」単純方式とする。
- 接続先表示は `public_host:public_port` を正本とする。
- UI 文言は Rails I18n を正本とし、既定 locale は日本語、英語は将来対応に留める。

## 2. システム構成

### 2.1 役割分担

- Rails:
  - 認証、認可、UI、DB 永続化
  - Docker Engine API 呼び出し
  - ポート払い出し
  - コンテナ / volume / label の正本管理
- Docker Engine:
  - Minecraft コンテナの create/start/stop/remove
  - 永続 volume の保持
- Minecraft コンテナ:
  - 実サーバープロセス
  - コンテナ単位で `itzg/minecraft-server` を実行

### 2.2 非目標

- 複数ホスト / 複数ノード管理
- Pterodactyl 連携
- mc-router 連携
- DNS 自動化
- SRV レコード運用
- 監査ログ UI
- 監視ダッシュボード
- 一般公開 SaaS を前提にした厳格な分離構成

## 3. 画面一覧

### 3.1 認証

#### ログイン画面

- パス: `/login`
- 目的: Web UI へのログイン

### 3.2 サーバー一覧

#### サーバー一覧画面

- パス: `/servers`
- 目的: 所有または参加しているサーバーのみ一覧表示
- 表示項目:
  - サーバー名
  - 接続先 `public_host:public_port`
  - 状態
  - Minecraft バージョン
  - メモリ
  - ディスク
  - 所有者 / 自分の権限
  - 最終更新日時
- 操作:
  - サーバー詳細へ遷移
  - サーバー作成画面へ遷移

### 3.3 サーバー作成

#### サーバー作成画面

- パス: `/servers/new`
- 目的: 新規サーバーの作成
- 入力項目:
  - サーバー名
  - サーバー識別子 `slug`
  - Minecraft バージョン
  - メモリ
  - ディスク
- 表示項目:
  - 生成予定の接続先 `public_host:public_port`
  - 使う標準イメージ
- バリデーション:
  - `slug` 形式
  - `slug` 一意性
  - メモリ / ディスク上限

### 3.4 サーバー詳細

#### サーバー詳細画面

- パス: `/servers/:id`
- 目的: サーバー状態確認と運用操作
- 表示項目:
  - サーバー基本情報
  - 接続先 `public_host:public_port`
  - Docker コンテナ状態
  - コンテナ名 / volume 名
  - Minecraft バージョン
  - メモリ / ディスク
  - 最終エラー
- 操作:
  - 起動
  - 停止
  - 再起動
  - 状態同期
  - 削除

### 3.5 メンバー管理

#### メンバー一覧・招待画面

- パス: `/servers/:id/members`
- 目的: 所有者がメンバーを管理

## 4. URL 設計

### 4.1 Web ルート

```text
GET    /login
POST   /login
DELETE /logout

GET    /servers
GET    /servers/new
POST   /servers
GET    /servers/:id
DELETE /servers/:id

POST   /servers/:id/start
POST   /servers/:id/stop
POST   /servers/:id/restart
POST   /servers/:id/sync

GET    /servers/:id/members
POST   /servers/:id/members
PATCH  /servers/:id/members/:user_id
DELETE /servers/:id/members/:user_id

GET    /health
```

### 4.2 JSON endpoint 候補

```text
GET /api/servers/:id/status
GET /api/servers/:id/container
```

## 5. データモデル

### 5.1 users

- 既存 auth baseline を利用

### 5.2 minecraft_servers

保持したい主な項目:

- `owner_id`
- `name`
- `slug`
- `status`
- `minecraft_version`
- `memory_mb`
- `disk_mb`
- `public_port`
- `docker_image`
- `container_name`
- `container_id`
- `volume_name`
- `container_state`
- `last_started_at`
- `last_error_message`

### 5.3 server_members

- 既存の owner / operator / viewer モデルを継続

### 5.4 旧 router_routes の扱い

- `router_routes` は新設計の正本モデルではない
- Pivot 後の cleanup task で削除する

## 6. Docker 管理方針

### 6.1 コンテナ命名

- 形式: `mc-server-<slug>`

### 6.2 volume 命名

- 形式: `mc-data-<slug>`

### 6.3 Docker labels

Rails が作成したリソースだけを安全に扱うため、少なくとも以下を付与する。

- `app=mc-auto-starting`
- `managed_by=rails`
- `minecraft_server_id=<db id>`
- `minecraft_server_slug=<slug>`

### 6.4 ポート払い出し

- Rails が `public_port` を DB 上で一意に管理する
- ポート範囲は設定値で定義する
- create 前に未使用ポートを予約する
- delete 時に解放する

### 6.5 初期 create payload

`itzg/minecraft-server` コンテナへ最低限渡すもの:

- `EULA=TRUE`
- `TYPE=PAPER` または標準方式に対応する値
- `VERSION=<minecraft_version>`
- `MEMORY=<memory_mb 相当>`

将来追加候補:

- `MOTD`
- `DIFFICULTY`
- `OPS`
- `ENABLE_WHITELIST`

## 7. 状態モデル

初期状態遷移:

- `requested`
- `creating`
- `ready`
- `starting`
- `stopping`
- `stopped`
- `restarting`
- `failed`
- `deleting`

基本ルール:

- DB 保存後、Docker create 成功で `requested -> ready` または `stopped`
- Docker create 失敗で `requested/creating -> failed`
- 削除受付後は `deleting`
- Docker 実状態との不整合は `failed` または `stopped` へ寄せて明示

## 8. Rails 側ディレクトリ構成

```text
app/
  controllers/
    application_controller.rb
    sessions_controller.rb
    servers_controller.rb
    server_members_controller.rb
    api/
      server_statuses_controller.rb

  models/
    user.rb
    minecraft_server.rb
    server_member.rb

  policies/
    application_policy.rb
    minecraft_server_policy.rb
    server_member_policy.rb

  services/
    docker_engine/
      client.rb
      port_allocator.rb
      container_name.rb
      volume_name.rb
    servers/
      create_server.rb
      destroy_server.rb
      start_server.rb
      stop_server.rb
      restart_server.rb
      sync_server_state.rb

  jobs/
    create_server_job.rb
    sync_server_state_job.rb
```

## 9. 既存実装との関係

- auth / policy / layout / servers UI の土台は流用する
- provider / router 前提の service, docs, schema は cleanup 対象
- まずは新設計で計画と task board を切り直し、その後に migration 戦略を確定する
