# Repository Guidelines

## Purpose Of This File
`AGENTS.md` is the durable restart constitution for this repository.

- Keep this file thin.
- Keep current project state in `docs/project/current_state.md`.
- Keep the active dependency chain in `docs/project/critical_path.md`.
- Keep detailed contracts, runbooks, and task history in the checked-in docs they already belong to.

## Current Snapshot
This repository is a single-host Minecraft server manager built with Rails 8, Docker Engine, and `mc-router`. Rails is the control plane, talks to Docker through `/var/run/docker.sock`, manages Minecraft containers directly, and rewrites `mc-router` routes so public ingress stays on one shared port.

## Source Of Truth Map
- `docs/project/current_state.md`
  Compressed accepted state, active open work, recent accepted changes, and current risks.
- `docs/project/critical_path.md`
  Current goal, active dependency chain, blockers, and immediate next checks.
- `docs/context_map.md`
  Authoritative map of which checked-in doc answers which question.
- `docs/project_execution_plan.md`
  Phase ordering, dependency flow, and implementation sequencing.
- `docs/task_board.md`
  Stable task IDs, statuses, dependencies, and completion criteria.
- `docs/implementation_breakdown.md`
  Active application architecture, screen list, models, and service decomposition.
- `docs/direct_docker_env_contract.md`
  Direct-Docker env and fixed-default contract.
- `docs/direct_docker_lifecycle_contract.md`
  Managed container lifecycle, sync, and delete contract.
- `docs/access_policy_and_quota_contract.md`
  Global roles, membership rules, and create quota policy.
- `docs/whitelist_and_access_control_strategy.md`
  Whitelist authority and Rails-owned RCON boundary.
- `docs/server_ui_display_review.md`
  Active server index/detail display contract.
- `docs/operator_runbook.md`
  Operator-facing day-2 procedure and safety notes.
- `docs/release_runbook.md`
  Release, rollback, and verification flow.
- `docs/compose_komodo_deployment_topology.md`
  Production Compose + Komodo topology and secret contract.

## Locked Technical Defaults
- App role: Rails control plane for single-host Minecraft server lifecycle management.
- Runtime control path: direct Docker Engine access over mounted `/var/run/docker.sock`.
- Topology: single host only in the initial version.
- Ingress: `mc-router` remains part of the active architecture and is managed by Compose, not Rails.
- Public connection format: `<server-fqdn>:<shared_public_port>`.
- Backend routing format: `<container_name>:25565` on the shared bridge network.
- Production deploy direction: `docker-compose.production.yml` managed by Komodo, with prebuilt images pulled from a registry.
- Production secrets direction: boot without Rails credentials or `master.key`; inject secrets directly by env/secret store.
- Auth direction: Discord OAuth2 only.
- User hierarchy: global `admin` / `operator` / `reader`; server-local `viewer` / `manager`.
- Runtime family baseline: `itzg/minecraft-server`, with `paper` and `vanilla` selected via `TYPE` + `VERSION`.
- UI stack: Rails + Inertia.js + React + Mantine.
- UI language policy: default `ja`, optional `en`, with Rails I18n as the source of truth.

## Repository Structure
- `app/controllers/`: Rails controllers
- `app/models/`: Active Record models
- `app/policies/`: authorization policies
- `app/services/`: Docker orchestration, lifecycle, RCON, and router services
- `app/jobs/`: async jobs
- `app/javascript/`: Inertia + React frontend
- `docs/`: durable design, plans, contracts, runbooks, and project-state docs
- `.local/`: disposable session notes that should not be treated as durable truth

## Resume Order After Context Reset
1. `AGENTS.md`
2. `docs/project/current_state.md`
3. `docs/project/critical_path.md`
4. `docs/context_map.md`
5. `docs/project_execution_plan.md`
6. `docs/task_board.md`
7. Relevant contracts or runbooks for the task you are touching

## Execution Rules
- Use Docker for Ruby and Rails commands.
- Prefer Rails generators before manual scaffolding.
- Prefer Rails-standard autoloading, reloading, initializer, and configuration patterns.
- Keep Docker control isolated behind small service classes.
- Never let Rails operate on Docker resources that are not explicitly labeled as app-managed.
- Preserve `mc-router`-based single-port routing unless the user explicitly changes that decision.
- Treat `/var/run/docker.sock` access as high risk and document it clearly.
- Keep `DOCKER_ENGINE_API_VERSION` unset by default unless a deployment explicitly requires an override.
- When removing legacy provider-era concepts, prefer deleting dead compatibility layers instead of extending them.
- UI copy should default to Japanese while remaining compatible with English through shared locale handling.
- In React/Inertia work, treat `useEffect` as a last resort after server props, event handlers, render-time derivation, and explicit local state.

## Write-Back Rule
- Update `AGENTS.md` only when durable restart rules, stable defaults, or source-of-truth routing change.
- Update `docs/project/current_state.md` when accepted state, open work, recent accepted changes, or real risks change.
- Update `docs/project/critical_path.md` when the current goal, dependency chain, blockers, or immediate next checks change.
- Do not turn `AGENTS.md` back into a task ledger or a runbook.
