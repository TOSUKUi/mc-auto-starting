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
- `AuditLog` baseline is installed through `T-105`.
- Server visibility scopes and request protections are installed through `T-107`.
- The authenticated layout shell is installed through `T-600`.
- The login page UI is installed through `T-601`.
- The server index page UI is installed through `T-602`.
- The members management page UI is installed through `T-605`.
- The server creation page UI is in progress under `T-603`; form and endpoint preview scaffolding are installed, but real provisioning now needs the `T-300` contract and the follow-up `T-301` provider interface.
- Development seed login is available as `dev@example.com` / `password`.
- The execution-provider contract is fixed through `T-300` using a Pterodactyl/Wings baseline.
- The critical path is now unblocked into `T-301` for the provider base client interface.
- `T-400` remains blocked on the mc-router config and reload contract.
