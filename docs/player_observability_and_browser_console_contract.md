# Player Observability And Browser Console Contract

## Purpose

This document fixes the contract for player count, recent logs, and the browser-side structured bounded RCON actions before the UI work in `T-1011` and `T-1012`.

`T-1010` uses this file as the authoritative contract.

## Scope

In scope:

- player count and online-player read surface
- recent Minecraft server log read surface
- browser-side structured bounded RCON actions
- authorization, refresh behavior, and payload shape for those surfaces

Out of scope in this phase:

- arbitrary RCON passthrough
- browser-side whitelist mutation through the command console
- browser-side lifecycle controls beyond the already-implemented server actions
- full-text log search or long-term log retention
- player-ban / op-list / advanced moderation flows

## Locked Decisions

### 1. Player count uses Rails-owned RCON as the source of truth

- Player count and online-player names should come from the Minecraft `list` command through Rails-owned RCON.
- The app should not derive player count from Docker state.
- The app should treat player count as opportunistic read data, not as lifecycle truth.
- If RCON is unavailable, player count should be treated as unavailable rather than guessed.

### 2. Recent logs use Docker logs as the source of truth

- Recent server logs should come from the managed container's stdout/stderr via the Rails-owned Docker boundary.
- Log viewing stays read-only.
- The initial log surface is a short tail view for current troubleshooting, not a persistent audit store.

### 3. Browser-side RCON actions reuse the same bounded policy as the bot

- The browser-side RCON surface must use the same Rails-owned bounded RCON boundary as the bot surface.
- Allowed commands stay aligned with `Servers::BoundedRconCommand`.
- Forbidden commands such as `stop`, `start`, `restart`, `reload`, `op`, `deop`, `ban`, `pardon`, and `whitelist ...` remain blocked.
- Lifecycle operations continue to live behind the dedicated lifecycle buttons.
- Whitelist operations continue to live behind the dedicated whitelist card.
- The first browser surface should prefer structured forms such as `difficulty`, `weather`, `time`, `say`, `kick`, and `save-all` instead of a freeform command textarea.

## Authorization Contract

### Player count and online-player names

Allowed when the acting user can already view the server:

- global `admin`
- server owner
- server membership `viewer`
- server membership `manager`

### Recent logs

Allowed for the same visibility set as server detail:

- global `admin`
- server owner
- server membership `viewer`
- server membership `manager`

The initial log view is read-only for visible members.

### Browser structured bounded RCON actions

Allowed only when the acting user is:

- global `admin`
- server owner

Server-local `manager` is not enough for direct browser-side RCON actions in the first pass.

## Refresh Strategy

### Player count

- Do not poll player count on the index page continuously.
- Fetch player count on server detail when the server is in a running/ready-like state.
- Refresh on an explicit short interval only while the detail page is visible.
- Stop refreshing when the server is stopped or when the detail page is no longer active.
- If RCON fails, keep the server page usable and show the player count surface as unavailable.

### Recent logs

- Fetch the most recent bounded tail on demand from the detail page.
- The initial browser log viewer should use manual refresh rather than aggressive streaming.
- Future streaming is allowed but not part of this contract.

### Browser structured RCON actions

- Commands execute only on explicit submit.
- The UI should show the command result returned by Rails.
- The UI should not retry commands automatically.
- The initial browser surface should be preset forms rather than arbitrary text input.

## Payload Contract

### Player count payload

```json
{
  "available": true,
  "online_count": 2,
  "max_players": 20,
  "online_players": ["TOSUKUi2", "Steve"]
}
```

Unavailable case:

```json
{
  "available": false,
  "error_code": "player_count_unavailable"
}
```

Notes:

- `online_players` is optional in index summaries and required only on detail reads.
- `max_players` may be omitted if the current runtime response does not provide it reliably.

### Recent logs payload

```json
{
  "available": true,
  "lines": [
    "[12:00:01] [Server thread/INFO]: Done (12.345s)! For help, type \"help\"",
    "[12:00:15] [Server thread/INFO]: TOSUKUi2 joined the game"
  ],
  "truncated": true
}
```

Unavailable case:

```json
{
  "available": false,
  "error_code": "logs_unavailable"
}
```

### Browser bounded RCON success

```json
{
  "ok": true,
  "command": "say サーバーメンテナンスを開始します",
  "response_body": "サーバーメンテナンスを開始します"
}
```

Forbidden command:

```json
{
  "ok": false,
  "error_code": "rcon_command_forbidden",
  "error": "この RCON コマンドは許可されていません。"
}
```

## UI Direction

### Index

- Show player count only when available.
- Do not let player count displace connection target or primary server state.
- If unavailable, prefer hiding the count rather than showing noisy warnings in the index.

### Detail

- Show player count ahead of lower-priority metadata.
- Allow a visible member to see online-player names when available.
- Show recent logs in a dedicated read-only panel.
- Show structured RCON actions only for owner/admin.
- Keep lifecycle buttons, whitelist controls, and structured RCON actions visually separate.

### Error behavior

- Player count failure should degrade quietly to an unavailable state.
- Log read failure should show a clear retry affordance.
- Command execution failure should show the returned Rails error inline with no hidden retry.

## Follow-Up Tasks

- `T-1011`: surface player counts in index and detail
- `T-1012`: add browser log viewer and structured bounded RCON UI

## Related Existing Contracts

- [docs/discord_bot_api_contract.md](discord_bot_api_contract.md)
- [docs/whitelist_and_access_control_strategy.md](whitelist_and_access_control_strategy.md)
- [docs/server_ui_display_review.md](server_ui_display_review.md)
