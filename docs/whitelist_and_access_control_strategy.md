# Whitelist And Access Control Strategy

## Purpose

This document fixes the first implementation scope for Minecraft player whitelist management under the current `Rails + docker.sock + mc-router` single-host architecture.

## Scope

In scope:

- Minecraft server whitelist operations executed through Rails-owned RCON
- Web and future bot authorization boundaries for whitelist changes

Out of scope in this phase:

- Router-side source IP restrictions
- Browser-side ad hoc RCON consoles
- Player-ban / op-list / advanced ACL management beyond the whitelist baseline

## Research Findings

### Minecraft whitelist control

- `itzg/minecraft-server` ships with RCON enabled by default and supports one-shot console commands through `rcon-cli`.
- The runtime already documents RCON-driven command execution, which fits the existing Rails-owned command boundary.
- The image also supports startup-time whitelist file/env syncing, but that path depends on username/UUID resolution and is better suited to bootstrap state than day-2 UI mutations.

## Locked Decisions

### 1. Whitelist changes use Rails-owned RCON

- The app should treat whitelist mutation as a bounded RCON feature.
- Managed containers should start with RCON enabled, using a per-server password derived by Rails from a stable app secret plus the local server identity.
- Managed containers should also start with whitelist enforcement enabled by default, so a server with no listed players behaves as closed until an operator explicitly adds entries or disables whitelist mode.
- Initial command surface:
  - `whitelist on`
  - `whitelist off`
  - `whitelist list`
  - `whitelist add <player>`
  - `whitelist remove <player>`
  - `whitelist reload`
- Whitelist operations should target running servers only.
- When a server is stopped, the UI should not offer whitelist mutations and should instead explain that the server must be running first.
- Because server data lives under the managed `/data` volume, successful whitelist mutations should survive ordinary start/stop/restart cycles.
- Changing this default affects newly provisioned containers; existing containers created before the change still need an explicit `whitelist on` once.

### 2. Whitelist authority is stronger than lifecycle authority

- `admin` may read and mutate whitelist state on any visible server.
- Server `owner` may read and mutate whitelist state on owned servers.
- Server-local `manager` membership may operate lifecycle actions, but should not mutate whitelist state in the first pass.
- `viewer` may not read or mutate whitelist state beyond whatever is already implied by normal server visibility.

Rationale:

- Lifecycle actions are operational.
- Whitelist changes alter who may enter the server, so they should stay closer to ownership/admin authority.

### 3. Router-side IP restriction is not part of the active scope

- The current product requirement is to improve access control through the Minecraft whitelist first.
- Router-side source IP restriction is deferred rather than forced into the current design.
- No task in this phase should present source IP restriction as a supported per-server feature.

## UX Direction

### Server detail

- Add a whitelist card only when the server is running.
- Show current whitelist mode and current entries.
- Offer explicit actions:
  - `ホワイトリストを有効化`
  - `ホワイトリストを無効化`
  - `プレイヤーを追加`
  - `プレイヤーを削除`
  - `再読込`
- If the acting user lacks whitelist authority, show nothing or read-only state depending on the finalized UI contract.

### Error handling

- RCON timeout / auth / command failure must map to operator-readable errors.
- The UI should always tell the user what to do next:
  - start the server first
  - retry later
  - contact an admin if the server cannot accept RCON

## Task Breakdown

- `T-1020`: define the whitelist command and authority contract
- `T-1021`: add Rails-side RCON whitelist service layer
- `T-1022`: add request/policy/service coverage for whitelist operations
- `T-1023`: add server-detail whitelist UI
- `T-1024`: align future bot command scope with whitelist authority

## Sources

- `itzg/minecraft-server` command docs:
  https://docker-minecraft-server.readthedocs.io/en/latest/sending-commands/commands/
- `itzg/minecraft-server` auto RCON command docs:
  https://docker-minecraft-server.readthedocs.io/en/latest/configuration/auto-rcon-commands/
- Maintainer discussion about temporary whitelist control via RCON:
  https://github.com/itzg/docker-minecraft-server/discussions/3009
