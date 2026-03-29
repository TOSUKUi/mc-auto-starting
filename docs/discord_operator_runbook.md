# Discord Operator Runbook

## Purpose

This document is the `T-1009` operator-facing runbook for Discord OAuth login, manual invite issuance, and the internal Discord Bot relay.

Use this together with:

- [docs/discord_auth_and_bot_strategy.md](discord_auth_and_bot_strategy.md)
- [docs/discord_bot_api_contract.md](discord_bot_api_contract.md)
- [docs/operator_runbook.md](operator_runbook.md)

## What Is Implemented Today

- Discord OAuth-only browser login
- manual invite URL issuance from the Rails UI
- first-login account creation from a valid invite
- internal bot API under `/api/discord/bot/*`
- bot-triggered status, lifecycle, whitelist, and bounded RCON operations

## Required Env

Browser login requires:

- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`
- `APP_BASE_URL`

Initial owner bootstrap requires:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

Internal bot relay requires:

- `DISCORD_BOT_API_TOKEN`

The bot API CIDR allowlist is fixed in Rails to the Docker private-network range `172.16.0.0/12`. Keep the bot relay on that private network unless the trust boundary is revised first.

## First-Time Login Setup

1. Set Discord OAuth env in `.env`.
2. Seed the initial owner:

```bash
docker compose run --rm app bin/rails db:seed
```

3. Open `/login`.
4. Complete Discord OAuth as the seeded Discord user.
5. Confirm the signed-in user can open `/discord-invitations`.

If OAuth env is missing, `/login` falls back to an explanatory redirect instead of starting OAuth.

## Invite Issuance

Issue invites from `/discord-invitations`.

Current authority:

- `admin`: may invite `admin`, `operator`, `reader`
- `operator`: may invite `reader` only
- `reader`: cannot issue invites

Current invite rules:

- invite URLs are manual and copyable
- invites are Discord-user-bound
- invites are revocable
- invites expire
- invite consumption is single-use

The invite target must authenticate with the same `discord_user_id` that the invite was issued for.

## Invite Redemption

Current flow:

1. operator issues invite URL
2. recipient opens `/invites/:token`
3. Rails stores pending invite context
4. Rails redirects to Discord OAuth
5. callback checks `discord_user_id`
6. Rails creates the local user with the invited global role
7. invite is marked used

Rejected cases:

- missing token
- expired invite
- revoked invite
- Discord user mismatch
- unknown user without a valid pending invite

## Bot Relay Baseline

The Discord Bot is not part of this Rails process. It is an external relay that calls Rails-owned APIs.

Current trust boundary:

- bot API is internal-only
- route access is limited to the fixed Docker private-network CIDR allowlist
- every request needs `Authorization: Bearer <DISCORD_BOT_API_TOKEN>`
- every request needs `X-Discord-User-Id`
- Rails remains the final authorization authority

Current bot surface:

- `status`
- `start`
- `stop`
- `restart`
- `sync`
- `whitelist_list`
- `whitelist_add`
- `whitelist_remove`
- `whitelist_enable`
- `whitelist_disable`
- `whitelist_reload`
- `rcon_command`

## Bot Authorization Summary

- `reader`
  - read/status only
  - may read servers visible through ownership or membership
- `manager`
  - read/status
  - lifecycle `start/stop/restart/sync`
  - no whitelist mutation
  - no bounded RCON command input
- `owner`
  - read/status
  - lifecycle
  - whitelist mutation
  - bounded RCON command input
- `admin`
  - same or more than owner

## Bounded RCON Summary

Allowed through the bot API:

- `list`
- `say ...`
- `kick <player> [reason]`
- `save-all`
- `time set ...`
- `weather ...`

Rejected through the bot API even for owner/admin:

- `stop`
- `start`
- `restart`
- `reload`
- `op`
- `deop`
- `ban`
- `pardon`
- `whitelist ...`

Lifecycle actions must stay on the lifecycle API surface, not the RCON command surface.

## Failure Model

Common bot failures:

- `401 unauthorized_bot`
  - missing or wrong bot token
- `400 missing_discord_user_id`
  - missing acting user header
- `403 unknown_discord_user`
  - acting Discord user is not linked locally
- `403 forbidden`
  - acting user exists but lacks permission
- `422 rcon_command_forbidden`
  - blocked bounded RCON command
- `422 live_apply_failed`
  - whitelist desired state saved, but running-server live apply failed

The whitelist `live_apply_failed` contract means:

- DB desired state was saved
- running server did not apply immediately
- next start/restart will still apply the saved whitelist env

## Operator Verification Checklist

Discord login:

- `/login` redirects into Discord
- callback returns to the server index
- header shows the signed-in Discord display identity and global role

Invite flow:

- `/discord-invitations` opens
- invite creation returns a copyable `/invites/:token`
- invite recipient can finish first login exactly once

Bot relay:

- bot runner is on the Docker private network
- bot requests from outside that network do not route
- requests without bot token return `401`
- requests with unknown `X-Discord-User-Id` return `403`

## Related Files

- [app/controllers/discord_oauth_controller.rb](../app/controllers/discord_oauth_controller.rb)
- [app/controllers/discord_invitations_controller.rb](../app/controllers/discord_invitations_controller.rb)
- [app/controllers/api/discord/bot/servers_controller.rb](../app/controllers/api/discord/bot/servers_controller.rb)
- [config/initializers/omniauth.rb](../config/initializers/omniauth.rb)
- [config/initializers/discord_bot.rb](../config/initializers/discord_bot.rb)
