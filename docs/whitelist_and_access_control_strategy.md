# Whitelist And Access Control Strategy

## Purpose

This document fixes the first implementation scope for Minecraft player whitelist management and ingress-side access restriction under the current `Rails + docker.sock + mc-router` single-host architecture.

## Scope

In scope:

- Minecraft server whitelist operations executed through Rails-owned RCON
- Web and future bot authorization boundaries for whitelist changes
- Global client IP allow/deny settings applied at the `mc-router` layer

Out of scope in this phase:

- Per-server source IP allow/deny rules
- Host firewall automation
- Browser-side ad hoc RCON consoles
- Player-ban / op-list / advanced ACL management beyond the whitelist baseline

## Research Findings

### Minecraft whitelist control

- `itzg/minecraft-server` ships with RCON enabled by default and supports one-shot console commands through `rcon-cli`.
- The runtime already documents RCON-driven command execution, which fits the existing Rails-owned command boundary.
- The image also supports startup-time whitelist file/env syncing, but that path depends on username/UUID resolution and is better suited to bootstrap state than day-2 UI mutations.

### Router-side client IP restriction

- `mc-router` supports `CLIENTS_TO_ALLOW` and `CLIENTS_TO_DENY` for source IP / CIDR filtering.
- Those settings apply to the router process itself, not to individual route mappings.
- `mc-router` also has a separate allow/deny config for auto-scale-up/down behavior, but that is about player identities for scale events and does not match this project's current single-host direct-Docker usage.

## Locked Decisions

### 1. Whitelist changes use Rails-owned RCON

- The app should treat whitelist mutation as a bounded RCON feature.
- Initial command surface:
  - `whitelist on`
  - `whitelist off`
  - `whitelist list`
  - `whitelist add <player>`
  - `whitelist remove <player>`
  - `whitelist reload`
- Whitelist operations should target running servers only.
- When a server is stopped, the UI should not offer whitelist mutations and should instead explain that the server must be running first.

### 2. Whitelist authority is stronger than lifecycle authority

- `admin` may read and mutate whitelist state on any visible server.
- Server `owner` may read and mutate whitelist state on owned servers.
- Server-local `manager` membership may operate lifecycle actions, but should not mutate whitelist state in the first pass.
- `viewer` may not read or mutate whitelist state beyond whatever is already implied by normal server visibility.

Rationale:

- Lifecycle actions are operational.
- Whitelist changes alter who may enter the server, so they should stay closer to ownership/admin authority.

### 3. Router IP restriction is global, not per-server

- `mc-router` client IP filtering should be modeled as host-wide ingress policy for the shared public port.
- The app should not present it as a per-server setting.
- If the product later needs per-server source IP restrictions, that will require a different ingress or host-firewall design, not just additional Rails UI.

### 4. Router IP restriction is operator/deploy configured

- Global allow/deny CIDRs belong in deploy-time env / runbook docs, not in the day-to-day server detail UI.
- The first implementation should document and wire the relevant env keys in Compose/Kamal/operator docs.
- A future admin UI can be considered only if there is a clear need to edit host-wide ingress policy from Rails.

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

### Router-side ingress restriction

- Do not add a per-server toggle or badge for global router IP allow/deny.
- Document the feature in setup and runbook docs as a host-wide ingress hardening option.
- If configured, the UI may later expose only a passive note such as "host-level ingress restriction is enabled", but that is not required for the first pass.

## Task Breakdown

- `T-1020`: define the whitelist and global ingress restriction contract
- `T-1021`: add Rails-side RCON whitelist service layer
- `T-1022`: add request/policy/service coverage for whitelist operations
- `T-1023`: add server-detail whitelist UI
- `T-1024`: document and wire `mc-router` global client IP allow/deny config
- `T-1025`: align future bot command scope with whitelist authority

## Sources

- `mc-router` official README:
  https://github.com/itzg/mc-router
- `itzg/minecraft-server` command docs:
  https://docker-minecraft-server.readthedocs.io/en/latest/sending-commands/commands/
- `itzg/minecraft-server` auto RCON command docs:
  https://docker-minecraft-server.readthedocs.io/en/latest/configuration/auto-rcon-commands/
- Maintainer discussion about temporary whitelist control via RCON:
  https://github.com/itzg/docker-minecraft-server/discussions/3009
