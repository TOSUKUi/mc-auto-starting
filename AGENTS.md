# Repository Guidelines

## Purpose of This File
This file is the primary restart guide for contributors and agents. If context is lost, start here, then read `docs/context_map.md`, then `docs/project_execution_plan.md`, then `docs/task_board.md`.

## Current Project State
This repository contains a generated Rails 8 application skeleton plus planning and bootstrap documents. The project has pivoted away from the earlier `Pterodactyl Panel + Wings` direction and is now being planned as a single-host Minecraft server manager where Rails directly controls Docker through `/var/run/docker.sock` while continuing to use `mc-router` for single-port public routing.

Current important files:

- `Dockerfile`
- `compose.yaml`
- `docs/direct_docker_lifecycle_contract.md`
- `docs/direct_docker_env_contract.md`
- `docs/discord_auth_and_bot_strategy.md`
- `docs/implementation_breakdown.md`
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
- `T-500` is complete: create UI and controller props are reduced to the direct-Docker baseline inputs plus hostname/FQDN preview metadata.
- `T-501` and `T-502` are complete: detail/index UI now emphasize connection target and router publication instead of provider-era framing, while active screens no longer foreground Docker backend identifiers.
- `T-503` is in progress: operator-facing UI copy and layout polish are being shifted toward a simpler Japanese-first presentation, the root route now lands on the server index, the active app shell uses a flat Minecraft-inspired dark theme instead of gradient-heavy panels, and current server forms now enforce a 4GB memory cap plus hostname character restrictions in both JS and Rails validations.
- `T-205`, `T-700`, `T-702`, and `T-703` are complete: provider dependency inventory exists, provider services/initializer/tests are removed, and controller create flow now treats `template_kind` as internal schema debt instead of an exposed input.
- `T-803` is complete: automated acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync paths against the direct-Docker baseline with router publication checks.
- `T-804` is complete: compose-managed `mc-router` now runs on the shared bridge network and a live status ping through the shared public port reached a managed Minecraft container.
- `T-805` is complete: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after rewriting the routes file, so live ingress updates no longer depend on bind-mounted file-watch behavior.
- The next implementation critical-path tasks are `T-900`, `T-903`, `T-904`, `T-901`, `T-905`, and `T-902`.
- After the P8 docs track, the planned next feature track is `T-1000` through `T-1009` for Discord OAuth invites and Discord Bot mediated server operations.
- `T-1000` is complete: the strategy contract for Discord OAuth-only login, manual invite URLs, and Discord Bot to Rails to RCON operations now lives in `docs/discord_auth_and_bot_strategy.md`.
- `T-1001` is complete: `User` now has Discord identity fields and Rails can complete Discord OAuth callbacks for already-linked users while invite gating remains future work.
- `T-1002` is complete: authenticated users can issue Discord-user-bound invite records, see invite status in the app, copy the raw invite URL at creation time, and revoke issued invites without email delivery.
- `T-1004` is complete: `/invites/:token` now stores pending invite context, Discord OAuth callbacks can create the first linked local user from a matching invite, and consumed invites are marked used.
- After the Discord bot/RCON track, the next planned operator UI work is `T-1010` through `T-1012` for player-count visibility and browser-side log / command operations.
- `T-1101` is complete: create flow now exposes runtime family selection with `paper` as the default, and both `paper` and `vanilla` provision through the `itzg/minecraft-server` runtime family.
- `T-1100` and `T-1103` are complete: a checked-in synchronized catalog file remains as the safe fallback instead of live registry access or DB-backed storage.
- `T-1105` through `T-1107` are complete: the create UI now resolves version options server-side on page load, caches them briefly, falls back to the checked-in catalog, and exposes only the runtime-family-specific select choices without a freeform version field.
- Runtime catalog option `label` is the user-facing Minecraft version display, while submitted `value` is the stable version key sent through the runtime `VERSION` contract.
- The remaining runtime-catalog follow-up is `T-1102` for concrete version resolution for symbolic tags such as `latest`.
- Important runtime nuance: `itzg/minecraft-server` should be treated as a `TYPE` + `VERSION` driven image family, not as a runtime where image tag always equals the Minecraft version; use the official docs page `https://docker-minecraft-server.readthedocs.io/en/latest/versions/minecraft/` as the source of truth for that distinction.
- The active live sources are Mojang's `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` for `vanilla` and `https://qing762.is-a.dev/api/papermc` for `paper`, resolved by Rails on create-page load with a short TTL cache and a checked-in fallback catalog.

Development seed login is available as `dev@example.com` / `password`.
The initial Discord owner can be bootstrapped with `BOOTSTRAP_DISCORD_USER_ID=... bin/rails db:seed`; use this before the Discord-only login flow replaces the local password baseline.

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
- Bot integration direction: Discord Bot calls Rails-owned APIs
- Minecraft command operation direction: Rails executes lifecycle/RCON actions; bots must not talk directly to Docker or server containers
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
6. `docs/provider_cleanup_inventory.md`
7. `docs/direct_docker_env_contract.md`
8. `docs/direct_docker_lifecycle_contract.md`
9. `docs/discord_auth_and_bot_strategy.md`

## Execution Rules
Follow these rules unless the user overrides them.

- Use Docker for Ruby and Rails commands.
- Prefer Rails generators before manual scaffolding.
- Prefer Rails-standard autoloading, reloading, initializer, and configuration patterns over manual `require`/load workarounds.
- Keep Docker control isolated behind small service classes.
- Never let Rails operate on Docker resources that are not explicitly labeled as app-managed.
- Show end users the exact connection target as `<server-fqdn>:<shared_public_port>`.
- Restrict visibility so users only see servers they own or belong to.
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
3. Next, add the remaining single-host setup and direct-Docker operations docs
4. After `T-900` through `T-902`, start the Discord auth/invite/bot track at `T-1000`
