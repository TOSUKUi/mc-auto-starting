# Repository Guidelines

## Purpose of This File
This file is the primary restart guide for contributors and agents. If context is lost, start here, then read `docs/context_map.md`, then `docs/project_execution_plan.md`, then `docs/task_board.md`.

## Current Project State
This repository contains a generated Rails 8 application skeleton plus planning and bootstrap documents. The project has pivoted away from the earlier `Pterodactyl Panel + Wings` direction and is now being planned as a single-host Minecraft server manager where Rails directly controls Docker through `/var/run/docker.sock` while continuing to use `mc-router` for single-port public routing.

Current important files:

- `Dockerfile`
- `compose.yaml`
- `docs/direct_docker_env_contract.md`
- `docs/implementation_breakdown.md`
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/context_map.md`

Current baseline:

- Docker bootstrap, DB readiness, and the Vite + Inertia + React + Mantine frontend baseline are complete through `T-005` and `T-004`.
- Authentication uses the Rails 8 built-in authentication generator baseline through `T-100` and `T-101`.
- Authorization and visibility protection are installed through `T-106` and `T-107`.
- The authenticated layout shell and basic login/index/create/detail/members pages already exist, but they still contain legacy provider/router assumptions and are now subject to simplification.
- Existing provider code remains in the repository as migration debt and is expected to be removed progressively.
- Existing `mc-router` code remains part of the active architecture and should not be removed unless the user explicitly changes that decision.
- The selected Docker integration path is direct Engine API access via `/var/run/docker.sock` with a minimal Rails wrapper, not `docker` CLI orchestration.
- The planning pivot through `T-110` is complete.
- `T-200` is complete: `minecraft_servers` now carries direct-Docker baseline fields such as `container_name`, `container_id`, `volume_name`, `container_state`, and `last_started_at`, while router ingress remains active.
- `T-201` through `T-204` are complete: normalized hostname slugs, FQDN/connection-target formatting, status-transition rules, and retained `router_routes` publication responsibilities are now codified in shared helpers and models.
- `T-302` is complete: a minimal `DockerEngine` wrapper now talks to Docker over `/var/run/docker.sock` via Excon-based Unix socket HTTP transport.
- `T-303` is complete: route publication apply/rollback is now centralized so create/delete flows share one `mc-router` update path.
- `T-304` is complete: direct-Docker env defaults for Docker transport, public endpoint, runtime image/network, and router config are now fixed in code and docs.
- `T-400` is complete: create requests now provision managed Docker volume/container resources, start the container, persist runtime identifiers, and publish the router route.
- The next implementation critical-path task is `T-402`.

Development seed login is available as `dev@example.com` / `password`.

## Locked Technical Decisions
These are already decided and should be treated as defaults unless explicitly changed.

- App role: Rails control plane for single-host Minecraft server lifecycle management
- Runtime: Docker-first workflow
- Docker control path: Rails may control Docker directly through mounted `/var/run/docker.sock`
- Topology: single host only in the initial version
- Router/container topology: `mc-router` and app-managed Minecraft containers share one bridge network
- Ruby: `3.4.9`
- Rails: `8.1.2`
- Database: MariaDB `10.11.16` (via `mysql2` adapter)
- Cache / queue support candidate: Redis `7`
- Frontend architecture: Rails + Inertia.js + React
- UI library: Mantine `8.3.1`
- UI language policy: default `ja`, optional `en`, with Rails I18n as the source of truth
- Frontend bundler: `vite_rails` + Vite
- Minecraft runtime image family: `itzg/minecraft-server`
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
6. `docs/direct_docker_env_contract.md`

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
- When touching a flow that still references provider-specific concepts, prefer removing those references as part of the same progress step instead of leaving dead compatibility layers behind.
- Preserve `mc-router`-based single-port routing unless the user explicitly instructs otherwise.
- Do not add monitoring dashboards or audit-log screens unless the user explicitly reintroduces them.
- UI copy should default to Japanese, while remaining compatible with English via shared locale handling.

## Build and Bootstrap Commands
Use these as the default command set.

- `export LOCAL_UID=$(id -u) LOCAL_GID=$(id -g)` if your host user is not `1000:1000`
- `docker compose build app`
- `docker compose up --build`
- `docker compose run --rm app bin/rails db:prepare`
- `docker compose run --rm -p 3000:3000 -p 3036:3036 app bin/dev`
- `docker compose run --rm app bin/rails test`

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
2. Implement the direct-Docker lifecycle and delete flows while keeping `mc-router`
3. Remove provider coupling after the direct-Docker path is working end to end
