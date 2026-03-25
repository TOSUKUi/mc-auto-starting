# Minecraft サーバー単一ホスト管理基盤 プロジェクト実行計画

## 1. 目的

本ドキュメントは、`Rails + docker.sock + mc-router` による単一ホスト Minecraft サーバー管理アプリへ方針転換したあとの実行計画である。設計、依存関係、並行可否、クリティカルパスを固定し、迷いなく実装を進めるための正本とする。

## 2. 前提

- Ruby は Docker 上で運用する
- Rails は既存 skeleton を継続利用する
- Rails アプリは `/var/run/docker.sock` を通じて Docker Engine を直接制御する
- 初期版は単一ホスト運用のみを対象とする
- Minecraft 実行イメージは `itzg/minecraft-server` 系を標準とする
- 公開方式は `mc-router` による単一公開ポート + FQDN ベース振り分けとする
- 接続先表示は `<server-fqdn>:<shared_public_port>` を正本とする
- Pterodactyl / Wings は現行計画の対象外とする
- `mc-router` は現行計画の対象に含む

## 3. クリティカルパス

以下が新方針でのクリティカルパスである。

1. Docker 直接制御の安全境界を定義する
2. `minecraft_servers` を direct-Docker + router 前提に再設計する
3. hostname / FQDN / single-port 接続ルールを定義する
4. Docker client wrapper を実装する
5. コンテナ create / delete / start / stop / restart / sync を実装する
6. provider 依存を除去しつつ `mc-router` 連携を維持する
7. 作成 / 詳細 UI を新前提へ簡素化する
8. 受け入れ条件ベースの統合検証を追加する
9. 単一ホスト運用手順を文書化する

この順序を崩すと、DB 項目、UI、Docker label、ポート管理の手戻りが大きい。

## 4. 並行実行の基本方針

- 認可と UI 骨組みの既存資産確認は並行可能
- データモデル見直しと Docker label / naming 規則の設計は並行可能
- Docker client wrapper 実装と UI copy 調整は並行可能
- 運用 docs は安全境界と Docker 構成が固まってから確定する
- provider 実装の cleanup は direct-Docker の最小経路が通ってから進める
- `mc-router` 連携の維持に必要な FQDN / route 設定の整合確認は並行可能

## 5. 詳細タスクリスト

### Phase 0: 方針転換と基盤維持

#### P0-1 Pivot 方針の文書固定

- restart docs を direct-Docker 方針へ更新する
- 旧 provider/router 文書を履歴扱いに下げる
- 完了条件:
  - `AGENTS.md`
  - `docs/context_map.md`
  - `docs/project_execution_plan.md`
  - `docs/task_board.md`
  - `docs/implementation_breakdown.md`
    が新方針に一致する

#### P0-2 Docker socket 利用の開発構成整理

- `app` コンテナへ `/var/run/docker.sock` を安全にマウントする方針を固める
- 開発時にどのユーザー権限で Docker API を叩くか整理する
- 完了条件:
  - compose 構成の変更方針が決まる
  - 安全上の注意点が明文化される

### Phase 1: ドメインモデルの再定義

#### P1-1 `minecraft_servers` direct-Docker 再設計

- provider 中心の項目を見直す
- `hostname`, `container_name`, `container_id`, `volume_name` などの保持方針を決める
- 完了条件:
  - 新しい正本フィールド一覧が決まる

#### P1-2 `server_members` と認可の継続方針整理

- owner / operator / viewer モデルを継続する
- create/delete/start/stop/restart/sync の権限境界を再確認する
- 完了条件:
  - direct-Docker でも既存 policy 方針を再利用できる

#### P1-3 `router_routes` 維持方針の固定

- `router_routes` を active architecture の一部として扱う
- direct-Docker 化後も必要な項目と責務を明確化する
- 完了条件:
  - provider cleanup と競合しない router 維持方針が決まる

#### P1-4 legacy provider 依存の棚卸し

- `ExecutionProvider`
- provider 前提の fixture / test / controller props / UI 表示
- 完了条件:
  - 何をいつ消すかが file 単位で見える

### Phase 2: Docker 制御設計

#### P2-1 Docker naming / labels / ownership ルール

- コンテナ名
- volume 名
- labels
- Rails が触ってよい Docker object の条件
- 完了条件:
  - Docker リソース識別規則が固定される

#### P2-2 single-port ingress / FQDN ルール

- 共有公開ポート
- hostname / fqdn 生成規則
- `mc-router` route 反映条件
- 完了条件:
  - DB と router 設定の両方で接続先規則が固定される

#### P2-3 状態遷移モデル

- `provisioning/ready/stopped/starting/stopping/restarting/degraded/unpublished/failed/deleting`
- Docker 実状態から Rails 状態への写像
- 完了条件:
  - 状態遷移表が決まり、service 実装の前提が揃う

### Phase 3: Docker 制御実装

#### P3-1 Docker client wrapper 実装

- Docker Engine API を呼ぶ service を追加する
- container create / inspect / start / stop / restart / remove を包む
- 完了条件:
  - Rails から Docker 操作を一箇所で扱える

#### P3-2 router publication 実装

- `mc-router` 用 route 定義更新を service 化する
- create/delete 時の route 適用を安定化する
- 完了条件:
  - create/delete 前後で router 設定が正しく反映される

#### P3-3 create flow 実装

- DB レコード作成
- volume / container 作成
- Docker label 付与
- route publication
- 完了条件:
  - UI からの create で Minecraft コンテナが立ち上がる

#### P3-4 lifecycle / delete / sync 実装

- start
- stop
- restart
- delete
- sync
- 完了条件:
  - UI からコンテナ lifecycle が操作できる

### Phase 4: UI の direct-Docker 化

#### P4-1 create UI 簡素化

- provider 用語を除去する
- hostname/FQDN ベースの入力と接続先案内を正本にする
- 完了条件:
  - 非インフラ寄りユーザーでも迷いにくい create 画面になる

#### P4-2 detail UI 再設計

- provider 表示を落とす
- container 状態、接続先、route publication 状態、エラーを正本にする
- 完了条件:
  - direct-Docker + router の情報だけで運用できる

### Phase 5: cleanup

#### P5-1 provider コードの撤去

- 未使用 provider service / docs / UI props を削る
- 完了条件:
  - direct-Docker と衝突する provider 前提が消えている

#### P5-2 schema cleanup

- 不要 column / table の migration 方針を確定する
- 完了条件:
- 旧 provider 依存が DB から整理される

#### P5-3 controller / UI の legacy 用語撤去

- provider 前提の JSON props を削る
- detail/index/create から provider 表示を落とす
- 完了条件:
  - UI と controller response が direct-Docker + router 用語だけで完結する

### Phase 6: 検証と運用

#### P6-1 direct-Docker テスト整備

- model tests
- request tests
- service tests
- acceptance tests
- 完了条件:
  - create/delete/lifecycle/sync が自動検証される

#### P6-2 単一ホスト運用 docs

- docker.sock マウント注意点
- compose 起動
- ポート範囲設定
- リリース / rollback
- 完了条件:
  - 新規参加者が単一ホストで再現できる

## 6. マイルストーン案

### Milestone A: 方針転換完了

- restart docs が新方針へ揃う

### Milestone B: Docker 直接 create が通る

- port 確保
- volume 作成
- container 作成
- 接続先表示

### Milestone C: 運用操作が揃う

- start / stop / restart / delete / sync が動く

### Milestone D: 旧前提の cleanup 完了

- provider/router 依存が整理される

### Milestone E: 検証と運用 docs 完了

- acceptance と運用手順が揃う

## 7. 直近着手順

1. Pivot 方針の文書を固定する
2. Docker socket の compose 方針を固める
3. `minecraft_servers` の direct-Docker + router 向けフィールド設計を決める
4. Docker naming / labels / hostname / route publication を決める
5. そのあとに Docker client wrapper 実装へ入る
