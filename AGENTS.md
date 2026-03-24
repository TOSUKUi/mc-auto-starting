# Repository Guidelines

## Purpose of This File
This file is the primary restart guide for contributors and agents. If context is lost, start here, then read `docs/context_map.md`, then `docs/project_execution_plan.md`, then `docs/task_board.md`.

## Current Project State
This repository now has a generated Rails 8 application skeleton plus planning and bootstrap documents. Bootstrap cleanup and environment alignment are still in progress. Current important files:

- `Dockerfile`
- `compose.yaml`
- `docs/implementation_breakdown.md`
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/context_map.md`
- `docs/provider_api_contract.md`
- `docs/router_api_contract.md`

A Rails app skeleton has already been generated in-place. Environment cleanup, DB readiness, and the Vite + Inertia + React + Mantine frontend baseline are complete through `T-005` and `T-004`. Authentication now uses the Rails 8 built-in authentication generator baseline through `T-100` and `T-101`, and the login page UI is installed through `T-601`. Authorization now uses a Pundit baseline through `T-106`, server visibility/request protection is installed through `T-107`, the authenticated layout shell is installed through `T-600`, the server index page UI is installed through `T-602`, the server creation page UI is installed through `T-603`, and the members management page UI is installed through `T-605`. The execution-provider contract is now fixed through `T-300` on a `Pterodactyl Panel + Wings` baseline, with the detailed API split captured in `docs/provider_api_contract.md`. The provider base client contract, concrete Pterodactyl HTTP client, and environment-driven initialization are now installed through `T-301`, `T-302`, and `T-303`, including Zeitwerk-compatible service objects, request/result value objects, error mapping, power/status calls, and provider config bootstrap. The provider-backed create job flow is now wired end-to-end through `T-501`, including provisioning template resolution, provider create, backend/identifier persistence, router config apply, and `ready` transition on success. The `MinecraftServer` model baseline is in place through `T-102`, hostname normalization, uniqueness, shared endpoint formatting, and status transition rules are fixed through `T-203`, the `ServerMember` model baseline is installed through `T-103`, the `RouterRoute` baseline is installed through `T-104`, and the `AuditLog` baseline is installed through `T-105`. The mc-router contract is now fixed through `T-400` in `docs/router_api_contract.md`, and the route definition builder, config renderer, and config applier baselines are installed through `T-401`, `T-402`, and `T-403`. The current critical path now moves into `T-700`, `T-701`, and `T-702`, while `T-502` remains pending for rollback hardening.
Development seed login is available as `dev@example.com` / `password`.

## Locked Technical Decisions
These are already decided and should be treated as defaults unless explicitly changed.

- App role: Rails control plane for Minecraft server lifecycle and publication management
- Runtime: Docker-first workflow
- Dev container user mapping: the `app` container runs as the host UID/GID in local development
- Ruby: `3.4.9`
- Rails: `8.1.2`
- Database: MariaDB `10.11.16` (via `mysql2` adapter)
- Cache / queue support candidate: Redis `7`
- Frontend architecture: Rails + Inertia.js + React
- UI library: Mantine `8.3.1`
- UI language policy: default `ja`, optional `en`, with Rails I18n as the source of truth
- Frontend bundler: `vite_rails` + Vite
- Public routing: `mc-router`
- Public DNS model: wildcard `*.mc.tosukui.xyz`
- Public connection format: `hostname:port`
- DNS automation: not allowed
- SRV record operations: not allowed
- Direct backend publish: not allowed
- Per-server public port allocation: not allowed
- Rails direct Docker control of Minecraft servers: not allowed
- Execution platform control path: external provider API only

Mantine version was checked from npm latest tag and is fixed here as `8.3.1` for bootstrap planning. If package installation starts much later, verify again before pinning `package.json`.
Source used for that decision: npm package page for `@mantine/core`.

## Architecture Summary
The system has four planes.

- Control plane: Rails, Inertia.js, React, Mantine UI, auth, authorization, audit logs, route generation, provider API orchestration
- Execution plane: existing Minecraft execution platform, responsible for actual server processes, logs, backups, templates, lifecycle
- Routing plane: `mc-router`, responsible for hostname-based backend routing from Minecraft Java handshake
- Network edge: home router with a single forwarded TCP port to the mc-router host

## Repository Structure
Use these paths once implementation begins.

- `app/controllers/` : Rails controllers
- `app/models/` : Active Record models
- `app/policies/` : authorization policies
- `app/services/` : provider, router, lifecycle, and monitoring services
- `app/jobs/` : async jobs
- `app/frontend/` : Inertia + React frontend
- `docs/` : persistent design, plans, decision docs, task tracking
- `.local/` : non-versioned scratch notes and per-session restart context

## Required Reading Order After Context Reset
1. `AGENTS.md`
2. `docs/context_map.md`
3. `docs/project_execution_plan.md`
4. `docs/task_board.md`
5. `docs/implementation_breakdown.md`

That order is intentional: orientation, where information lives, overall plan, concrete tasks, then detailed implementation design.

## Execution Rules
Follow these rules unless the user overrides them.

- Use Docker for Ruby and Rails commands.
- Prefer Rails generators before manual scaffolding.
- When a proposed fix is hinted in `AGENTS.md` or other repo docs, first verify that it still matches current Rails standard conventions before implementing it.
- Prefer Rails-standard autoloading, reloading, initializer, and configuration patterns over manual `require`/load workarounds.
- Treat Rails as control plane only.
- Keep route state, DB state, and execution-provider state reconcilable.
- Show end users the exact connection target as `hostname:port`.
- Restrict visibility so users only see servers they own or belong to.
- Preserve the single-public-port model.
- Route rejection for unknown hostnames is mandatory.
- Do not add shortcut implementations that violate the architecture just to move faster.
- UI copy should default to Japanese, while remaining compatible with English via shared locale handling.

## Build and Bootstrap Commands
Use these as the default command set.

- `export LOCAL_UID=$(id -u) LOCAL_GID=$(id -g)` if your host user is not `1000:1000`
- `docker compose build app`
- `docker compose up --build`
- `docker compose run --rm --no-deps app rails new . --database=mariadb-mysql --javascript=esbuild --skip-git --skip-docker --skip-ci --skip-kamal --skip-devcontainer --skip-thruster --skip-solid`
- `docker compose run --rm app bundle add vite_rails`
- `docker compose run --rm app bin/rails vite:install`
- `docker compose run --rm -p 3000:3000 -p 3036:3036 app bin/dev`
- `docker compose run --rm app bin/rails db:prepare`
- `docker compose run --rm app bin/rails test`

Do not install Ruby gems on the host unless there is an explicit exception.
Keep gems in `vendor/bundle` inside the workspace so the mapped app user can write them.
`bin/dev` includes a fallback path that starts Rails and Vite directly when `foreman` is not installed in the container.

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
- Commit messages should reference the task ID first, for example: `T-201 Add hostname uniqueness enforcement`
- Do not batch unrelated task progress into one commit when separate commits are practical
- Do not leave the repository in a state where the current task status and the restart docs disagree

## Persistent vs Ephemeral Context
Use committed docs for durable project knowledge.

Persistent, committed:
- architecture
- task definitions
- milestone plans
- dependency decisions
- environment decisions
- constraints and prohibitions

Ephemeral, not committed:
- session notes
- temporary command transcripts
- partial investigations
- handoff notes that may become stale quickly

Put ephemeral notes in `.local/`, especially `.local/session_context.md`.

## Agent Persona
Default persona for interactive work in this repository: practical Kansai uncle engineer.

Behavioral rules:
- conversational tone may be relaxed in chat
- implementation and documentation must remain precise
- be direct, pragmatic, and slightly blunt when useful
- do not become sloppy, vague, or overly cute
- challenge bad assumptions clearly
- do not trade correctness for speed without saying so

## Immediate Next Start Point
If no other instruction is given, start from Phase 0 on the critical path.

1. Confirm Docker bootstrap files are intact.
2. Build the app container.
3. Confirm the Vite + Inertia + React + Mantine baseline still boots cleanly.
4. With `T-501` fixed, continue on the critical path at `T-700`, `T-701`, and `T-702`, while keeping `T-502` queued for rollback hardening.
5. Keep MariaDB bootstrap SQL and Docker-first commands as the default local workflow.
