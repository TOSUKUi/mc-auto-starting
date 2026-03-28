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
- `mc-router` と app 管理の Minecraft コンテナは同一 bridge network に参加させる
- `mc-router` 自体は Rails ではなく `compose.yaml` 側で管理する
- router backend は `<container_name>:25565` を正本とする
- 接続先表示は `<server-fqdn>:<shared_public_port>` を正本とする
- Pterodactyl / Wings は現行計画の対象外とする
- `mc-router` は現行計画の対象に含む

## 3. クリティカルパス

以下が新方針でのクリティカルパスである。

1. Docker 直接制御の安全境界を定義する
2. `minecraft_servers` を direct-Docker + router 前提に再設計する
3. hostname / FQDN / single-port / route publication / 状態遷移ルールを定義する
4. Docker client wrapper を実装する
5. コンテナ create / delete / start / stop / restart / sync を実装する
6. provider 依存を除去しつつ `mc-router` 連携を維持する
7. 作成 / 詳細 UI を新前提へ簡素化する
8. 受け入れ条件ベースの統合検証を追加する
9. `.env` / `.env.example` / deploy secrets の境界を整理する
10. Kamal 前提の単一ホスト deploy 基盤を整える
11. 単一ホスト運用手順を文書化する
12. Discord OAuth 招待制ログインと Bot 経由の RCON 操作を追加する
13. プレイヤー人数表示とブラウザ運用コンソールを追加する
14. Java サーバー runtime の選択肢とバージョン解決を改善する

この順序を崩すと、DB 項目、UI、Docker label、ポート管理の手戻りが大きい。

## 4. 並行実行の基本方針

- 認可と UI 骨組みの既存資産確認は並行可能
- データモデル見直しと Docker label / naming 規則の設計は並行可能
- Docker client wrapper 実装と UI copy 調整は並行可能
- 運用 docs は安全境界と Docker 構成が固まってから確定する
- `.env` の required/optional 整理は運用 docs と並行可能だが、Kamal 実装前に終えて env 名を固定する
- Kamal 導入は `.env.example` の required/optional 区分と secret 注入方針が固まってから着手する
- provider 実装の cleanup は direct-Docker の最小経路が通ってから進める
- `mc-router` 連携の維持に必要な FQDN / route 設定の整合確認は並行可能
- provider schema debt の棚卸しは `docs/provider_cleanup_inventory.md` を正本にする
- Discord auth / invite / bot command 実装は P8 の運用 docs で基本運用を固めたあとに着手する
- global user type は `admin` / `operator` / `reader` を正本とし、server membership role は `viewer` / `manager` を正本とする
- 招待権限は `admin -> unrestricted`, `operator -> reader only` に制限する
- サーバー作成は `admin unrestricted`, `operator quota-limited`, `reader denied` とし、operator の所有サーバー合計 `memory_mb` は `5120 MB` 上限で扱う
- サーバー閲覧 / lifecycle 操作は ownership と membership を併用し、`manager` は global `reader` / `operator` のどちらにも付与可能とする
- サーバー削除と membership 管理は owner または global `admin` に限定する
- プレイヤー人数表示とブラウザ console UI は RCON/command trust boundary を先に固めてから進める
- Java runtime family の選択自体は先に進め、`latest` 解決と version catalog はその後に固める

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

- `app` コンテナへ `/var/run/docker.sock` を直接マウントする方針を固める
- 初期版は安全強化よりも単純さを優先し、socket proxy は導入しない
- 開発時にどのユーザー権限で Docker API を叩くか整理する
- 完了条件:
  - compose 構成の変更方針が決まる
  - docker.sock 利用上の注意点が明文化される

### Phase 1: ドメインモデルの再定義

#### P1-1 `minecraft_servers` direct-Docker 再設計

- provider 中心の項目を見直す
- `hostname`, `container_name`, `container_id`, `volume_name` などの保持方針を決める
- 完了条件:
  - 新しい正本フィールド一覧が決まる

#### P1-2 `server_members` と認可の継続方針整理

- global user type `admin` / `operator` / `reader` を正本とする
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
  - `docs/provider_cleanup_inventory.md` が正本として更新される

### Phase 2: Docker 制御設計

#### P2-1 Docker naming / labels / ownership ルール

- コンテナ名
- volume 名
- labels
- shared bridge network 名
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
- `docker` CLI は使わず、Unix socket 越しの最小 API surface に限定する
- container create / inspect / start / stop / restart / remove を包む
- 完了条件:
  - Rails から Docker 操作を一箇所で扱える

#### P3-2 router publication 実装

- `mc-router` 用 route 定義更新を service 化する
- create/delete 時の route 適用を安定化する
- 完了条件:
  - create/delete 前後で router 設定が正しく反映される
  - route enable/disable, config apply, and apply failure rollback are centralized in one service

#### P3-2.5 direct-Docker env contract

- Docker transport, public endpoint, runtime image, and shared network defaultsを env 契約として固定する
- router file path / reload 設定を app 側から一貫して参照できるようにする
- 完了条件:
  - create flow が参照する image/network/public endpoint/router path の基準値が文書とコードで一致する

#### P3-3 create flow 実装

- DB レコード作成
- volume / container 作成
- Docker label 付与
- route publication
- 完了条件:
  - UI からの create で Minecraft コンテナが立ち上がる
  - server record に `container_id`, `container_state`, `last_started_at` が反映される

#### P3-4 lifecycle / delete / sync 実装

- start
- stop
- restart
- delete
- sync
- 実装前に direct-Docker lifecycle/delete 契約を文書で固定し、Docker state から Rails status への写像と delete 順序を揃える
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
- 実 `mc-router` service を同一 network に載せた end-to-end ingress 疎通確認
- 完了条件:
  - create/delete/lifecycle/sync が自動検証される
  - route file 生成だけでなく shared public port での ingress 疎通も確認される

#### P6-2 `.env` / `.env.example` 契約の整理

- 実データを持つ `.env` をローカル専用・Git 非追跡として維持する
- `.env.example` を checked-in template の正本として扱う
- 参照されている env を required と optional に分類する
- 必須ではない env はコメントアウトしたまま例示できる形に寄せる
- Discord 初期 owner bootstrap に必要な env は required 側に残す
- 完了条件:
  - `.env` と `.env.example` の責務が docs と task board で一致する
  - required/optional の区分が deploy 前提でも破綻しない

#### P6-3 Kamal deploy 基盤

- 単一ホスト前提の Kamal deploy topology を決める
- Rails app / accessories / secret 注入方法を固定する
- 現在の local Compose 用 env 名を可能な限りそのまま deploy 側へ持ち込む
- 完了条件:
  - Kamal で deploy 可能な最小構成が決まる
  - local `.env` と deploy secrets の写像が追跡できる

#### P6-4 単一ホスト運用 docs

- docker.sock マウント注意点
- compose 起動
- ポート範囲設定
- Kamal deploy / rollback
- 完了条件:
  - 新規参加者が単一ホストで再現できる

### Phase 7: Discord 認証と Bot 運用

#### P7-1 Discord auth / invite 契約固定

- ログイン方式を Discord OAuth2 のみに固定する
- 手動発行の招待 URL と invite token の寿命・失効ルールを決める
- 初回ログイン時に招待 token と Discord identity をどう結びつけるか決める
- 正本ドキュメントは `docs/discord_auth_and_bot_strategy.md` とする
- 完了条件:
  - ローカル password 配布を前提にしない onboarding 方式が固定される

#### P7-2 Discord identity と招待実装

- `User` に Discord identity を保持する
- invite token モデルと管理 UI を追加する
- Discord callback から招待済みユーザーだけを通す
- 完了条件:
  - 手動発行した invite URL でのみ新規ユーザーが参加できる

#### P7-3 Discord-only login への切り替え

- `/login` を既存ユーザー向け Discord-only login 入口に置き換える
- 初回オーナー向けに startup log から最初の `/login` 導線を案内する
- password reset / local password login を active path から外す
- 完了条件:
  - Web UI の認証入口が Discord OAuth のみで完結する
  - 招待リンク以外から public signup はできない

#### P7-4 Bot command / RCON 実装

- Discord Bot が叩く Rails API の trust boundary を定義する
- Rails 側に RCON client service を追加する
- lifecycle 操作と制限付き RCON 実行を Bot 経由で扱えるようにする
- server whitelist 操作は同じ Rails-owned RCON boundary に乗せる
- `mc-router` の source IP 制限は per-server bot command ではなく host-wide ingress policy として別管理にする
- 完了条件:
  - Bot は Rails API 経由でサーバー操作でき、Docker やコンテナへ直接触れない

#### P7-5 Discord auth / bot フロー検証と docs

- OAuth callback
- invite redemption
- bot command authorization
- RCON 実行失敗時の扱い
- 完了条件:
  - Discord auth / invite / bot 運用のテストと手順が揃う

#### P7-6 プレイヤー人数表示とブラウザ console UI

- server 一覧と詳細で現在の参加人数を優先表示する
- recent logs を Web UI から確認できるようにする
- 制限付き command 実行を Web UI から扱えるようにする
- browser 側の command 実行も Bot と同じ Rails-owned authorization / RCON boundary に乗せる
- 完了条件:
  - operator は人数確認、ログ確認、command 実行を Discord を経由せずに Web UI から行える

### Phase 8: Java runtime と version catalog

#### P8-1 create flow の runtime family 対応

- create UI に runtime family の選択肢を追加する
- 現行の provisioning default を壊さずに Java-server path を追加する
- 完了条件:
  - operator が対応 runtime family を選んで作成できる

#### P8-2 latest 解決 / version source 調査

- `latest` のような symbolic tag から concrete version をどう得るか整理する
- tag 候補を live に取得するか、同期済み catalog を持つかを比較する
- 完了条件:
  - version 解決と tag catalog の設計判断が揃う

#### P8-3 concrete version metadata 表示

- symbolic tag と concrete version を分けて扱う
- サーバー側から取得した concrete version を一覧 / 詳細へ反映する
- 完了条件:
  - `latest` を選んだ場合でも実際の Minecraft version が UI で分かる

#### P8-4 version option catalog

- dynamic fetch または synchronized catalog のどちらかで version 選択肢を構築する
- live tag discovery が不安定な場合の fallback を用意する
- 完了条件:
  - create UI の version 選択肢生成が運用可能な形で固定される

#### P8-5 runtime-family ごとの live version source

- `vanilla` は Mojang version manifest を参照して候補を作る
- `paper` は Paper-specific version source を参照して候補を作る
- 候補取得は create 画面表示時に Rails 側で upstream API を呼び、短い TTL cache を挟む
- 初回実装では `vanilla` に `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json`、`paper` に `https://qing762.is-a.dev/api/papermc` を試す
- source ごとに到達不能時の fallback を持つ
- 完了条件:
  - runtime family に応じて候補生成の source が分かれ、誤った source の混用がなくなる

#### P8-6 version option の表示契約

- ユーザーに見せるのは Minecraft version 名だけに寄せる
- 内部で送る `value` は runtime family ごとの安定した version key として扱う
- `label` と `value` を分ける前提を UI / controller / doc で固定する
- 完了条件:
  - operator-facing 表示と内部の submitted/stored value の責務が混ざらない

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

### Milestone F: Discord SSO と Bot 操作完了

- 手動 invite URL で参加できる
- Discord ログインだけで Web UI に入れる
- Discord Bot から Rails 経由で lifecycle / RCON 操作できる

### Milestone G: 運用 UI 完了

- 一覧と詳細でプレイヤー人数を優先表示できる
- Web UI から recent logs と command console を扱える

### Milestone H: Java runtime と version catalog 完了

- 通常の Java サーバー系 runtime を選べる
- `latest` でも concrete Minecraft version が分かる
- version 選択肢の供給方法が固定される

## 7. 直近着手順

1. Pivot 方針の文書を固定する
2. Docker socket の compose 方針を固める
3. `T-303` と `T-304` は完了
4. `T-400` と `T-401` / `T-402` は完了し、`T-500` / `T-501` / `T-502` で create/detail/index UI を direct-Docker 前提へ簡素化した
5. `mc-router` の live route reload は `SIGHUP` ベースで安定化済み
6. 次は request / acceptance / operations docs を厚くする
7. その後は Discord bot/RCON 基盤を足場に、プレイヤー人数表示とブラウザ console UI を追加する
8. Java runtime family の選択はその独立トラックの先頭で進め、`latest` 解決と version catalog はその後に続ける
