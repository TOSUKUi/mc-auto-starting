# Current State

## Evidence Set
- `README.md`
- `AGENTS.md` before slimming
- `docs/context_map.md`
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/implementation_breakdown.md`
- `docs/direct_docker_env_contract.md`
- `docs/direct_docker_lifecycle_contract.md`
- `docs/access_policy_and_quota_contract.md`
- `docs/server_ui_display_review.md`
- Recent git history for state-doc updates:
  - `6cae399` Define next UI, world transfer, and bot planning tasks
  - `6028955` Rewrite runbooks for compose deployment

## Project Snapshot
The repository is past the architecture-pivot phase and already ships the direct-Docker single-host baseline. Rails manages Minecraft containers over `/var/run/docker.sock`, publishes hostname-based routes through Compose-managed `mc-router`, uses Discord OAuth-only login, enforces global-role plus server-membership authorization, and exposes Rails-owned RCON, whitelist, player-count, recent-log, and structured command flows.

## Stable Decisions
- Active architecture is `Rails + docker.sock + mc-router` on a single host.
- `mc-router` stays in the active design and is managed by Compose on the shared `mc_router_net` bridge network.
- Production deploy direction is pull-based `docker-compose.production.yml` under Komodo, using prebuilt registry images and env-injected secrets.
- Authentication is Discord OAuth-only with invite URLs; the internal bot talks only to Rails-owned private-network APIs.
- Runtime family baseline is `itzg/minecraft-server`; `paper` and `vanilla` both use the `TYPE` + `VERSION` contract instead of per-version image tags.

## Active Work
The task board currently shows no tasks marked `in_progress`.

Open todo work evidenced in `docs/task_board.md`:
- `T-1122`: fix the create-form memory-field alignment issue.
- `T-1200`: define the managed world download/upload contract.
- `T-1201`: implement the managed world download/upload flow after `T-1200`.
- `T-1202`: define the repository-local Discord bot runtime contract.

## Recent Accepted Changes
- The deployment baseline is now production Compose + Komodo, with checked-in topology, pull-based production Compose, and rewritten operator/release runbooks through `T-911` to `T-914`.
- `T-915` is complete: obsolete Kamal deployment files and the superseded Kamal topology doc have been removed, and the restart/context map now points only at the active Compose + Komodo path.
- Discord OAuth invites, internal bot API, Rails-owned RCON boundary, whitelist management, player observability, and browser structured-command flows are complete through the `T-1000` to `T-1121` tracks.
- Runtime family selection, runtime-version resolution, and operator-facing runtime/version display are complete through the `T-1100` to `T-1107` work.
- The current UI baseline is Japanese-first and the active server index/detail/create flows already follow the direct-Docker contract; the remaining visible UI follow-up is the smaller `T-1122` form-alignment task.
- The latest planning write-back added the next Phase 11 tasks for world transfer and repository-local bot runtime (`6cae399`).

## Open Risks
- World transfer is still contract-only debt: there is no accepted archive/import safety boundary yet for managed server data.
- The repository-local Discord bot runtime is not yet specified, so the bot remains an API contract without a checked-in process topology.
- The task board still carries `T-910` as a blocked historical task; contributors should treat it as inactive context, not as active delivery work.

## Unknowns And Assumptions
- No checked-in source marks any task as actively assigned or currently being implemented; this file therefore treats the remaining `todo` tasks as open follow-up work rather than active in-flight work.
- The ordering between `T-1122`, `T-1200`, and `T-1202` is not fixed by a single linear dependency chain; only explicit task dependencies are treated as authoritative.

## Write-Back Targets
- `AGENTS.md`: slim constitution and restart map only.
- `docs/project/current_state.md`: compressed accepted state and open work.
- `docs/project/critical_path.md`: current goal and active dependency chain.
