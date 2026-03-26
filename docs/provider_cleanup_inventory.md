# Provider Cleanup Inventory

## Purpose

`T-205` の棚卸し正本。direct-Docker 化の完了後も repository に残っていた provider-era 依存を file 単位で記録し、どこまで cleanup したかを追跡する。

## Removed In T-700 / T-702 / T-703

以下は direct-Docker 実行経路から切り離した。

- `config/initializers/execution_provider.rb`
- `app/services/execution_provider.rb`
- `app/services/execution_provider/**/*`
- `test/services/execution_provider/**/*`
- `test/test_helper.rb` 内の provider provisioning template 初期化
- `ServersController#create` の `template_kind` 強制注入

## Remaining Schema Debt

以下は現時点では DB compatibility のため残っているが、active flow では正本ではない。

- `minecraft_servers.template_kind`
- `minecraft_servers.provider_name`
- `minecraft_servers.provider_server_id`
- `minecraft_servers.provider_server_identifier`
- `minecraft_servers.backend_host`
- `minecraft_servers.backend_port`

整理先タスク:

- `T-703`: controller / UI / response からの legacy 用語撤去
- `T-701`: restart docs から provider 文書を active workflow から外す
- schema cleanup task: provider-era column の migration 削除方針を確定する

## Remaining Historical References

履歴資料として docs に残しているもの:

- `docs/provider_api_contract.md`
- `docs/provider_template_env_setup.md`
- `docs/provider_router_operations.md`

これらは current architecture の正本ではない。`T-701` で active workflow からさらに距離を置く。
