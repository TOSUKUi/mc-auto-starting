# Repository Guidelines

## Purpose of This File
This file is the primary restart guide for contributors and agents. If context is lost, start here, then read `docs/context_map.md`, then `docs/project_execution_plan.md`, then `docs/task_board.md`.

## Current Project State
This repository contains a generated Rails 8 application skeleton plus planning and bootstrap documents. The project has pivoted away from the earlier `Pterodactyl Panel + Wings` direction and is now being planned as a single-host Minecraft server manager where Rails directly controls Docker through `/var/run/docker.sock` while continuing to use `mc-router` for single-port public routing.

Current important files:

- `README.md`
- `Dockerfile`
- `compose.yaml`
- `docs/single_host_setup.md`
- `docs/operator_runbook.md`
- `docs/discord_operator_runbook.md`
- `docs/release_runbook.md`
- `docs/kamal_deployment_topology.md`
- `config/deploy.yml`
- `config/deploy.production.yml`
- `docs/direct_docker_lifecycle_contract.md`
- `docs/direct_docker_env_contract.md`
- `docs/discord_auth_and_bot_strategy.md`
- `docs/discord_bot_api_contract.md`
- `docs/implementation_breakdown.md`
- `docs/access_policy_and_quota_contract.md`
- `docs/whitelist_and_access_control_strategy.md`
- `docs/player_observability_and_browser_console_contract.md`
- `docs/server_ui_display_review.md`
  This now also holds the next server-screen de-dup/layout cleanup plan for `T-508`.
- `docs/provider_cleanup_inventory.md`
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/context_map.md`

Current baseline:

- Docker bootstrap, DB readiness, and the Vite + Inertia + React + Mantine frontend baseline are complete through `T-005` and `T-004`.
- Authentication uses the Rails 8 built-in authentication generator baseline through `T-100` and `T-101`.
- Authorization and visibility protection are installed through `T-106` and `T-107`.
- The authenticated layout shell and basic login/index/create/detail/members pages already exist, and the active server create/detail/index screens now follow the direct-Docker baseline.
- Existing `mc-router` code remains part of the active architecture and should not be removed unless the user explicitly changes that decision.
- The selected Docker integration path is direct Engine API access via `/var/run/docker.sock` with a minimal Rails wrapper, not `docker` CLI orchestration.
- The planning pivot through `T-110` is complete.
- `T-200` is complete: `minecraft_servers` now carries direct-Docker baseline fields such as `container_name`, `container_id`, `volume_name`, `container_state`, and `last_started_at`, while router ingress remains active.
- `T-201` through `T-204` are complete: normalized hostname slugs, FQDN/connection-target formatting, status-transition rules, and retained `router_routes` publication responsibilities are now codified in shared helpers and models.
- `T-302` is complete: a minimal `DockerEngine` wrapper now talks to Docker over `/var/run/docker.sock` via Excon-based Unix socket HTTP transport.
- `T-302` defaults to unversioned Docker Engine API paths and only prefixes `/v1.xx` when `DOCKER_ENGINE_API_VERSION` is explicitly set.
- `T-303` is complete: route publication apply/rollback is now centralized so create/delete flows share one `mc-router` update path.
- `T-304` is complete: direct-Docker env defaults for Docker transport, public endpoint, runtime image/network, and router config are now fixed in code and docs.
- `T-400` is complete: create requests now provision managed Docker volume/container resources, start the container, persist runtime identifiers, and publish the router route.
- `T-400` now retries container create once by pulling the selected runtime image when Docker returns `No such image`.
- The direct-Docker lifecycle/delete contract is fixed in `docs/direct_docker_lifecycle_contract.md` before `T-401` / `T-402` implementation.
- `T-401` and `T-402` are complete: delete/start/stop/restart/sync now operate on managed Docker containers and volumes instead of the legacy provider path.
- `T-403` is complete: sync now reconciles `container_state`, `last_started_at`, and `last_error_message` from Docker inspect so runtime details stay aligned after manual syncs.
- `T-404` is complete: operator create requests are now quota-limited by owned `memory_mb` total `<= 5120`, the server-side create flow rejects over-quota requests, and the create UI shows current usage plus remaining quota.
- `T-500` is complete: create UI and controller props are reduced to the direct-Docker baseline inputs plus hostname/FQDN preview metadata.
- `T-501` and `T-502` are complete: detail/index UI now emphasize connection target and router publication instead of provider-era framing, while active screens no longer foreground Docker backend identifiers.
- `T-503` is in progress: operator-facing UI copy and layout polish are being shifted toward a simpler Japanese-first presentation; the root route now lands on the server index, the active app shell uses a flat Minecraft-inspired dark theme, the header now shows the signed-in user's global role, shared navigation/member/invite labels are Japanese-first, and current server forms enforce a 4GB memory cap plus hostname character restrictions in both JS and Rails validations.
- `T-505` is complete: the server index/detail display contract is fixed in `docs/server_ui_display_review.md`, and the active screens now follow that contract with Discord owner display, connection-first ordering, and lower-priority metadata pushed below the primary state/action area.
- `T-508` is complete: index/detail no longer show `応答状態` or router timestamp noise, and the detail layout now separates primary connection/action cues from ownership/version information and lower-priority technical metadata without repeating the same facts.
- `T-509` is complete: route publication failures are now audited against the rendered routes file and shown only when abnormal, instead of keeping router internals visible all the time.
- `T-510` is complete: transition-state polling now triggers backend reconciliation during detail-page polling, so `starting` / `stopping` / `restarting` can converge without manual sync.
- `T-511` is complete: publication-failure warnings now tell the user the next step, and authorized users can reapply publication directly from the server detail page.
- `T-205`, `T-700`, `T-702`, and `T-703` are complete: provider dependency inventory exists, provider services/initializer/tests are removed, and controller create flow now treats `template_kind` as internal schema debt instead of an exposed input.
- `T-701` is complete: legacy provider design docs remain only as historical references and are no longer part of the active restart workflow.
- `T-803` is complete: automated acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync paths against the direct-Docker baseline with router publication checks.
- `T-800` through `T-802` are complete: the direct-Docker baseline now has model, request/authorization, and Docker/router/server service coverage, so the earlier P7 test-hardening placeholders are no longer open.
- `T-804` is complete: compose-managed `mc-router` now runs on the shared bridge network and a live status ping through the shared public port reached a managed Minecraft container.
- `T-805` is complete: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after rewriting the routes file, so live ingress updates no longer depend on bind-mounted file-watch behavior.
- `T-900` is complete: `README.md` now points at a concrete single-host bootstrap path, and `docs/single_host_setup.md` documents the local `.env` setup, external network prerequisite, Dockerized boot flow, and bootstrap-owner seed path for new contributors.
- `T-904` is complete: `docs/kamal_deployment_topology.md` now fixes the single-host Kamal deployment shape, keeping MariaDB and Redis as Kamal accessories, `mc-router` as a long-lived sibling service, and deploy secrets outside Git while preserving the current env key names.
- `T-901` is complete: `docs/operator_runbook.md` now gives operators a current Compose-based single-host deployment procedure, host-side verification commands, direct-Docker lifecycle guidance, and explicit Docker safety notes.
- `T-905` is complete: the repository now includes `config/deploy.yml`, `config/deploy.production.yml`, `.kamal` secret templates and hooks, plus the `mc-router` deployment helper needed for the first Kamal-based single-host rollout.
- `T-902` is complete: `docs/release_runbook.md` now documents the Kamal-based release, migration, and rollback procedure for the current single-host deployment baseline.
- `T-1005` is complete: `docs/discord_bot_api_contract.md` now fixes the bot credential model, acting Discord-user resolution, allowed lifecycle/read/whitelist commands, request/response envelopes, and audit expectations before bot endpoint implementation.
- `T-1024` is complete: the bot contract now keeps whitelist mutations owner/admin-only, treats `whitelist_list` as a read-class surface, and separates bounded RCON input from lifecycle/server-operation commands so forbidden commands such as `stop` are never accepted through the RCON path.
- Bot API network policy is now fixed at the strategy layer: `/api/discord/bot/*` should be reachable only from the Docker private network, while still requiring the dedicated bot bearer token.
- Follow-up UI tasks for the server screens have been partially closed: `T-505`, `T-506`, and `T-507` are complete, and `docs/server_ui_display_review.md` remains the display-contract reference for future adjustments.
- `T-504` is complete: the server index now prefers the owner's Discord display identity over `email_address`, using `discord_global_name`, then `discord_username`, then a fixed fallback label.
- `T-506` is complete: server detail responses now gate lifecycle actions by current server status so `ready` only shows stop/restart, `stopped` shows start, and transitional/degraded states converge on sync-only controls.
- `T-507` is complete: the server detail page now polls only while `starting`, `stopping`, or `restarting`, and the status badge shows a simple spinner instead of timestamps or countdown-style progress.
- `T-1013` is complete: Discord OAuth now requests only `identify`, bootstrap/invite/login flows no longer persist email fields, and the remaining member-management UI resolves users by `discord_user_id` instead of email lookup.
- `T-1014` is complete: global user types, server-local `viewer` / `manager` roles, invitation authority, ownership-vs-membership authorization rules, and the operator-scoped `5120 MB` create quota now live in `docs/access_policy_and_quota_contract.md`.
- `T-1015` is complete: `users.user_type` now persists the global `admin` / `operator` / `reader` role, existing users are backfilled to `operator`, new users default to `reader`, bootstrap owner seeding assigns `admin`, and shared controller/policy code can resolve the global role independently from server membership.
- `T-1019` is complete: server-local membership terminology now uses `manager` instead of `operator`, so membership roles no longer collide with the global `operator` user type.
- `T-1016` is complete: invitation issuance now stores the invited global user type, admins can invite `admin` / `operator` / `reader`, operators can invite only `reader`, readers are denied at the policy/controller layer, and invite-based first login now applies the invited global role to the created user.
- `T-1017` is complete: server create authorization is now enforced at the policy/controller layer so `admin` and `operator` can open the create flow, while `reader` is denied before request handling reaches provisioning logic.
- `T-1018` is complete: server authorization now combines global type and server-local membership so `admin` has full visibility/management, `manager` membership grants lifecycle access, `viewer` grants read-only visibility, and destroy/member-management remain owner-or-admin only.
- `T-1020` is complete: whitelist planning now treats server whitelist changes as Rails-owned RCON operations, with the resulting contract fixed in `docs/whitelist_and_access_control_strategy.md`.
- `T-1006` is complete: Rails now has an app-owned RCON connection layer, managed containers enable RCON by default, and per-server RCON passwords are derived from a stable secret plus server identity instead of being stored as plain DB fields.
- `T-1007` is complete: Rails now has an internal-only `/api/discord/bot/*` surface gated to the Docker private network plus a dedicated bot bearer token, and the current implementation covers acting-user resolution, policy-checked status/lifecycle/whitelist endpoints, and owner/admin-only bounded RCON commands.
- `T-1008` is complete: automated coverage now exercises Discord OAuth login, invite redemption/rejection, bot network/token/user rejection, and the main bot status/lifecycle/whitelist/bounded-RCON flows.
- `T-1009` is complete: the repository now includes `docs/discord_operator_runbook.md`, which gives operators one place to configure Discord OAuth, issue invite URLs, and run the internal bot relay safely.
- `T-1010` is complete: `docs/player_observability_and_browser_console_contract.md` now fixes the source of truth, refresh behavior, authorization, and payload contracts for player count, recent logs, and owner/admin-only browser bounded RCON input before UI work starts.
- Managed runtime env now also defaults `ENABLE_WHITELIST=TRUE`, so newly provisioned servers enforce whitelist mode from first boot.
- `T-1021` is complete: Rails now has a bounded whitelist service over RCON for list/add/remove/on/off/reload operations against running managed servers, explicitly loads `rconrb`, and authenticates with the Minecraft-compatible `ignore_first_packet` handling.
- `T-1022` is complete: whitelist endpoints are now controller/policy-gated to admins and owners, and request/service coverage includes unauthorized access plus stopped-server and RCON-failure handling.
- `T-1023` is complete: server detail now includes an owner/admin whitelist card backed by persisted desired whitelist state; running servers apply changes immediately through RCON, stopped servers stage changes that are applied on the next start because `StartServer` recreates the container with current env, the detail page no longer re-fetches whitelist data on every render, whitelist mutations now re-sync only the whitelist card while safely rejecting non-JSON restart/redirect responses, and whitelist entries are shown with code-like monospace styling to reduce case-misread risk.
- `T-1025` is complete: raw-socket verification showed this Minecraft runtime returns a single auth packet, so RCON auth now uses `ignore_first_packet: false`; `WhitelistManager` now reads response bodies instead of object inspection; `start` and `restart` both recreate the managed container so saved whitelist env is reapplied; live verification against `muuchannel` confirmed DB state, `WHITELIST`, `/data/whitelist.json`, and RCON `whitelist list` can agree; and immediate-apply failures now return a clear saved-but-not-live-applied message.
- After the P8 docs track, the planned next feature track is `T-1000` through `T-1009` for Discord OAuth invites and Discord Bot mediated server operations.
- `T-1000` is complete: the strategy contract for Discord OAuth-only login, manual invite URLs, and Discord Bot to Rails to RCON operations now lives in `docs/discord_auth_and_bot_strategy.md`.
- `T-1001` is complete: `User` now has Discord identity fields and Rails can complete Discord OAuth callbacks for already-linked users while invite gating remains future work.
- `T-1002` is complete: authenticated users can issue Discord-user-bound invite records, see invite status in the app, copy the raw invite URL at creation time, and revoke issued invites without email delivery.
- `T-1003` is complete: `/login` now serves as a Discord-only entry page for existing users, a Rails-owned `/discord/login` handoff guards the Discord OAuth start path, local password and password-reset routes are no longer part of the active path, and bootstrap-owner startup logs can point the initial operator at the first `/login` link.
- `T-1004` is complete: `/invites/:token` now stores pending invite context, Discord OAuth callbacks can create the first linked local user from a matching invite, and consumed invites are marked used.
- After the Discord bot/RCON track, the next planned operator UI work is `T-1011` and `T-1012` for player-count visibility and browser-side log / command operations.
- `T-1101` is complete: create flow now exposes runtime family selection with `paper` as the default, and both `paper` and `vanilla` provision through the `itzg/minecraft-server` runtime family.
- `T-1100` and `T-1103` are complete: a checked-in synchronized catalog file remains as the safe fallback instead of live registry access or DB-backed storage.
- `T-1105` through `T-1107` are complete: the create UI now resolves version options server-side on page load, caches them briefly, falls back to the checked-in catalog, and exposes only the runtime-family-specific select choices without a freeform version field.
- Index/detail screens now surface both Minecraft version and runtime `Type` so the current `paper` / `vanilla` selection is visible outside the create flow.
- Runtime catalog option `label` is the user-facing Minecraft version display, while submitted `value` is the stable version key sent through the runtime `VERSION` contract.
- `T-1102` is complete: create flow now persists resolved Minecraft version metadata so symbolic selections such as `latest` can be shown as concrete numeric versions on index/detail screens.
- Important runtime nuance: `itzg/minecraft-server` should be treated as a `TYPE` + `VERSION` driven image family, not as a runtime where image tag always equals the Minecraft version; use the official docs page `https://docker-minecraft-server.readthedocs.io/en/latest/versions/minecraft/` as the source of truth for that distinction.
- The active live sources are Mojang's `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` for `vanilla` and `https://qing762.is-a.dev/api/papermc` for `paper`, resolved by Rails on create-page load with a short TTL cache and a checked-in fallback catalog.

The initial Discord owner can be bootstrapped with `BOOTSTRAP_DISCORD_USER_ID=... bin/rails db:seed`; once Discord OAuth is configured, use the startup `/login` hint to complete the first sign-in and issue invite URLs.

## Locked Technical Decisions
These are already decided and should be treated as defaults unless explicitly changed.

- App role: Rails control plane for single-host Minecraft server lifecycle management
- Runtime: Docker-first workflow
- Docker control path: Rails may control Docker directly through mounted `/var/run/docker.sock`
- Topology: single host only in the initial version
- Router/container topology: `mc-router` and app-managed Minecraft containers share one bridge network
- `mc-router` itself is managed by `compose.yaml`, not created or lifecycle-managed by Rails
- `compose.yaml` defines a compose-managed `mc-router` service that publishes `${MINECRAFT_PUBLIC_PORT}:25565`
- `compose.yaml` attaches `mc-router` to the external shared network `${MINECRAFT_RUNTIME_NETWORK_NAME}`
- `compose.yaml` labels the `mc-router` service with `app.kubos.dev/component=mc-router` so Rails can target reload signals without relying on generated container names
- Ruby: `3.4.9`
- Rails: `8.1.2`
- Database: MariaDB `10.11.16` (via `mysql2` adapter)
- Cache / queue support candidate: Redis `7`
- Frontend architecture: Rails + Inertia.js + React
- UI library: Mantine `8.3.1`
- UI language policy: default `ja`, optional `en`, with Rails I18n as the source of truth
- Frontend bundler: `vite_rails` + Vite
- Authentication target direction: Discord OAuth2 only
- Account onboarding direction: manually issued invite URLs
- User-type hierarchy direction: `admin` / `operator` / `reader`
- Server-membership vocabulary direction: `viewer` / `manager`
- Bot integration direction: Discord Bot calls Rails-owned APIs
- Minecraft command operation direction: Rails executes lifecycle/RCON actions; bots must not talk directly to Docker or server containers
- Server creation quota direction: `admin` is unrestricted, `operator` is limited by summed owned `memory_mb <= 5120`, and `reader` cannot create servers
- Minecraft runtime image family: `itzg/minecraft-server`
- `paper` and `vanilla` both run on `itzg/minecraft-server`, selected through `TYPE=PAPER` or `TYPE=VANILLA`
- The create-form `minecraft_version` field is treated as runtime-version input and is passed through the container `VERSION` environment contract rather than mapped to a Docker image tag
- `MEMORY` should leave JVM headroom below the Docker memory limit
- Public connection format: `<server-fqdn>:<shared_public_port>`
- Public ingress port: single shared public port
- Router backend format: `<container_name>:25565` on the shared bridge network
- DNS automation: out of scope
- SRV record operations: out of scope
- Pterodactyl / Wings integration: not part of the active plan
- mc-router integration: part of the active plan

## Architecture Summary
The active system has four parts.

- Control plane: Rails, Inertia.js, React, Mantine UI, auth, authorization, Docker orchestration
- Execution plane: Docker Engine on the same host
- Routing plane: `mc-router` on the same host, exposing a single public port and dispatching by hostname
- Runtime plane: Minecraft server containers created and managed by Rails

## Repository Structure

- `app/controllers/` : Rails controllers
- `app/models/` : Active Record models
- `app/policies/` : authorization policies
- `app/services/` : Docker orchestration and server lifecycle services
- `app/jobs/` : async jobs
- `app/javascript/` : Inertia + React frontend
- `docs/` : persistent design, plans, decision docs, task tracking
- `.local/` : non-versioned scratch notes and per-session restart context

## Required Reading Order After Context Reset
1. `AGENTS.md`
2. `docs/context_map.md`
3. `docs/project_execution_plan.md`
4. `docs/task_board.md`
5. `docs/implementation_breakdown.md`
6. `docs/access_policy_and_quota_contract.md`
7. `docs/whitelist_and_access_control_strategy.md`
8. `docs/server_ui_display_review.md`
9. `docs/provider_cleanup_inventory.md`
10. `docs/single_host_setup.md`
11. `docs/operator_runbook.md`
12. `docs/release_runbook.md`
13. `docs/kamal_deployment_topology.md`
14. `config/deploy.yml`
15. `config/deploy.production.yml`
16. `docs/direct_docker_env_contract.md`
17. `docs/direct_docker_lifecycle_contract.md`
18. `docs/discord_auth_and_bot_strategy.md`

## Execution Rules
Follow these rules unless the user overrides them.

- Use Docker for Ruby and Rails commands.
- Prefer Rails generators before manual scaffolding.
- Prefer Rails-standard autoloading, reloading, initializer, and configuration patterns over manual `require`/load workarounds.
- Keep Docker control isolated behind small service classes.
- Never let Rails operate on Docker resources that are not explicitly labeled as app-managed.
- Show end users the exact connection target as `<server-fqdn>:<shared_public_port>`.
- Restrict visibility so users only see servers they own or belong to.
- Before implementing a feature that depends on managed-container env or runtime toggles, verify the end-to-end behavior of the underlying image/runtime contract first; do not assume that storing data or exposing UI alone is sufficient if the runtime feature flag itself may still be disabled.
- Treat `/var/run/docker.sock` access as high risk and document it clearly.
- Keep `DOCKER_ENGINE_API_VERSION` unset by default unless a deployment needs an explicit Engine API override.
- When touching a flow that still references provider-specific concepts, prefer removing those references as part of the same progress step instead of leaving dead compatibility layers behind.
- Preserve `mc-router`-based single-port routing unless the user explicitly instructs otherwise.
- Router config writes should treat explicit `SIGHUP` reload of the compose-managed `mc-router` container as the default baseline; do not rely on bind-mounted file-watch pickup.
- Do not add monitoring dashboards or audit-log screens unless the user explicitly reintroduces them.
- UI copy should default to Japanese, while remaining compatible with English via shared locale handling.

## Build and Bootstrap Commands
Use these as the default command set.

- `export LOCAL_UID=$(id -u) LOCAL_GID=$(id -g) DOCKER_GID=$(grep '^docker:' /etc/group | cut -d: -f3)` if your host user is not `1000:1000` or the Docker group differs
- `docker compose build app`
- `docker compose up --build`
- `docker compose run --rm app bin/rails db:prepare`
- `docker compose run --rm -p 3000:3000 -p 3036:3036 app bin/dev`
- `docker compose run --rm app bin/rails test`

- `.env` now carries the local default `LOCAL_UID`, `LOCAL_GID`, `DOCKER_GID`, `MINECRAFT_RUNTIME_IMAGE`, and `MINECRAFT_RUNTIME_VANILLA_IMAGE` values used by Compose.
- `.env.example` is the checked-in template for those values; keep the real `.env` local and out of Git, treat it as the single local source for Compose, Discord OAuth, bootstrap-owner, and future bot secrets, and leave only the current local/bootstrap baseline uncommented while keeping non-required variables as commented examples.
- If the host user or Docker socket group differs, update `.env` before running Compose.
Do not install Ruby gems on the host unless there is an explicit exception.
Keep gems in `vendor/bundle` inside the workspace so the mapped app user can write them.
`bin/dev` includes a fallback path that starts Rails and Vite directly when `foreman` is not installed in the container.

## Browser Verification Notes
- For Playwright MCP quality checks, confirm reachability from the MCP runtime, not only from inside the `app` container.
- Before starting a new Dockerized Rails/Vite dev process for browser checks, first confirm whether an existing reachable app instance is already serving the target URL and reuse it if healthy.
- In the current Docker setup, the reliable browser target was `http://172.17.0.1:3000`.

## Coding and Naming Conventions
- Indentation: 2 spaces for Ruby, YAML, ERB, JS, and TS
- Ruby files and methods: snake_case
- Classes and React components: PascalCase
- Controllers: plural names such as `ServersController`
- Service objects: action-oriented names such as `Servers::CreateServer`
- Prefer small service classes over large controllers
- Prefer explicit policy checks over implicit access assumptions

## Progress Management Rules
All contributors and sub-agents must use `docs/task_board.md` as the shared task system.

- Do not invent ad hoc task IDs
- Update task status using the existing task IDs
- If a new task is needed, add it under the correct phase and define dependency IDs
- Mark blockers explicitly
- Keep progress reporting tied to task IDs, not vague prose only
- After each meaningful progress step, sync committed restart docs before ending the work block
- Minimum sync set after each progress step: `AGENTS.md`, `docs/task_board.md`, `docs/context_map.md`
- Update `docs/project_execution_plan.md` when dependencies, ordering, or critical path change
- Update `.local/session_context.md` for temporary restart notes that should not be committed
- After each meaningful progress step, create a git commit unless the user explicitly says not to
- Each progress-step commit must include both the implementation change and the matching restart-doc updates for that step
- Commit messages should reference the task ID first
- Do not batch unrelated task progress into one commit when separate commits are practical
- Do not leave the repository in a state where the current task status and the restart docs disagree

## Immediate Next Start Point
If no other instruction is given, start from the current critical path:

1. `T-200` through `T-400` are complete
2. `T-205`, `T-700`, `T-702`, `T-703`, `T-803`, `T-804`, and `T-805` are complete while keeping `mc-router`
3. `T-900`, `T-901`, `T-903`, `T-904`, and `T-905` are complete
4. Next, continue from `T-1011` on the operator-facing player-count/browser-console track
