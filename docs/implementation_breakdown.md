# Minecraft サーバー公開・管理基盤 実装設計ドラフト

## 1. 前提

- 本ドキュメントは、要件定義書（修正版）を Rails + Inertia.js + React + Mantine UI 実装へ落とし込むための初期設計である。
- 現時点ではリポジトリに既存アプリケーションは存在しないため、新規 Rails アプリケーションとして構成する前提で整理する。
- Minecraft サーバーの実行責務は外部の既存実行基盤に委譲し、本アプリケーションは control plane として振る舞う。
- DNS の追加・削除は行わず、`*.mc.tosukui.xyz` と単一公開ポートを前提とする。

## 2. 画面一覧

### 2.1 認証

#### ログイン画面

- パス: `/login`
- 目的: Web UI へのログイン
- 主な要素:
  - email
  - password
  - ログイン実行ボタン
- 備考:
  - 未認証時のデフォルト遷移先
  - 将来 SSO を入れる場合もこの画面を起点にする

### 2.2 ダッシュボード

#### サーバー一覧画面

- パス: `/servers`
- 目的: 自分が所有または参加しているサーバーのみ一覧表示
- 表示項目:
  - サーバー名
  - hostname
  - 接続先 `hostname:port`
  - 状態
  - Minecraft バージョン
  - 所有者/自分の権限
  - 最終更新日時
  - route 反映状態
  - 実行基盤状態
- 操作:
  - サーバー詳細へ遷移
  - サーバー作成画面へ遷移
  - フィルタリング

### 2.3 サーバー作成

#### サーバー作成画面

- パス: `/servers/new`
- 目的: 新規サーバーの作成要求
- 入力項目:
  - サーバー名
  - hostname prefix
  - Minecraft バージョン
  - memory_mb
  - disk_mb
  - 実行基盤テンプレート種別
- 表示項目:
  - 生成される `fqdn`
  - 公開ポート
  - 接続先 `hostname:port`
  - 作成ジョブ状態
  - route 反映状態
- バリデーション:
  - hostname prefix 形式
  - hostname 一意性
  - 予約語チェック
  - リソース上限チェック

### 2.4 サーバー詳細

#### サーバー詳細画面

- パス: `/servers/:id`
- 目的: サーバー状態確認と運用操作
- 表示項目:
  - サーバー基本情報
  - 接続先 `hostname:port`
  - 実行基盤状態
  - router route 状態
  - backend 情報
  - 最終ヘルスチェック結果
  - 監査イベント概要
- 操作:
  - 起動
  - 停止
  - 再起動
  - 編集
  - 削除
  - route 再反映
  - 状態再取得

### 2.5 サーバー編集

#### サーバー設定編集画面

- パス: `/servers/:id/edit`
- 目的: サーバーのメタ情報や公開状態を更新
- 編集対象候補:
  - サーバー名
  - メモ
  - 公開有効/無効
  - メンバー権限
- 非対応候補:
  - hostname の安易な変更
  - backend の手動直接変更
- 備考:
  - hostname 変更は route と実行基盤整合に影響が大きいため、初期版では禁止または管理者限定が妥当

### 2.6 メンバー管理

#### メンバー一覧・招待画面

- パス: `/servers/:id/members`
- 目的: 所有者がメンバーを管理
- 表示項目:
  - ユーザー名
  - email
  - role
  - 追加日時
- 操作:
  - 招待
  - 権限更新
  - 削除

### 2.7 イベント・監査

#### 操作履歴画面

- パス: `/servers/:id/audit-logs`
- 目的: 対象サーバーの操作・異常履歴を確認
- 表示項目:
  - 実行者
  - event_type
  - payload 要約
  - 発生日時

### 2.8 監視

#### 監視状態画面

- パス: `/monitoring`
- 目的: 全体の router / 実行基盤 / 整合チェック結果を可視化
- 表示項目:
  - mc-router 死活
  - listen ポート状態
  - route 生成成否
  - reload 成否
  - 不整合件数
  - 未登録 hostname アクセス件数
- 備考:
  - 一般ユーザーには見せず、管理者向け画面とするのが妥当

## 3. URL 設計

### 3.1 Web ルート

```text
GET    /login
POST   /login
DELETE /logout

GET    /servers
GET    /servers/new
POST   /servers
GET    /servers/:id
GET    /servers/:id/edit
PATCH  /servers/:id
DELETE /servers/:id

POST   /servers/:id/start
POST   /servers/:id/stop
POST   /servers/:id/restart
POST   /servers/:id/sync
POST   /servers/:id/reapply-route

GET    /servers/:id/members
POST   /servers/:id/members
PATCH  /servers/:id/members/:user_id
DELETE /servers/:id/members/:user_id

GET    /servers/:id/audit-logs

GET    /monitoring
GET    /health
```

### 3.2 内部 API 方針

- Inertia ベースのため、初期版では JSON API を乱立させず controller を中心に構成する。
- ただし以下は JSON endpoint 化の価値が高い:
  - 非同期状態ポーリング
  - route 反映状態再取得
  - 実行基盤状態取得
  - 監視メトリクス取得

#### JSON endpoint 候補

```text
GET /api/servers/:id/status
GET /api/servers/:id/route-status
GET /api/servers/:id/execution-status
GET /api/monitoring/summary
```

## 4. Rails / Inertia ディレクトリ構成

### 4.1 Rails 側

```text
app/
  controllers/
    application_controller.rb
    sessions_controller.rb
    servers_controller.rb
    server_members_controller.rb
    audit_logs_controller.rb
    monitoring_controller.rb
    api/
      server_statuses_controller.rb
      monitoring_summaries_controller.rb

  models/
    user.rb
    minecraft_server.rb
    server_member.rb
    router_route.rb
    audit_log.rb

  policies/
    application_policy.rb
    minecraft_server_policy.rb
    server_member_policy.rb
    monitoring_policy.rb

  services/
    execution_provider/
      base_client.rb
      pterodactyl_client.rb
    router/
      route_definition_builder.rb
      config_renderer.rb
      config_applier.rb
      health_checker.rb
    servers/
      create_server.rb
      destroy_server.rb
      start_server.rb
      stop_server.rb
      restart_server.rb
      sync_server_state.rb
    monitoring/
      consistency_checker.rb
      unregistered_hostname_detector.rb

  jobs/
    create_server_job.rb
    destroy_server_job.rb
    sync_server_state_job.rb
    consistency_check_job.rb
    route_healthcheck_job.rb

  presenters/
    minecraft_server_presenter.rb
    monitoring_summary_presenter.rb

  validators/
    hostname_format_validator.rb
    reserved_hostname_validator.rb

config/
  routes.rb
  initializers/
    execution_provider.rb
    mc_router.rb
```

### 4.2 Inertia / React 側

```text
app/frontend/
  app.tsx
  layouts/
    authenticated-layout.tsx
    auth-layout.tsx

  pages/
    auth/
      login.tsx
    servers/
      index.tsx
      new.tsx
      show.tsx
      edit.tsx
      members.tsx
      audit-logs.tsx
    monitoring/
      index.tsx

  components/
    servers/
      server-form.tsx
      server-status-badge.tsx
      connection-info.tsx
      route-status-panel.tsx
      execution-status-panel.tsx
      members-table.tsx
    monitoring/
      monitoring-summary-cards.tsx
      inconsistencies-table.tsx
    common/
      app-shell.tsx
      copyable-text.tsx
      confirm-button.tsx
      empty-state.tsx

  lib/
    routes.ts
    format.ts
    status.ts
```

### 4.3 補足方針

- 認可は Pundit 系を第一候補とする。
- 非同期処理は Active Job を前提とし、Queue backend は Sidekiq か Solid Queue を後で選定する。
- mc-router 設定反映は service object と job に分離し、controller から直接 shell 実行しない。

## 5. ドメインモデル補足

### 5.1 `minecraft_servers`

- `status` は最低限以下を持つ:
  - `provisioning`
  - `ready`
  - `stopped`
  - `starting`
  - `stopping`
  - `restarting`
  - `degraded`
  - `unpublished`
  - `failed`
  - `deleting`

### 5.2 `router_routes`

- `enabled` は公開制御の実質フラグ
- `last_apply_status` は `pending/success/failed`
- `last_healthcheck_status` は `unknown/healthy/unreachable/rejected`

### 5.3 `server_members`

- role 候補:
  - `viewer`
  - `operator`
  - `owner`

## 6. 実装タスク分解

### フェーズ 0: アプリケーション土台

1. Rails + Inertia.js + React + Mantine UI の新規プロジェクト作成
2. 認証基盤導入
3. 共通レイアウトとナビゲーション整備
4. Pundit 等の認可基盤導入
5. バックグラウンドジョブ基盤導入

### フェーズ 1: 認可と基本データモデル

1. `users` 作成
2. `minecraft_servers` 作成
3. `server_members` 作成
4. `router_routes` 作成
5. `audit_logs` 作成
6. モデル関連付け定義
7. 所有者 / メンバー可視性制御実装
8. サーバー一覧のスコープ実装

### フェーズ 2: hostname 制約

1. hostname 正規化方針決定
   - 初期版は DNS label 準拠で `a-z`、`0-9`、内部ハイフンのみ許可
   - 保存前に trim + lowercase を適用
   - 先頭末尾ハイフンは禁止
   - 最大長は 63 文字とする
2. 予約語バリデータ実装
3. DB ユニーク制約追加
4. モデルバリデーション追加
5. 作成 UI に即時エラー表示追加

### フェーズ 3: 実行基盤 API クライアント

1. 実行基盤抽象インターフェース定義
2. 具体実装クライアント追加
3. create / delete / start / stop / restart / status API 実装
4. エラーハンドリング方針統一
5. API レスポンスから backend 接続情報抽出

### フェーズ 4: サーバー作成 / 削除フロー

1. `ServersController#create` 実装
2. 仮レコード作成と `provisioning` 遷移実装
3. `CreateServerJob` 実装
4. 実行基盤作成成功時に backend 情報保存
5. route 生成処理呼び出し
6. route 反映成功時に `ready` 遷移
7. 失敗時ロールバック実装
8. 削除フローと route 削除実装
9. 監査ログ記録実装

### フェーズ 5: mc-router 連携

1. route 定義モデル整理
2. config renderer 実装
3. 現行設定のバックアップ戦略定義
4. config ファイル生成
5. reload 実行処理
6. reload 結果検証
7. 未登録 hostname reject 方針固定
8. route 反映状態保存

### フェーズ 6: 監視と整合性チェック

1. mc-router プロセス死活チェック
2. listen ポート死活チェック
3. hostname ごとの route 存在確認
4. backend 疎通確認
5. 実行基盤状態取得ジョブ
6. DB / router / 実行基盤突合ジョブ
7. 未登録 hostname アクセス検知
8. 異常状態遷移定義

### フェーズ 7: UI 実装

1. ログイン画面
2. サーバー一覧画面
3. サーバー作成画面
4. サーバー詳細画面
5. メンバー管理画面
6. 監査ログ画面
7. 監視画面
8. エラー通知と copy UI 整備

### フェーズ 8: 運用補強

1. 監査ログ保持方針反映
2. 管理者向け監視権限制御
3. リトライ戦略
4. タイムアウト / circuit breaker 検討
5. ドキュメント整備
6. 受け入れテスト整備

## 7. 初期マイルストーン

### Milestone 1

- ログインできる
- 自分のサーバー一覧だけ見える
- サーバー作成フォームを送信できる
- DB に仮レコードができる

### Milestone 2

- 実行基盤 API 経由でサーバー作成できる
- backend 情報を保存できる
- route 定義が生成される

### Milestone 3

- mc-router へ設定反映できる
- `hostname:port` で公開できる
- 未登録 hostname が reject される

### Milestone 4

- 起動 / 停止 / 再起動できる
- 整合性チェックジョブが動く
- UI に異常状態が出る

## 8. 未確定事項を実装着手可能レベルにするための確認項目

1. 実行基盤は Pterodactyl/Wings 互換か、それ以外か
2. mc-router の設定ファイル形式と reload 手段
3. 認証方式はメール+パスワードで開始してよいか
4. 非同期ジョブ基盤は Sidekiq を使うか
5. `public_port` は固定値 `42434` として system-wide 定数化してよいか
6. hostname 変更を初期版で禁止してよいか

## 9. 次の実装着手順

1. Rails アプリを新規作成する
2. 認証・認可・主要テーブル migration を作る
3. サーバー一覧と作成画面の骨組みを先に出す
4. 実行基盤 API クライアントの interface を固定する
5. route 生成と apply を service 化する
6. 非同期ジョブと監視ジョブを追加する
