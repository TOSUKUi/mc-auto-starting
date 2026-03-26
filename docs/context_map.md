# Context Map

## Purpose
This file tells any contributor or agent where to find authoritative information after a context reset.

## Read First
- `AGENTS.md`

## Architecture and Implementation Design
- `docs/implementation_breakdown.md`
  Use for the active `Rails + docker.sock` single-host architecture, screen list, data model, and service decomposition.
- `docs/provider_cleanup_inventory.md`
  Use for the legacy provider dependency inventory and the remaining schema/doc cleanup debt after `T-700` / `T-702` / `T-703`.
- `docs/docker_engine_contract.md`
  Use for the direct Docker Engine wrapper scope, shared bridge network rules, and managed resource conventions.
- `docs/direct_docker_env_contract.md`
  Use for the required env vars and config defaults for Docker transport, public endpoint rendering, runtime image, and router publication.
- `docs/direct_docker_lifecycle_contract.md`
  Use for the direct-Docker lifecycle, sync, and delete contract before implementing `T-401` through `T-403`.
- `docs/discord_auth_and_bot_strategy.md`
  Use for the authoritative Discord OAuth, manual invite URL, and Discord Bot to Rails to RCON strategy fixed by `T-1000`.
- `docs/project_execution_plan.md`
  Use for the active phase ordering, dependency flow, milestones, and critical path.
- `docs/task_board.md`
  Use for the active `direct-Docker + mc-router` task system.

## Historical / Superseded References
- `docs/provider_api_contract.md`
  Historical reference from the abandoned Pterodactyl/Wings approach. Not current architecture.
- `docs/provider_template_env_setup.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/provider_router_operations.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/router_api_contract.md`
  Active reference for the retained `mc-router` ingress contract.

## Disposable Session Context
- `.local/session_context.md`
  Use for temporary restart notes, recent findings, in-flight command plans, and handoff notes that should not be committed.

## Bootstrap / Environment Files
- `Dockerfile`
- `compose.yaml`
- `.env`
- `.env.example`
- `.gitignore`

## Current Start State
- Rails application skeleton has been generated in-place.
- Docker bootstrap exists.
- MariaDB `10.11.16` is the chosen database runtime.
- Mantine version target is `8.3.1`.
- UI language policy is `ja` by default with optional `en`, backed by Rails I18n.
- Frontend bundler choice is `Vite` via `vite_rails`.
- The development `app` container is expected to run as the host UID/GID.
- `bin/dev` works in Docker without `foreman` by falling back to direct Rails + Vite startup.
- Bootstrap is complete through `T-005`.
- Authentication baseline is installed through `T-100` and `T-101`.
- `MinecraftServer` and `ServerMember` baselines exist through `T-102` and `T-103`.
- Authorization and visibility protection are installed through `T-106` and `T-107`.
- Authenticated layout and current login/index/create/detail/members UI baselines already exist; the active server create/detail/index screens are direct-Docker-first.
- The planning pivot task `T-110` is complete.
- `T-200` is complete: `minecraft_servers` now has direct-Docker baseline fields for managed container/volume identity and runtime state.
- `T-201` through `T-204` are complete: hostname slug normalization, FQDN/public-port connection formatting, status transitions, and `router_routes` publication responsibilities are fixed in code.
- `T-302` is complete: Docker Engine access is wrapped behind `DockerEngine::Connection`, `DockerEngine::Client`, `DockerEngine::ManagedLabels`, and `DockerEngine::ManagedName`.
- `T-302` defaults to unversioned Docker Engine API paths so local daemons do not need to support a hard-coded minimum API version.
- The active architecture is now `Rails + docker.sock + mc-router` for single-host Minecraft container management.
- `Pterodactyl/Wings` are no longer the current target architecture, but `mc-router` remains active.
- `mc-router` and app-managed Minecraft containers are expected to share one bridge network, with router backends addressed by container name.
- `T-303` is complete: route publication apply/rollback is centralized and reused by the existing create/delete-era services.
- `T-304` is complete: Docker transport, public endpoint, runtime image/network, `marctv` create payload, and router file/reload defaults are fixed in env-backed helpers and docs.
- The create-form `minecraft_version` field now represents the selected `marctv` image tag, and the UI exposes it as a fixed select list.
- `MinecraftRuntime` now derives `MEMORYSIZE` below the Docker limit so the container keeps JVM headroom.
- Local Compose bootstrap now includes checked-in `.env` defaults for `LOCAL_UID`, `LOCAL_GID`, `DOCKER_GID`, and `MINECRAFT_RUNTIME_IMAGE`.
- `T-400` is complete: the create job now provisions managed Docker resources, persists runtime state, and publishes the `mc-router` mapping.
- `T-400` now pulls the selected runtime image on demand when Docker create fails with `No such image`.
- The direct-Docker lifecycle/delete contract is now fixed in `docs/direct_docker_lifecycle_contract.md` ahead of service replacement work.
- `T-401` and `T-402` are complete: delete/start/stop/restart/sync now use Docker Engine instead of the legacy provider path.
- `T-500` is complete: create UI now exposes only the direct-Docker baseline inputs and the public connection preview contract.
- `T-501` and `T-502` are complete: detail/index UI now center connection targets and publication data, while current active screens de-emphasize Docker backend identifiers.
- `T-503` is in progress: operator-facing copy and layout polish are being moved further toward a Japanese-first, simpler presentation; the unused home page has been removed in favor of routing `/` to the server index, the active app shell now uses a flat Minecraft-inspired dark theme, and the server create form now caps memory at 4GB while blocking invalid hostname characters earlier.
- `T-205`, `T-700`, `T-702`, and `T-703` are complete: provider inventory is documented, provider services/initializer/tests are removed, and create requests no longer expose provider-era template input.
- `T-803` is complete: acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync paths against the direct-Docker baseline.
- `compose.yaml` now defines a compose-managed `mc-router` service on the shared `mc_router_net` bridge network.
- `T-804` is complete: a live status ping through the shared public port reached a managed Minecraft server after `mc-router` loaded the generated routes.
- `T-805` is complete: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after route rewrites, so live ingress updates no longer depend on bind-mounted file-watch behavior.
- The next implementation critical path starts at `T-900`, then `T-903` / `T-904` / `T-905` to align `.env`, `.env.example`, and the Kamal deploy baseline before the remaining P8 ops docs; after the Discord bot/RCON track, operator-facing player-count and browser-console tasks continue at `T-1010` through `T-1012`.
- A later runtime-catalog track is planned at `T-1100` through `T-1103` to cover Java runtime family selection, `latest` version resolution, and dynamic or synchronized version-choice sourcing.
- The selected future auth direction is Discord OAuth-only login plus manually issued invite URLs, not distributed local passwords.
- The selected future bot direction is Discord Bot -> Rails API -> lifecycle/RCON execution, not direct bot access to Docker or containers.
- `docs/discord_auth_and_bot_strategy.md` is the strategy-level source of truth for the future Discord auth and bot track.
- `T-1001` is complete: `users` now store Discord identity fields, OmniAuth Discord is wired into the app, and linked users can complete the Discord OAuth callback into a normal Rails session.
- `T-1002` is complete: `discord_invitations` now stores digest-backed manual invite records, authenticated users can issue/revoke invites from `/discord-invitations`, and raw invite URLs are shown only at issuance time.
- `T-1004` is complete: invite redemption now starts at `/invites/:token`, pending invite tokens are held in the Rails session, and Discord OAuth callbacks can create/link the invited user on first login.
- Initial operator bootstrap should use `BOOTSTRAP_DISCORD_USER_ID=... bin/rails db:seed` to create the first Discord-linked user before invite-based onboarding takes over.
- Local configuration should now be driven from `.env`, using `.env.example` as the checked-in template; required local/bootstrap keys stay active there, while non-required Discord, bot, router-command, and deploy-era examples stay commented until needed.
