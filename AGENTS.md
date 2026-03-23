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

A Rails app skeleton has already been generated in-place, and the next focus is environment cleanup, DB readiness, and frontend baseline setup.

## Locked Technical Decisions
These are already decided and should be treated as defaults unless explicitly changed.

- App role: Rails control plane for Minecraft server lifecycle and publication management
- Runtime: Docker-first workflow
- Ruby: `3.4.9`
- Rails: `8.1.2`
- Database: MariaDB `10.11.16` (via `mysql2` adapter)
- Cache / queue support candidate: Redis `7`
- Frontend architecture: Rails + Inertia.js + React
- UI library: Mantine `8.3.1`
- JS bundling direction: Rails 8-compatible setup, planned around `esbuild`
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
- Treat Rails as control plane only.
- Keep route state, DB state, and execution-provider state reconcilable.
- Show end users the exact connection target as `hostname:port`.
- Restrict visibility so users only see servers they own or belong to.
- Preserve the single-public-port model.
- Route rejection for unknown hostnames is mandatory.
- Do not add shortcut implementations that violate the architecture just to move faster.

## Build and Bootstrap Commands
Use these as the default command set.

- `docker compose build app`
- `docker compose up --build`
- `docker compose run --rm --no-deps app rails new . --database=mariadb-mysql --javascript=esbuild --skip-git --skip-docker --skip-ci --skip-kamal --skip-devcontainer --skip-thruster --skip-solid`
- `docker compose run --rm app bin/rails db:prepare`
- `docker compose run --rm app bin/rails test`

Do not install Ruby gems on the host unless there is an explicit exception.

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
3. Configure Inertia + React + Mantine baseline on top of the generated Rails app.
4. Then choose auth and authorization foundations and start model generators.
5. Keep MariaDB bootstrap SQL and Docker-first commands as the default local workflow.
