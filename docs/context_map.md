# Context Map

## Purpose
This file tells any contributor or agent where to find authoritative information after a context reset.

## Read First
- `AGENTS.md`

## Architecture and Implementation Design
- `docs/implementation_breakdown.md`
  Use for planned screens, routes, directory structure, and initial implementation decomposition.
- `docs/provider_api_contract.md`
  Use for the fixed Pterodactyl/Wings execution-provider contract, auth split, endpoint set, and backend discovery rules.
- `docs/router_api_contract.md`
  Use for the fixed mc-router file format, unknown-host rejection policy, and reload strategy baseline.

## Full Project Plan and Critical Path
- `docs/project_execution_plan.md`
  Use for phase ordering, dependency flow, critical path, completion criteria, and milestone planning.

## Shared Progress Tracking
- `docs/task_board.md`
  Use for unified task IDs, status tracking, blockers, and assignment across contributors or sub-agents.

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
- `bin/dev` now works in Docker without `foreman` by falling back to direct Rails + Vite startup.
- Bootstrap is complete through `T-005`.
- `T-004` is complete.
- Authentication baseline is installed with the Rails 8 built-in authentication generator through `T-100` and `T-101`.
- `MinecraftServer` baseline is installed through `T-102`.
- Authorization baseline is installed with Pundit through `T-106`.
- Hostname normalization, uniqueness, shared endpoint formatting, and status transition rules are installed through `T-203`.
- `ServerMember` baseline is installed through `T-103`.
- `RouterRoute` baseline is installed through `T-104`.
- Server visibility scopes and request protections are installed through `T-107`.
- The authenticated layout shell is installed through `T-600`.
- The login page UI is installed through `T-601`.
- The server index page UI is installed through `T-602`.
- The members management page UI is installed through `T-605`.
- The server creation page UI is installed through `T-603`; the form now submits real create requests, shows validation errors, and redirects into the server detail status view after intake.
- Development seed login is available as `dev@example.com` / `password`.
- The execution-provider contract is fixed through `T-300` using a Pterodactyl/Wings baseline.
- The provider base client contract, concrete Pterodactyl client, and env-driven provider initialization are installed through `T-301`, `T-302`, and `T-303`.
- The server create intake flow is installed through `T-500`; create requests now persist provisional server state, create an initial pending `RouterRoute`, and enqueue `CreateServerJob`.
- The mc-router contract is fixed through `T-400` in `docs/router_api_contract.md`.
- The route definition builder, config renderer, and config applier baselines are installed through `T-401`, `T-402`, and `T-403`.
- The provider-backed create job flow is installed through `T-501`; provisioning now resolves template config, creates the provider server, persists backend identifiers, applies router config, and transitions to `ready` on success.
- Create failure rollback handling is installed through `T-502`; provider create failures now remove provisional records, and route apply failures keep the server in `unpublished` with route publication disabled.
- Out-of-scope audit-log and monitoring code has been removed from the app codebase.
- Application scope is centered on server lifecycle and publication consistency; mc-router liveness is handled outside the app via Docker health checks.
- Monitoring dashboards, audit-log viewing pages, audit event recording, and unknown-hostname analytics are currently out of scope.
- If audit logging returns in a future phase, the preferred implementation baseline is the `audited` gem.
- The current critical path now moves through `T-503`, `T-504`, and `T-604`.
