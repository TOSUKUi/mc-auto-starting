# Discord Auth and Bot Strategy

## Purpose

This document fixes the strategy for Discord-based authentication, manual invite issuance, and Discord Bot mediated server operations before implementation starts.

`T-1000` uses this file as the authoritative contract for the Discord auth and bot track.

## Goals

- Replace local password distribution with Discord OAuth2 based sign-in.
- Keep onboarding under explicit operator control through manually issued invite URLs.
- Use `discord_user_id` as the authoritative external identity key.
- Let a Discord Bot trigger server operations without granting the bot direct access to Docker or Minecraft containers.
- Route Minecraft command execution through Rails-owned RCON integrations.

## Non-Goals

- General public self-signup
- Email-based account invitations
- Discord guild membership as the only admission control
- Direct bot access to `/var/run/docker.sock`
- Direct bot access to Minecraft containers or RCON endpoints
- Designing the full slash-command UX before backend trust boundaries are fixed

## Fixed Decisions

### Identity

- The authoritative external identity key is `discord_user_id`.
- Local user resolution must not depend on email address.
- Discord profile fields such as username, global name, avatar, and email are auxiliary attributes, not identity keys.
- Existing local password login is a migration baseline only and should be removed from the active path by `T-1003`.

### Authentication

- Web sign-in will use Discord OAuth2 Authorization Code flow.
- The Rails app remains the OAuth client and completes the callback on the server side.
- Rails-managed sessions remain the local authenticated session mechanism after OAuth succeeds.
- Discord OAuth should be implemented through an OmniAuth-based strategy rather than a custom OAuth client implementation.
- `/login` remains as the browser login entry, but it should expose only Discord sign-in for existing users.
- Public signup must stay disabled; creating a new local user is allowed only from a valid invite redemption flow.
- The bootstrap owner should still be seeded from `BOOTSTRAP_DISCORD_USER_ID`, and startup logs may point that operator at `/login` for the first Discord sign-in.

### Invitations

- New user onboarding is invite-only.
- Invite URLs are issued manually by an authenticated operator from the app.
- The app does not send invitation emails automatically.
- Invite redemption is tied to Discord login and validated against the Discord identity returned by OAuth.
- Invitations should be revocable, expirable, and single-use or otherwise explicitly state their reuse policy in implementation docs.
- Invitation authority and target-role limits should follow `docs/access_policy_and_quota_contract.md`.

### Bot Integration

- The Discord Bot is an external caller to Rails-owned APIs.
- The bot must not control Docker directly.
- The bot must not connect directly to Minecraft containers.
- All lifecycle operations and Minecraft command execution must be mediated by Rails authorization and service boundaries.
- Bot authentication to Rails must use a dedicated machine-to-machine trust mechanism, separate from end-user browser sessions.

### Minecraft Command Execution

- In-game command execution will use RCON from Rails to the managed Minecraft server.
- RCON connection details are app-managed server configuration and not a Discord Bot concern.
- Rails must apply command allowlisting or equivalent policy controls before exposing command execution to the bot.
- Lifecycle actions and RCON actions are separate capabilities and should be authorized independently.

## Recommended Architecture

### Login Flow

1. An operator manually issues an invite URL.
2. The recipient opens the invite URL.
3. Rails stores invite context and redirects the user to Discord OAuth.
4. Discord redirects back with the authenticated Discord identity.
5. Rails validates the invite against the returned `discord_user_id`.
6. If valid, Rails creates or links the local `User`.
7. Rails starts the normal local session.

### Identity Model

- `users` should gain Discord identity fields headed by `discord_user_id`.
- `discord_user_id` should be unique and required for active users after the migration is complete.
- Local user visibility, membership, and ownership logic continue to use local `users.id`; Discord identity is the external lookup key that resolves to that local user.

### Role Model

- The active global user-type vocabulary should be `admin`, `operator`, and `reader`.
- `admin` may invite without restriction and is not quota-limited on server creation.
- `operator` may invite only `reader` and is limited to `5120 MB` total owned server memory for create actions.
- `reader` is a read-only user type and must not gain create or invitation authority.
- Bot authorization should inherit the same user-type semantics rather than introducing a Discord-only permission model.

### Invite Model

- Invitations should be stored as app-owned records rather than inferred from Discord guild membership.
- The stored invite record should support:
  - token verification without persisting raw tokens
  - manual revocation
  - expiry
  - audit of who issued the invite
  - binding to a target `discord_user_id` when known

### Bot Operation Flow

1. A Discord user invokes a bot command.
2. The Discord Bot validates command syntax and forwards the request to Rails.
3. Rails authenticates the bot itself.
4. Rails resolves the acting Discord user by `discord_user_id`.
5. Rails applies server-level authorization.
6. Rails executes the requested lifecycle or RCON action.
7. Rails returns a bounded result for the bot to present back in Discord.

For future read-only bot operations, `reader` may access read surfaces only; write surfaces remain restricted above that user type.

## Security Boundaries

### Browser/User Boundary

- Discord OAuth proves the external identity of the browser user.
- Invite validation determines whether that identity may join the app.
- Rails session cookies represent authenticated browser sessions after successful login.

### Bot Boundary

- The bot is trusted only to relay commands to Rails, not to enforce final authorization.
- Rails must treat every bot request as untrusted until the bot credential is validated and the acting Discord user is resolved.
- The bot should supply the acting Discord user id with each request; Rails must not rely on Discord display names for authorization.
- `reader` should be able to use only read-class bot endpoints such as status and future player-count/log reads.
- `reader` must not gain lifecycle, command, invite, or create privileges through the bot path.

### Infrastructure Boundary

- Docker access remains isolated to Rails service objects.
- RCON access remains isolated to Rails service objects.
- Neither capability is delegated directly to Discord-facing infrastructure.

## Data Ownership Strategy

- `discord_user_id` is the external identity key.
- Invite issuance and redemption state belong to Rails.
- Server ownership and memberships remain local database concerns.
- Docker resource ownership remains local database plus managed Docker labels.
- RCON connection configuration belongs to Rails and should be stored with the same care level as other operational secrets.

## Implementation Order

1. `T-1000`: freeze this strategy and any related safety notes
2. `T-1001`: add Discord identity support and OAuth plumbing
3. `T-1002`: add manual invite issuance and token lifecycle
4. `T-1003`: replace local password-first login with Discord-only entry
5. `T-1004`: implement invite redemption and first-login linking
6. `T-1005`: define bot API trust boundary and command contract
7. `T-1006`: add Rails-owned RCON client and server configuration model
8. `T-1007`: implement bot-facing lifecycle and RCON endpoints
9. `T-1008`: add automated coverage
10. `T-1009`: write operator-facing setup and operations docs

## Open Follow-Up Questions

- Whether invites are always pre-bound to a single `discord_user_id` or may support an unbound first-claim mode
- What subset of RCON commands are safe to expose through the bot
- How bot-to-Rails authentication should be provisioned and rotated
- Whether local password columns are removed immediately or deprecated across an intermediate migration window
