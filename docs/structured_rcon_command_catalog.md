# Structured RCON Command Catalog

## Purpose

`T-1116` の正本として、browser detail と Discord bot が共有する structured RCON command catalog と argument schema を固定する。

この catalog は mutable な live server property を Rails の desired state として保存しない前提で使う。

## Goals

- browser と bot で同じ `command_key + args` contract を使う
- freeform command input ではなく schema-driven form を前提にする
- Rails 側で server-side validation と command build を一元化する
- `gamemode(mode, player_name?)` のような optional target を扱えるようにする

## Non-Goals

- arbitrary RCON passthrough
- lifecycle command を RCON surface に戻すこと
- whitelist command を RCON surface に戻すこと

## Locked Decisions

### 1. Mutable live settings are not stored as Rails desired state

- `difficulty` や `gamemode` などの mutable live settings は DB-backed desired state として持たない。
- Rails が保持するのは create-time defaults のみとする。
- live 変更は structured RCON command 実行として扱う。

### 2. The surface uses `command_key + args`

- frontend や bot は raw command string を直接組み立てない。
- request payload は `command_key` と `args` を送る。
- Rails が schema validation を通したあとに RCON command string を組み立てる。

### 3. Browser and bot share one catalog

- browser detail と Discord bot は同じ command catalog を使う。
- label や help copy は surface ごとに変えてよいが、引数 schema と server-side validation は共有する。

## Authorization Contract

Structured RCON actions are allowed only when the acting user is:

- global `admin`
- server owner

Server-local `manager` is not enough.

## Initial Command Catalog

### `difficulty`

Purpose:
- サーバー全体の難易度変更

Args:
- `difficulty`
  - type: enum
  - required: true
  - values: `peaceful | easy | normal | hard`

Build:
- `difficulty <difficulty>`

### `weather`

Purpose:
- サーバー全体の天気変更

Args:
- `weather`
  - type: enum
  - required: true
  - values: `clear | rain | thunder`

Build:
- `weather <weather>`

### `time_set`

Purpose:
- サーバー全体の時刻変更

Args:
- `time`
  - type: enum
  - required: true
  - values: `day | noon | night | midnight`

Build:
- `time set <time>`

### `say`

Purpose:
- サーバー全体への告知

Args:
- `message`
  - type: string
  - required: true
  - min_length: 1
  - max_length: 200

Build:
- `say <message>`

### `kick`

Purpose:
- プレイヤー切断

Args:
- `player_name`
  - type: minecraft_player_name
  - required: true
- `reason`
  - type: string
  - required: false
  - max_length: 200

Build:
- `kick <player_name>`
- `kick <player_name> <reason>`

### `save_all`

Purpose:
- ワールド保存

Args:
- なし

Build:
- `save-all`

### `gamemode`

Purpose:
- ゲームモード変更

Args:
- `gamemode`
  - type: enum
  - required: true
  - values: `survival | creative | adventure | spectator`
- `player_name`
  - type: minecraft_player_name
  - required: false

Build:
- `gamemode <gamemode>`
- `gamemode <gamemode> <player_name>`

Notes:
- `player_name` がなければ server/global 対象の command として扱う。
- `player_name` があればそのプレイヤーを対象にする。

## Shared Argument Types

### `minecraft_player_name`

- 3 から 16 文字
- `A-Z a-z 0-9 _` のみ

### `string`

- 前後の空白を trim して扱う
- 空文字は required field では invalid

### `enum`

- catalog 側で定義した許可値のみ valid

## Shared Request Contract

```json
{
  "command_key": "gamemode",
  "args": {
    "gamemode": "creative",
    "player_name": "TOSUKUi2"
  }
}
```

## Shared Success Contract

```json
{
  "ok": true,
  "command_key": "gamemode",
  "command": "gamemode creative TOSUKUi2",
  "response_body": "Set TOSUKUi2's game mode to Creative Mode"
}
```

## Shared Failure Contract

Validation error:

```json
{
  "ok": false,
  "error_code": "structured_rcon_invalid",
  "error": "player_name is invalid"
}
```

Execution error:

```json
{
  "ok": false,
  "error_code": "rcon_command_failed",
  "error": "RCON command requires a running server"
}
```

## UI Direction

### Browser Detail

- `コマンド` select を主軸にする
- command schema に応じて引数フォームを切り替える
- command ごとの個別 card を量産しない
- `実行` ボタンは 1 つに寄せる
- 実行結果は 1 箇所に出す

### Discord Bot

- slash command 側の UX は別でよい
- Rails に送る payload は browser と同じ `command_key + args` を使う

## Forbidden Through This Surface

- `stop`
- `start`
- `restart`
- `reload`
- `op`
- `deop`
- `ban`
- `pardon`
- `whitelist ...`
- arbitrary raw command input

## Follow-Up Tasks

- `T-1117`: Rails-side structured RCON builder / validation
- `T-1118`: detail UI を command select + args form に再構成
- `T-1119`: bot contract を structured catalog に揃える

## Related Existing Contracts

- [docs/player_observability_and_browser_console_contract.md](player_observability_and_browser_console_contract.md)
- [docs/discord_bot_api_contract.md](discord_bot_api_contract.md)
- [docs/server_startup_settings_candidates.md](server_startup_settings_candidates.md)
