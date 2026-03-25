# Minecraft サーバー公開・管理基盤 プロジェクト実行計画

## 1. 目的

本ドキュメントは、要件定義書および [docs/implementation_breakdown.md](./implementation_breakdown.md) をもとに、実装開始前に必要な全作業を洗い出し、依存関係、並行可否、クリティカルパスを明確化するための詳細タスクリストである。

## 2. 前提

- Ruby は Docker 上で運用する
- Ruby は 3.4 系、Rails は 8 系を利用する
- DB は MariaDB 10.11 系を利用する
- Rails generator を優先して土台を作る
- 実行基盤は外部 API 経由で制御し、Rails から Docker を直接制御しない
- 公開判定は DNS ではなく mc-router route 設定で行う

## 3. クリティカルパス

以下が本プロジェクトのクリティカルパスである。

1. Docker / Rails / MariaDB 基盤構築
2. 認証・認可・基礎データモデル構築
3. hostname 制約と公開識別子ルール確定
4. 実行基盤 API クライアント境界の定義
5. サーバー作成 / 削除 / 状態同期フロー実装
6. mc-router 設定生成 / 反映 / reload 実装
7. サーバー削除 / ライフサイクル / 状態同期フロー実装
8. 公開整合性チェック実装
9. 受け入れ条件ベースの統合検証

この順序が遅れると、後続作業の仕様固定ができず、手戻りが大きい。

## 4. 並行実行の基本方針

- 認可ポリシーと DB migration 作成は並行可能
- hostname バリデーションと実行基盤 API interface 設計は並行可能
- UI 骨組みは controller 契約確定後に並行可能
- 運用補助の可視化は、サーバー管理フローが固まった後に必要性を再評価する
- ドキュメント整備とテスト雛形は一部並行可能
- UI 文言は Rails I18n を正本とし、既定 locale は日本語、英語は切替対応とする

## 5. 詳細タスクリスト

### Phase 0: 開発基盤

#### P0-1 リポジトリ bootstrap

- `compose.yaml` を整備する
- `Dockerfile` を整備する
- MariaDB / Redis コンテナを定義する
- 開発用 `app` コンテナをホスト UID/GID で動かす
- `.dockerignore` を整備する
- 完了条件:
  - `docker compose build app` が通る
  - `docker compose up` で app/db/redis が起動する

#### P0-2 Rails 雛形生成

- `rails new . --database=mariadb-mysql` を Docker 上で実行する
- 既存ドキュメントを壊さずに Rails 雛形を生成する
- 不要な初期オプションの採用有無を決める
- 完了条件:
  - `bin/rails about` が Docker 上で通る
  - Rails アプリとして起動可能

#### P0-3 フロントエンド土台

- Inertia.js 導入方針を確定する
- React 導入を行う
- Mantine 導入を行う
- `vite_rails` と Vite を導入する
- 完了条件:
  - Inertia ページを 1 枚表示できる
  - Mantine の共通レイアウトが描画できる
  - Vite 経由で frontend asset を開発・本番ビルドできる

#### P0-4 開発用共通設定

- `.env` / credentials / config 方針を定める
- DB 接続設定を MariaDB ベースに合わせる
- queue adapter を選定する
- linter / formatter 導入方針を決める
- locale 方針は `ja` を default、`en` を optional とし、frontend は共有 locale を参照する
- 完了条件:
  - `bin/rails db:prepare` が通る
  - 開発時の必須環境変数一覧が決まる

### Phase 1: 認証・認可・基礎モデル

#### P1-1 認証方式決定と実装

- 初期版は email/password 認証で開始するかを確定する
- 認証ライブラリを選定する
- ログイン / ログアウト導線を実装する
- 初期実装は Rails 8 built-in authentication generator を採用し、`/login` と `/logout` を固定ルートにする
- 完了条件:
  - 認証必須画面へ未ログインで到達できない

#### P1-2 users テーブルと User モデル

- generator で model / migration を作成する
- 必須属性を定義する
- role の扱いを決める
- 完了条件:
  - User の基本 CRUD が可能

#### P1-3 minecraft_servers テーブルとモデル

- generator で model / migration を作成する
- owner との関連を張る
- status enum を定義する
- 実行基盤識別子と backend 情報の保持項目を定義する
- 完了条件:
  - 所有者付きのサーバーレコードを保存できる

#### P1-4 server_members テーブルとモデル

- generator で model / migration を作成する
- role を定義する
- owner との重複ルールを決める
- 初期実装では `server_members` に owner を重複保持せず、role は `viewer` と `operator` のみを持つ
- 完了条件:
  - メンバー付与と権限参照ができる

#### P1-5 router_routes テーブルとモデル

- generator で model / migration を作成する
- `enabled`、apply 状態、healthcheck 状態を持たせる
- 初期実装では `minecraft_server` と 1:1 で保持し、`last_applied_at` と `last_healthchecked_at` も持たせる
- `last_apply_status` は `pending/success/failed`、`last_healthcheck_status` は `unknown/healthy/unreachable/rejected` を採用する
- 完了条件:
  - サーバーと 1 対 1 または明確な関連で route 情報を保持できる

#### P1-6 監査ログ方針

- 初期版 product scope では監査ログの model / table / UI を持たない
- 将来必要になった場合のみ監査ログを再導入する
- 完了条件:
  - 現行コードベースに audit 専用 model / policy / UI が残っていない
- 将来メモ:
  - 監査ログを再導入する場合は custom 実装を増やさず、`audited` gem を優先候補にする

#### P1-7 認可ポリシー

- Pundit などの認可基盤を導入する
- owner / operator / viewer の権限制御を定義する
- 一覧 API / 詳細取得 / 更新 / 削除を保護する
- 初期実装では Pundit を採用し、`MinecraftServerPolicy` と `ServerMemberPolicy` を置く
- owner は管理系を許可、operator は lifecycle 操作を許可、viewer は参照のみ許可とする
- 完了条件:
  - 他人の server ID を指定しても取得できない

### Phase 2: ドメイン制約

#### P2-1 hostname 正規化ルール

- prefix 許可文字を定義する
- 小文字化ルールを定義する
- 予約語一覧を定義する
- 完了条件:
  - 保存前に hostname を正規化できる

#### P2-2 hostname 一意制約

- DB unique index を追加する
- モデルバリデーションを追加する
- 同時作成時の競合エラー方針を決める
- 完了条件:
  - 重複 hostname が保存できない

#### P2-3 fqdn / 接続先生成

- `fqdn = hostname + domain` ルールを固定する
- `hostname:port` 表示値を生成する
- `public_port` を system-wide 定数として扱う
- 初期値は `domain = mc.tosukui.xyz`、`public_port = 42434` とし、shared formatter から参照する
- 完了条件:
  - UI と backend で同一ロジックを参照できる

#### P2-4 status 遷移ルール

- `provisioning/ready/failed/degraded/unpublished/deleting` 等の遷移を定義する
- route 失敗時と実行基盤失敗時の状態分離を決める
- 初期遷移方針:
  - provider create 完了 + route apply 成功で `provisioning -> ready`
  - provider create 失敗で `provisioning -> failed`
  - route apply 失敗で `provisioning/ready/degraded -> unpublished`
  - provider 状態不整合や backend 劣化で `ready/starting/stopping/restarting -> degraded`
  - 削除要求受付後は各状態から `deleting` を許可し、完了時は物理削除する
- 完了条件:
  - 状態遷移表が定まり実装可能になる

### Phase 3: 実行基盤 API 境界

#### P3-1 実行基盤選定情報の確定

- 実行基盤は `Pterodactyl Panel + Wings` を採用する
- API は Application API と Client API の 2 面に分けて扱う
- 認証方式:
  - create/delete/metadata は Application API key
  - lifecycle/status は Client API key
- backend 情報は選択した node allocation の IP/alias + port を正本にする
- 完了条件:
  - interface 設計に必要な外部仕様が揃う

#### P3-2 client interface 作成

- base client を定義する
- create / delete / start / stop / restart / status の契約を定義する
- backend_host / backend_port をどこから取得するか決める
- 完了条件:
  - Rails 側から provider 差し替え可能な interface になる
- 進捗メモ:
  - `T-301` 完了。`ExecutionProvider::BaseClient`、`CreateServerRequest`、結果オブジェクト、例外クラス、`ExecutionProvider.build_client` の土台を追加済み。

#### P3-3 具体 client 実装

- HTTP client 実装を作る
- 例外クラスを定義する
- タイムアウトとリトライ方針を決める
- 完了条件:
  - ダミーまたは実環境向け疎通確認ができる
- 進捗メモ:
  - `T-302` 完了。`Net::HTTP` ベースで Application API と Client API を分けた `ExecutionProvider::PterodactylClient` を追加し、create/delete/fetch/power/status の JSON 契約と例外マッピングをテスト付きで実装済み。

#### P3-4 provider 設定管理

- initializer を用意する
- provider 名、token、endpoint を設定可能にする
- 完了条件:
  - 環境別に provider を切り替えられる
- 進捗メモ:
  - `T-303` 完了。initializer では `config.x.execution_provider` に静的設定のみを保持し、アプリコード側で `ExecutionProvider::Configuration` に解決する。

#### P3-5 provisioning template 設定整備

- `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES` の JSON 形を確定する
- create UI に露出する template_kind と provider 側 provisioning template を一致させる
- 開発 / 検証環境で最低限必要な template baseline を文書化する
- 完了条件:
  - 露出中の各 template_kind に対して provider provisioning template 設定が用意されている
  - 設定不足時にどの env を足せばよいかが restart docs と運用 docs から辿れる
- 進捗メモ:
  - `T-304` 完了。`docs/provider_template_env_setup.md` に required JSON shape、`fabric/paper/velocity` baseline 例、起動前チェック、失敗時の見方を追加済み。

### Phase 4: mc-router 連携

#### P4-1 mc-router 設定方式の確定

- config ファイル形式を確認する
- reload コマンドまたは API を確認する
- 未登録 hostname reject 方法を確認する
- 完了条件:
  - route renderer と applier の入力仕様が定まる
- 進捗メモ:
  - `T-400` 完了。`docs/router_api_contract.md` に `routes-config` JSON 形式、`default-server = null` による unknown hostname reject、`ROUTES_CONFIG_WATCH=true` を前提にした file-watch reload 方針、補助的な REST API の存在を固定した。

#### P4-2 route definition builder

- DB の server / route 情報から route 定義を組み立てる
- backend target の文字列表現を固定する
- 完了条件:
  - 1 server 分の route 定義を生成できる
- 進捗メモ:
  - `T-401` 完了。`Router::RouteDefinitionBuilder` が `RouterRoute` と `MinecraftServer` から `fqdn => backend_host:backend_port` を生成する。

#### P4-3 config renderer

- 全 route を 1 ファイルへレンダリングする
- テンプレートまたは serializer を決める
- 完了条件:
  - config 文字列を生成できる
- 進捗メモ:
  - `T-402` 完了。`Router::ConfigRenderer` が enabled route のみを deterministic な JSON にレンダリングし、`default-server` は `null` 固定とした。

#### P4-4 config applier

- config の保存先を決める
- バックアップ方針を決める
- reload 実行処理を実装する
- 完了条件:
  - route 反映処理が 1 service call で完結する
- 進捗メモ:
  - `T-403` 完了。`Router::ConfigApplier` が config を atomic write し、`watch` / `command` / `manual` の reload 戦略を扱う。

#### P4-5 route health check

- route 存在確認方法を実装する
- backend 疎通確認方法を実装する
- 完了条件:
  - route ごとに health 状態を保存できる

### Phase 5: サーバー lifecycle フロー

#### P5-1 サーバー作成フロー

- controller の create を実装する
- 仮レコードを作る
- job を enqueue する
- 完了条件:
  - UI から create 要求を受付できる
- 進捗メモ:
  - `T-500` 完了。`ServersController#create` から `Servers::CreateRequest` を通して provisional な `MinecraftServer` と pending `RouterRoute` を保存し、`CreateServerJob` を enqueue して詳細画面へ遷移する intake フローを追加済み。

#### P5-2 CreateServerJob

- 実行基盤へ create 要求を送る
- backend 情報を保存する
- route を生成する
- route を反映する
- success 時に `ready` へ遷移する
- 完了条件:
  - 1 件の create が end-to-end で処理される
- 進捗メモ:
  - `T-501` 完了。`CreateServerJob` は `Servers::ProvisionServer` を通して provisioning template 解決、Pterodactyl create、`provider_server_id` と `provider_server_identifier` を含む backend 情報保存、mc-router config apply、成功時の `ready` 遷移まで処理する。

#### P5-3 失敗時ロールバック

- 実行基盤 create 失敗時の failed 化
- route 反映失敗時の `unpublished` 化
- reload 失敗時の `failed` または route 無効化
- 完了条件:
  - 中途半端な公開状態を残さない
- 進捗メモ:
  - `T-502` 完了。provider create が失敗した provisional server は詳細画面から追えるよう `failed` のまま保持しつつ route を disabled にし、route apply 失敗時は route を disabled + `last_apply_status=failed` にして `unpublished` へ倒す。あわせて最新の失敗理由を `MinecraftServer.last_error_message` に残し、詳細画面で表示できるようにした。

#### P5-4 削除フロー

- 削除要求受付
- 認可確認
- 実行基盤 delete または stop 呼び出し
- route 削除
- DB 更新
- 完了条件:
  - 削除時に route が残らない
- 進捗メモ:
  - `T-503` 完了。`Servers::DestroyServer` と `ServersController#destroy` を追加し、owner 認可のもとで `deleting` 遷移、route の unpublish + router apply、provider delete、DB レコード削除までをテスト付きで固定した。

#### P5-5 起動 / 停止 / 再起動 / 同期

- action endpoint を実装する
- 実行基盤呼び出しを行う
- 状態同期ジョブを実装する
- 完了条件:
  - 各操作後に状態が UI に反映される
- 進捗メモ:
  - `T-504` 完了。`ServersController` に start/stop/restart/sync endpoint を追加し、`Servers::StartServer` / `StopServer` / `RestartServer` / `SyncServerState` を通して Client API 側の lifecycle/status 操作を `provider_server_identifier` 基準で実行し、Rails status を更新するようにした。

#### P5-6 監査イベント

- 初期版 product scope では実装しない
- 必要になった場合のみ、create / delete / lifecycle 操作の最小限イベント保存を再検討する
- 完了条件:
  - 未実装で進める判断が docs と task board に反映されている
- 将来メモ:
  - 再導入時は `audited` gem ベースで要件を再整理する

### Phase 6: Web UI

#### P6-1 共通レイアウト

- 認証済みレイアウト
- ナビゲーション
- フラッシュメッセージ
- locale 切替時も UI 文言が破綻しないこと
- 完了条件:
  - 全ページで共通 shell が使える

#### P6-2 ログイン画面

- フォーム
- バリデーション表示
- 完了条件:
  - 認証フローが UI から実行できる

#### P6-3 サーバー一覧画面

- 一覧テーブル
- 状態バッジ
- `hostname:port` コピー UI
- 所有者 / 自分の role 表示
- 完了条件:
  - 自分が見えるべきサーバーだけ一覧表示される

#### P6-4 サーバー作成画面

- フォーム
- hostname prefix バリデーション
- 作成状態表示
- route 状態表示
- 完了条件:
  - create 要求後の進行状態が分かる
- 進捗メモ:
  - `T-603` 完了。create form は実 submit と validation error 表示に対応し、受付後は server detail へ遷移して `provisioning` 状態を確認できる。

#### P6-5 サーバー詳細画面

- 基本情報
- backend 情報
- 実行基盤状態
- route 状態
- 操作ボタン
- 完了条件:
  - 運用に必要な情報が 1 画面で見える
- 進捗メモ:
  - `T-604` 完了。server detail 画面は connection target、route apply/health 状態、provider backend 情報、identifier、lifecycle action ボタンを 1 画面に集約し、controller JSON でも detail props を補完した。

#### P6-6 メンバー管理画面

- メンバー一覧
- 招待
- role 更新
- 削除
- 完了条件:
  - owner がメンバー運用できる

#### P6-7 監査・監視 UI

- 監査ログ画面は初期版スコープから外す
- publication / provider の運用補助ダッシュボードも初期版スコープから外す
- mc-router プロセス死活や listen ポートは Docker / runtime health check に委譲する
- 完了条件:
  - これらの UI を作らない判断が docs と task board に反映されている

#### P6-8 UI 日本語化

- operator-facing copy を日本語へ寄せる
- Rails I18n を正本にして文言定義を集約する
- 既存 Inertia/Mantine 画面で英語ハードコードを減らす
- 完了条件:
  - 既定 locale `ja` で主要 UI が日本語表示される
  - optional な `en` 切替余地を壊さない

### Phase 7: 整合性チェック

#### P7-1 route 整合性チェック

- DB にある / router にない
- router にある / DB にない
- 完了条件:
  - 不整合一覧を生成できる

#### P7-2 実行基盤整合性チェック

- DB にある / 実行基盤にない
- 実行基盤にある / route 無効
- 完了条件:
  - provider 不整合を検知できる

#### P7-3 backend 疎通チェック

- backend_host:backend_port への疎通
- last_healthcheck 更新
- 完了条件:
  - backend 不達が見える

### Phase 8: テスト / 品質保証

#### P8-1 モデルテスト

- validation
- association
- status 遷移
- 完了条件:
  - ドメイン制約の回帰が防げる

#### P8-2 リクエスト / 認可テスト

- 一覧スコープ
- 他人の server 取得拒否
- 操作権限テスト
- 完了条件:
  - 認可回りの後退を防げる

#### P8-3 service / job テスト

- create / delete / route apply / consistency check
- provider client の stubbed test
- 完了条件:
  - 非同期処理の主要分岐が保証される

#### P8-4 受け入れ条件テスト

- 単一公開ポート
- hostname 別ルーティング
- 未登録 hostname reject
- route 削除確認
- Playwright による実ブラウザ導線確認
- 完了条件:
  - 要件定義の受け入れ条件を automated acceptance test と実ブラウザ確認の両方で検証できる
- 進捗メモ:
  - `T-803` 完了。`test/integration/servers_acceptance_test.rb` で create success / create failure visibility / delete / lifecycle-sync acceptance を検証し、Playwright 実ブラウザ確認では login / server index / create / detail / members / delete 導線を確認済み。

### Phase 9: 運用・保守

#### P9-1 ドキュメント更新

- セットアップ手順
- 実行基盤接続設定
- mc-router 反映手順
- トラブルシュート
- 完了条件:
  - 新規参加者が環境構築できる
- 進捗メモ:
  - `T-901` 完了。`docs/provider_router_operations.md` に Rails Docker / Panel Docker / Wings host の運用トポロジ、必要 env、接続境界、provisioning checklist を追加済み。

#### P9-2 セキュリティ運用整理

- 秘密情報管理
- SSH 制限
- 公開ポート棚卸し
- 監査ログ保持方針
- 完了条件:
  - 運用時の事故要因が減る

#### P9-3 リリース準備

- 本番用 env 整理
- migrate 手順確認
- rollback 手順確認
- 完了条件:
  - 本番反映の手順が明文化される

## 6. マイルストーン案

### Milestone A: 土台構築

- Phase 0 完了
- generator が使える
- MariaDB / Redis / Rails が Docker 上で動く

### Milestone B: 権限付きデータ管理

- Phase 1 完了
- 認証と認可が効く
- 自分のサーバーだけ見える

### Milestone C: サーバー作成の骨格

- Phase 2 から Phase 5 の create まで完了
- create 要求から route 反映まで流れる

### Milestone D: 公開整合

- Phase 4 から Phase 7 完了
- route 反映、削除、同期、不整合検知が動く

### Milestone E: UI 完成と受け入れ

- Phase 6 と Phase 8 完了
- 受け入れ条件が確認できる

## 7. 直近着手順

1. Phase 0 を完了させる
2. Rails generator で認証・主要モデルを作る
3. 認可ポリシーと一覧スコープを先に固定する
4. hostname 制約を DB とモデルに入れる
5. 実行基盤 client interface を先に確定する
6. その後に create/delete フローへ入る
