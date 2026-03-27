# Minecraft サーバー単一ホスト管理基盤 実装設計ドラフト

## 1. 前提

- 本ドキュメントは、Rails 8 + Inertia.js + React + Mantine を使って、単一ホスト上の Minecraft サーバーを Docker 直接管理しつつ `mc-router` で単一公開ポート運用するための実装設計である。
- 既存の `Pterodactyl Panel + Wings` 前提のコードと文書は履歴として残るが、今後の正本設計ではない。
- Rails アプリは `/var/run/docker.sock` をマウントされた単一ホスト control plane として振る舞う。
- 初期版の実行イメージは `itzg/minecraft-server` 系を前提とする。
- 公開方式は `mc-router` による「単一公開ポート + FQDN ベース振り分け」とする。
- Docker transport, public endpoint, runtime image, and shared network defaults are supplied through the direct-Docker env contract.
- 接続先表示は `<server-fqdn>:<shared_public_port>` を正本とする。
- UI 文言は Rails I18n を正本とし、既定 locale は日本語、英語は将来対応に留める。

## 2. システム構成

### 2.1 役割分担

- Rails:
  - 認証、認可、UI、DB 永続化
  - Docker Engine API 呼び出し
  - コンテナ / volume / label の正本管理
  - `mc-router` 向け route 定義の正本管理
- mc-router:
  - 単一公開ポートの受け口
  - FQDN から backend への振り分け
  - compose 管理の sibling service として起動
  - Rails が更新した routes JSON を `SIGHUP` で再読込
- Docker Engine:
  - Minecraft コンテナの create/start/stop/remove
  - 永続 volume の保持
- Minecraft コンテナ:
  - 実サーバープロセス
  - コンテナ単位で `itzg/minecraft-server` を実行し、`TYPE` と `VERSION` で実際のサーバー種別/版を選ぶ

### 2.2 非目標

- 複数ホスト / 複数ノード管理
- Pterodactyl 連携
- DNS 自動化
- SRV レコード運用
- 監査ログ UI
- 監視ダッシュボード
- 一般公開 SaaS を前提にした厳格な分離構成

## 3. 画面一覧

### 3.1 認証

#### ログイン画面

- パス: `/login`
- 目的: 既存ユーザー向け Discord-only ログイン入口
- 表示項目:
  - Discord ログイン CTA
  - 招待制であることの説明
  - 招待リンクを受け取った人はリンクから開始する案内
- 非表示:
  - email/password form
  - password reset 導線

### 3.2 サーバー一覧

#### サーバー一覧画面

- パス: `/servers`
- 目的: 所有または参加しているサーバーのみ一覧表示
- 表示項目:
  - サーバー名
  - 現在の参加人数
  - 接続先 `<server-fqdn>:<shared_public_port>`
  - 状態
  - Minecraft バージョン
  - container 状態
  - route publication 状態
  - 所有者 / 自分の権限
- 操作:
  - サーバー詳細へ遷移
  - サーバー作成画面へ遷移

### 3.3 サーバー作成

#### サーバー作成画面

- パス: `/servers/new`
- 目的: 新規サーバーの作成
- 入力項目:
  - サーバー名
  - サーバー識別子 / サブドメイン `hostname`
  - runtime family 選択
  - Minecraft バージョン選択
  - メモリ
- 表示項目:
  - 生成予定の接続先 `<hostname>.<public_domain>:<shared_public_port>`
  - operator に対する合計メモリ上限 `5120 MB` と現在使用量
  - `latest` など symbolic tag を選んだ場合の concrete version 表示方針
  - live source から解決し、失敗時は checked-in catalog に落ちる runtime family ごとの version 候補
  - 単一ホスト標準構成で作成されることの説明
- version 選択肢の表示方針:
  - operator には Minecraft version 名だけを見せる
  - form submit の `value` は runtime family ごとの安定した version key として扱う
  - `vanilla` と `paper` は別 source から候補を取得できる前提で設計する
  - 候補取得は create 画面表示時に Rails が upstream API を呼んで解決し、短い TTL cache と fallback を持つ
- バリデーション:
  - `hostname` 形式
  - `hostname` 一意性
  - メモリ / ディスク上限
  - user type ごとの create 可否
  - operator ごとの合計メモリ上限 `5120 MB`
  - runtime family ごとの version/tag 契約に従うこと

### 3.4 サーバー詳細

#### サーバー詳細画面

- パス: `/servers/:id`
- 目的: サーバー状態確認と運用操作
- 表示項目:
  - 現在の参加人数
  - サーバー基本情報
  - 接続先 `<server-fqdn>:<shared_public_port>`
  - router backend `<container_name>:25565`
  - Docker コンテナ状態
  - コンテナ名 / volume 名
  - Minecraft バージョン
  - route publication 状態
  - 最終エラー
- 操作:
  - 起動
  - 停止
  - 再起動
  - 状態同期
  - recent logs の確認
  - 制限付き command 実行
  - 削除

### 3.5 メンバー管理

#### メンバー一覧・招待画面

- パス: `/servers/:id/members`
- 目的: 所有者がメンバーを管理

## 4. URL 設計

### 4.1 Web ルート

```text
GET    /login
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
- global user type `admin` / `operator` / `reader` を持つ

### 5.2 minecraft_servers

保持したい主な項目:

- `owner_id`
- `name`
- `hostname`
- `slug`
- `status`
- `minecraft_version`
- `memory_mb`
- `disk_mb`
- `container_name`
- `container_id`
- `volume_name`
- `container_state`
- `last_started_at`
- `last_error_message`

### 5.3 server_members

- server membership は server visibility / participation の局所権限として維持する
- membership role は `viewer` / `manager` を正本とする
- app-wide authorization は別途 global user type `admin` / `operator` / `reader` を正本とする
- `viewer` は閲覧のみ、`manager` は対象サーバーに限った lifecycle 操作までを許可する
- 削除と membership 管理は owner または global `admin` に限定する

### 5.4 router_routes の扱い

- `router_routes` は active architecture の一部として維持する
- create/delete/sync から参照される publication 状態の正本とする
- `server_address` は関連する `MinecraftServer#fqdn` から導出する
- backend は関連する `MinecraftServer#backend` から導出する

## 6. Docker 管理方針

### 6.1 コンテナ命名

- 形式: `mc-server-<hostname>`

### 6.2 volume 命名

- 形式: `mc-data-<hostname>`

### 6.3 Docker labels

Rails が作成したリソースだけを安全に扱うため、少なくとも以下を付与する。

- `app=mc-auto-starting`
- `managed_by=rails`
- `minecraft_server_id=<db id>`
- `minecraft_server_hostname=<hostname>`

### 6.4 ingress / routing

- 公開ポートは 1 つだけ使う
- `mc-router` と Minecraft コンテナは同一 bridge network に参加させる
- Rails が hostname と backend の対応を `router_routes` 経由で管理する
- backend は `container_name:25565` を正本とする
- create/delete/sync 時に `mc-router` 設定を再生成する
- route 更新後は compose-managed `mc-router` に `SIGHUP` を送って再読込する

### 6.5 初期 create payload

`itzg/minecraft-server` コンテナへ最低限渡すもの:

- `EULA=TRUE`
- `TYPE=PAPER` または `TYPE=VANILLA`
- `VERSION=<minecraft_version>`
- `MEMORY=<memory_mb から 512MB 引いた JVM heap>`

将来追加候補:

- `MOTD`
- `DIFFICULTY`
- `OPS`
- `ENABLE_WHITELIST`

`itzg/minecraft-server` 系では、Minecraft version は image tag と同一視せず、公式 docs の `TYPE` + `VERSION` 環境変数契約を正本にする。

## 7. 状態モデル

初期状態遷移:

- `provisioning`
- `ready`
- `starting`
- `stopping`
- `stopped`
- `restarting`
- `degraded`
- `unpublished`
- `failed`
- `deleting`

基本ルール:

- DB 保存後、Docker create 成功で `provisioning -> ready`
- Docker create 失敗で `provisioning -> failed`
- 削除受付後は `deleting`
- Docker 実状態または router publication との不整合は `degraded` / `unpublished` / `failed` で明示
- route publication は `ready/stopped/starting/stopping/restarting/degraded` で有効対象とする
- lifecycle / sync / delete の詳細契約は `docs/direct_docker_lifecycle_contract.md` を正本とする

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
- provider 前提の service, docs, schema は cleanup 対象
- router 前提の service と schema は active architecture として維持する
- まずは新設計で計画と task board を切り直し、その後に migration 戦略を確定する
