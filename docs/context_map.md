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
- `docs/provider_template_env_setup.md`
  Use for the required `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES` JSON shape, per-template required fields, and local/provider setup checks.
- `docs/provider_router_operations.md`
  Use for the chosen deployment topology of Rails Docker + Panel Docker + Wings host, plus provider/router integration checklist and anti-patterns.
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
- The authenticated layout shell is installed through `T-600`; the navbar now collapses behind a Burger on mobile widths instead of staying open by default.
- The login page UI is installed through `T-601`.
- The server index page UI is installed through `T-602`.
- `T-608` is the remaining Phase 6 UI task for Japanese-first copy cleanup across the current screens.
- `T-609` is the planned Phase 6 simplification task for a Paper-only create baseline with no template selector in the UI.
- The members management page UI is installed through `T-605`.
- The server creation page UI is installed through `T-603`; the form now submits real create requests, shows validation errors, redirects into the server detail status view after intake, and wraps correctly on smartphone widths.
- Development seed login is available as `dev@example.com` / `password`.
- The execution-provider contract is fixed through `T-300` using a Pterodactyl/Wings baseline.
- The provider base client contract, concrete Pterodactyl client, and env-driven provider initialization are installed through `T-301`, `T-302`, and `T-303`.
- `T-304` is complete in docs via `docs/provider_template_env_setup.md`; real provisioning still depends on the target environment actually setting those env values before Rails boots.
- `T-901` is complete in docs via `docs/provider_router_operations.md`; the operational topology is now fixed as Rails Docker + Panel Docker + Wings host.
- The server create intake flow is installed through `T-500`; create requests now persist provisional server state, create an initial pending `RouterRoute`, and enqueue `CreateServerJob`.
- The mc-router contract is fixed through `T-400` in `docs/router_api_contract.md`.
- The route definition builder, config renderer, and config applier baselines are installed through `T-401`, `T-402`, and `T-403`.
- The provider-backed create job flow is installed through `T-501`; provisioning now resolves template config, creates the provider server, persists backend identifiers, applies router config, and transitions to `ready` on success.
- Create failure rollback handling is installed through `T-502`; provider create failures now keep the provisional record visible in `failed` with route publication disabled, route apply failures keep the server in `unpublished` with route publication disabled, and the latest provisioning failure reason is persisted on `MinecraftServer.last_error_message` for the detail UI.
- The create page now exposes only template kinds configured on the active execution provider, and unavailable template kinds are rejected before a provisional record is created.
- The delete flow is installed through `T-503`; owners can delete a server, the route is unpublished before provider deletion, and the DB records are removed on success.
- Lifecycle actions and provider-status sync are installed through `T-504`; start/stop/restart/sync endpoints now use the persisted provider server identifier for Client API operations and update Rails status accordingly.
- Lifecycle controls are now hidden unless `provider_server_identifier` is present, so the UI no longer offers invalid operations against unprovisioned records.
- The server detail page UI is installed through `T-604`; operators can inspect connection, route, provider backend, and run lifecycle actions from a single screen.
- `T-803` is complete; acceptance coverage includes Docker-run Rails acceptance tests plus Playwright-based real-browser checks for login, server index, create, detail, members, and delete flows.
- Playwright MCP reachability note: in the current Docker host setup, the working browser target was `http://172.17.0.1:3000`; `localhost`, `127.0.0.1`, and the Docker service name were not reliable from the MCP side.
- Before launching a new Dockerized `bin/dev` process for browser verification, first check whether an existing reachable app instance is already serving the target URL and reuse it when healthy.
- The server detail page no longer emits the previous invalid HTML nesting warning during browser verification because non-text detail values now render through a `div` wrapper instead of a nested paragraph.
- Inertia local-development behavior is adjusted for the current Docker/LAN workflow; history encryption is disabled outside production, Mantine GET navigation uses `renderRoot` with Inertia `Link`, and the create form avoids chained `transform().post()` calls in React.
- `bin/dev` now removes stale `tmp/pids/server.pid` before booting Rails in the direct fallback path, so Docker restarts do not get stuck behind an old Puma PID file.
- Out-of-scope audit-log and monitoring code has been removed from the app codebase.
- Application scope is centered on server lifecycle and publication consistency; mc-router liveness is handled outside the app via Docker health checks.
- Monitoring dashboards, audit-log viewing pages, audit event recording, and unknown-hostname analytics are currently out of scope.
- If audit logging returns in a future phase, the preferred implementation baseline is the `audited` gem.
- The current remaining critical-path documentation task is `T-902`.
