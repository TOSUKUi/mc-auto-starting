# Context Map

## Purpose
This file tells any contributor or agent where to find authoritative information after a context reset.

## Read First
- `AGENTS.md`

## Architecture and Implementation Design
- `docs/implementation_breakdown.md`
  Use for the active `Rails + docker.sock` single-host architecture, screen list, data model, and service decomposition.
- `docs/project_execution_plan.md`
  Use for the active phase ordering, dependency flow, milestones, and critical path.
- `docs/task_board.md`
  Use for the active direct-Docker task system.

## Historical / Superseded References
- `docs/provider_api_contract.md`
  Historical reference from the abandoned Pterodactyl/Wings approach. Not current architecture.
- `docs/provider_template_env_setup.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/provider_router_operations.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/router_api_contract.md`
  Historical reference from the abandoned mc-router approach. Not current architecture.

## Disposable Session Context
- `.local/session_context.md`
  Use for temporary restart notes, recent findings, in-flight command plans, and handoff notes that should not be committed.

## Bootstrap / Environment Files
- `Dockerfile`
- `compose.yaml`
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
- Authenticated layout and current login/index/create/detail/members UI baselines already exist, but they still contain legacy provider/router assumptions and are now subject to direct-Docker cleanup.
- The planning pivot task `T-110` is complete.
- The active architecture is now `Rails + docker.sock` for single-host Minecraft container management.
- `Pterodactyl/Wings` and `mc-router` are no longer the current target architecture.
- The next implementation critical path starts at `T-200` after the planning pivot is fixed.
