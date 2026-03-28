# Discord Bot API Contract

## Purpose

This document fixes the Rails-side trust boundary and command contract for Discord Bot initiated operations before bot endpoints are implemented.

`T-1005` uses this file as the authoritative contract.

## Goals

- Keep the Discord Bot as a relay, not an authority.
- Make every bot request attributable to one acting Discord user.
- Reuse the existing Rails authorization model instead of creating bot-only permissions.
- Split read-class, server-operation, whitelist, and bounded-RCON-command surfaces clearly.

## Non-Goals

- Final slash-command UX wording
- Direct bot access to Docker, container shells, or RCON
- Unbounded arbitrary RCON command passthrough

## Trust Boundary

### Bot Identity

- The bot authenticates to Rails with a dedicated bot credential.
- The bot credential represents only the Discord application itself.
- The bot credential does not imply authority to perform any server action on its own.

### Acting User Identity

- Every bot request must include the acting `discord_user_id`.
- Rails resolves that `discord_user_id` to a local `User`.
- Authorization is evaluated against the resolved local user plus the target server.
- Display names, usernames, and guild nicknames are never authorization keys.

### Rails Authority

- Rails is the final policy authority for every bot request.
- Rails decides whether the acting user can read, run lifecycle operations, or mutate whitelist state.
- The bot never performs permission filtering as the source of truth.

## Authentication Contract

The bot sends these headers on every request:

- `Authorization: Bearer <bot_token>`
- `X-Discord-User-Id: <acting_discord_user_id>`
- `X-Discord-Interaction-Id: <interaction_id>`

Rails behavior:

- Reject missing or invalid bot tokens with `401`
- Reject missing acting user id with `400`
- Reject unknown acting Discord users with `403`
- Reject authorized bot identity but unauthorized acting user with `403`

## Network Boundary Contract

- `/api/discord/bot/*` is an internal-only surface and must not be exposed as part of the public web ingress.
- Initial deployment policy allows bot API access only from the Docker private network.
- `bot_token` remains required even on the private network; network isolation and bot credential validation are both mandatory.
- If the bot runner moves outside the private Docker network in the future, the allowed network policy must be explicitly revised in docs and config before rollout.

## Authorization Contract

The effective policy model is identical to the web surface.

### Read-Class Operations

Allowed when the acting user is any of:

- global `admin`
- server owner
- server membership `viewer`
- server membership `manager`

Initial read-class bot commands:

- `status`
- `show_connection_target`
- future `player_count`
- future `recent_logs`
- `whitelist_list`

### Server Operations

Allowed when the acting user is any of:

- global `admin`
- server owner
- server membership `manager`

Initial server-operation commands:

- `start`
- `stop`
- `restart`
- `sync`

### Whitelist Operations

Allowed when the acting user is any of:

- global `admin`
- server owner

Server membership `manager` is not enough for whitelist mutation in the initial contract.

Initial whitelist commands:

- `whitelist_list`
- `whitelist_add`
- `whitelist_remove`
- `whitelist_enable`
- `whitelist_disable`
- `whitelist_reload`

### Bounded RCON Commands

Allowed when the acting user is any of:

- global `admin`
- server owner

Server membership `manager` is not enough for direct RCON command input in the initial contract.

Initial bounded-RCON commands:

- `say`
- `list`
- `kick <player>`
- `save-all`
- `time set ...`
- `weather ...`

These commands are intentionally separate from server operations. For example, `stop` remains a server-operation capability and is not exposed through the RCON command surface.

### Forbidden Through Bounded RCON

These commands must be rejected even when the acting user is `owner` or `admin`:

- `stop`
- `start`
- `restart`
- `reload`
- `op`
- `deop`
- `ban`
- `pardon`
- `whitelist ...`

### Forbidden Through Bot

These stay out of the bot surface in the initial contract:

- server create
- server destroy
- membership management
- invite issuance / revocation
- arbitrary RCON command execution outside the bounded allowlist

## Endpoint Contract

Base path:

- `/api/discord/bot`

Initial endpoints:

- `POST /api/discord/bot/servers/:id/status`
- `POST /api/discord/bot/servers/:id/start`
- `POST /api/discord/bot/servers/:id/stop`
- `POST /api/discord/bot/servers/:id/restart`
- `POST /api/discord/bot/servers/:id/sync`
- `POST /api/discord/bot/servers/:id/whitelist/list`
- `POST /api/discord/bot/servers/:id/whitelist/add`
- `POST /api/discord/bot/servers/:id/whitelist/remove`
- `POST /api/discord/bot/servers/:id/whitelist/enable`
- `POST /api/discord/bot/servers/:id/whitelist/disable`
- `POST /api/discord/bot/servers/:id/whitelist/reload`
- `POST /api/discord/bot/servers/:id/rcon/command`

`POST` is used consistently so the bot can send one authenticated request shape regardless of whether the command is read or write.

## Request Contract

Shared request body:

```json
{
  "interaction_id": "discord-interaction-id",
  "channel_id": "discord-channel-id",
  "guild_id": "discord-guild-id"
}
```

Whitelist mutation payloads add:

```json
{
  "player_name": "TOSUKUi2"
}
```

Bounded-RCON payload:

```json
{
  "command": "say サーバーメンテナンスを開始します"
}
```

## Response Contract

Shared success envelope:

```json
{
  "ok": true,
  "server_id": 28,
  "server_name": "muuchannel",
  "action": "whitelist_add",
  "message": "プレイヤーを追加しました。",
  "result": {}
}
```

Shared failure envelope:

```json
{
  "ok": false,
  "error": "human readable message",
  "error_code": "forbidden"
}
```

## Whitelist-Specific Result Contract

`whitelist_list` success:

```json
{
  "ok": true,
  "action": "whitelist_list",
  "result": {
    "enabled": true,
    "entries": ["TOSUKUi2"],
    "staged_only": false
  }
}
```

Mutation success:

```json
{
  "ok": true,
  "action": "whitelist_add",
  "message": "プレイヤーを追加しました。",
  "result": {
    "enabled": true,
    "entries": ["TOSUKUi2"],
    "staged_only": false
  }
}
```

Mutation failure after DB save but before live RCON apply:

```json
{
  "ok": false,
  "error": "ホワイトリスト設定は保存しましたが、実行中サーバーへの即時反映に失敗しました。次回起動時には保存済み設定が反映されます。原因: ...",
  "error_code": "live_apply_failed",
  "desired_state_saved": true
}
```

Bounded-RCON success:

```json
{
  "ok": true,
  "action": "rcon_command",
  "message": "コマンドを実行しました。",
  "result": {
    "command": "say サーバーメンテナンスを開始します",
    "response_body": ""
  }
}
```

Bounded-RCON forbidden command:

```json
{
  "ok": false,
  "error": "この RCON コマンドは許可されていません。",
  "error_code": "rcon_command_forbidden"
}
```

## Audit Expectations

Rails should log at least:

- bot identity accepted/rejected
- acting `discord_user_id`
- resolved local `user_id`
- target `server_id`
- requested action
- authorization outcome
- success/failure outcome

The bot does not own the audit log; Rails does.

## Implementation Notes

- Bot controller code should call the same service objects used by the web surface.
- Bot-specific code should translate request/response envelopes, not re-implement business logic.
- Whitelist bot actions should call the existing Rails-owned whitelist services and inherit the same desired-state plus live-apply behavior.
- Bot-side RCON input should use an explicit allowlist validator owned by Rails; it must not pass arbitrary text through to the Minecraft server.
