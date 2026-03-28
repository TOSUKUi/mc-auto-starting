# Server Startup Settings Candidates

## Purpose

サーバー作成時または詳細画面から扱いたい「起動設定」の候補を整理する。

このメモは、起動設定 contract の正本として使う。

## Goal

- create 時に触らせるべき設定
- create 後に詳細画面から変更したい設定
- Discord bot からも扱える設定
- 初手では scope 外に置く設定

を分け、実装順を決めやすくする。

## Recommended First Batch

初手で入れる価値が高いもの:

- `difficulty`
  - `peaceful / easy / normal / hard`
  - もっとも意味が分かりやすく、UI 化しやすい
- `hardcore`
  - on / off
  - サーバー方針を大きく変えるので、早い段階で選べる価値がある
- `gamemode`
  - `survival / creative / adventure / spectator`
  - サーバー用途が明確に変わる
- `max_players`
  - 運用での需要が高い
- `motd`
  - 接続一覧で見える説明文として有用
- `pvp`
  - on / off
  - サーバー方針として重要

## Good Second Batch

次段階で扱いやすいもの:

- `view_distance`
- `simulation_distance`
- `allow_flight`
- `enable_command_block`
- `allow_nether`
- `spawn_protection`

これらは useful だが、最初の作成画面に詰め込むと重くなりやすい。

## Advanced / Needs Extra Caution

初手では慎重に扱うもの:

- `online_mode`
  - 接続方式や運用ポリシーに直結する
- `hardcore`
  - ワールド方針を強く固定する
- `force_gamemode`
- `white_list`
  - 既に専用 UI / contract があるため、設定画面へ雑に再統合しない方がよい
- `enable_rcon`
  - Rails 管理前提なので operator-facing toggle にはしない

## Recommended Split

### Create Form

作成時に直接触れる baseline:

- `hardcore`
- `difficulty`
- `gamemode`
- `max_players`
- `motd`
- `pvp`

### Detail Screen

作成後に変更しやすい候補:

- `difficulty`
- `gamemode`
- `max_players`
- `motd`
- `pvp`
- `view_distance`
- `simulation_distance`

### Discord Bot

bot でも扱える前提にする候補:

- `hardcore`
- `difficulty`
- `gamemode`
- `max_players`
- `motd`
- `pvp`

初手では browser/detail と同じ bounded setting surface を使い、bot 専用の別契約を増やしすぎない。

## Runtime Contract Direction

- Rails は startup settings を desired state として `minecraft_servers` に保存する
- create 時はその desired state をそのまま保存する
- detail と bot からの update も同じ desired state を更新する
- managed container の env は `create` / `start` / `restart` 時に current desired state から組み立てる
- 初期 baseline の startup settings は live apply を行わず、次回の起動または再起動で反映する

## UI Direction

- 初手の create form では 3 から 5 項目までに抑える
- それ以上は「詳細設定」に分ける
- whitelist や lifecycle は既存の専用 UI を維持する
- 変更結果は `server.properties` 系の desired state として Rails 側で保持し、次回の起動または再起動で反映する
- 列挙型の設定は freeform input ではなく `Select` を使う
- 想定対象:
  - `hardcore`
  - `difficulty`
  - `gamemode`
  - 将来追加する列挙型 setting
- `max_players` や `motd` のような自由入力値だけを text / number input に残す
- detail では「リアルタイム反映できる設定」と「再起動で反映する設定」を分けて見せる
- 初期 baseline では startup settings 全体が再起動反映なので、detail の editable surface は再起動反映セクションに寄せる

## Surface Contract Direction

- create form
  - 初期 desired state を決める
- server detail
  - 保存済み desired state を編集する
- Discord bot
  - 同じ desired state を read / mutate できる

つまり source of truth は Rails 側の startup settings desired state で共通化する。

## Suggested Order

1. `difficulty`
2. `hardcore`
3. `max_players`
4. `motd`
5. `pvp`
6. `gamemode`

## Related Existing Contracts

- [docs/whitelist_and_access_control_strategy.md](whitelist_and_access_control_strategy.md)
- [docs/server_ui_display_review.md](server_ui_display_review.md)
- [docs/direct_docker_env_contract.md](direct_docker_env_contract.md)
