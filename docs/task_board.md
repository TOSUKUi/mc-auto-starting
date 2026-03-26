# Task Board

## Usage Rules
- Every task has a stable ID.
- Status values are `todo`, `in_progress`, `blocked`, `done`.
- Dependencies list prerequisite task IDs.
- Contributors and sub-agents should refer to task IDs in all progress reports.
- Add new tasks only if they cannot fit under an existing task.

## Status Summary
- `todo`: not started
- `in_progress`: actively being worked on
- `blocked`: cannot proceed due to dependency or decision gap
- `done`: finished with completion criteria met

## Core Board

| ID | Phase | Task | Dependencies | Status | Completion Criteria |
| --- | --- | --- | --- | --- | --- |
| T-000 | P0 | Validate Docker bootstrap files | - | done | `Dockerfile`, `compose.yaml`, `.gitignore` match current decisions |
| T-001 | P0 | Build app container | T-000 | done | `docker compose build app` succeeds |
| T-002 | P0 | Generate Rails app skeleton with MariaDB-compatible adapter | T-001 | done | Rails app skeleton exists and bootstrap docs were preserved |
| T-003 | P0 | Boot Rails app in Docker | T-002 | done | Rails boots and `bin/rails about` succeeds |
| T-004 | P0 | Configure Vite + Inertia + React + Mantine | T-003 | done | One Inertia page renders with Mantine provider through Vite |
| T-005 | P0 | Configure DB, Redis, env handling, queue baseline | T-003 | done | `bin/rails db:prepare` succeeds, env approach is documented, and dev UID/GID mapping is defined |
| T-100 | P1 | Choose and add authentication library | T-003 | done | Login/logout flow path is fixed and installed |
| T-101 | P1 | Generate `User` model and migration | T-100 | done | User model persists required attributes |
| T-102 | P1 | Baseline `MinecraftServer` model exists | T-101 | done | Existing model and table are available for pivot work |
| T-103 | P1 | Generate `ServerMember` model and migration | T-102 | done | Membership and role model works |
| T-106 | P1 | Add authorization framework and policies | T-101,T-102,T-103 | done | Owner/member visibility rules are enforced |
| T-107 | P1 | Add server visibility scopes and request protections | T-106 | done | Users cannot fetch other users' servers |
| T-110 | P0 | Pivot planning docs to direct Docker control | T-005 | done | Restart docs, design, plan, and task board reflect the `Rails + docker.sock` single-host approach |
| T-200 | P1 | Redesign `minecraft_servers` for direct Docker management with `mc-router` | T-110,T-102 | done | Direct-Docker fields and migration strategy are fixed without removing router-based ingress |
| T-201 | P1 | Define slug normalization and uniqueness rules | T-200 | done | `slug` format and DB uniqueness are enforceable |
| T-202 | P1 | Define FQDN + single-public-port connection rules | T-200 | done | Shared formatting logic is fixed for `hostname.public_domain:shared_public_port` access |
| T-203 | P1 | Define server status transition model | T-200 | done | Direct-Docker state machine is documented and coded |
| T-204 | P1 | Define retained `router_routes` responsibilities | T-110,T-200 | done | Router model and route publication rules are fixed for the Docker-managed flow |
| T-205 | P1 | Inventory legacy provider dependencies | T-110 | done | Files, schema fields, fixtures, tests, and UI props that still depend on `ExecutionProvider` are explicitly listed before removal starts |
| T-300 | P2 | Define docker.sock safety boundary and compose strategy | T-110 | done | Compose and permission strategy for Docker Engine access are fixed |
| T-301 | P2 | Define Docker naming and label conventions | T-300,T-200 | done | Container names, volume names, and labels are fixed |
| T-302 | P2 | Implement Docker Engine client wrapper | T-300 | done | Rails can create/inspect/start/stop/restart/remove managed containers |
| T-303 | P2 | Implement `mc-router` publication update flow | T-200,T-204,T-300 | done | Route enable/disable + config apply is centralized so create/delete can reuse one publication path |
| T-304 | P2 | Define direct-Docker environment contract | T-300,T-301 | done | Required env such as image baseline, public domain, shared public port, shared network, and router paths are documented and wired into app defaults |
| T-400 | P3 | Implement direct-Docker create flow | T-200,T-201,T-202,T-203,T-302,T-303 | done | Create request persists a server, creates Docker resources, updates router publication, and stores identifiers |
| T-401 | P3 | Implement delete flow for direct-Docker servers | T-302,T-303,T-400 | done | Delete removes managed container resources and unpublishes the router route |
| T-402 | P3 | Implement start/stop/restart/sync flows | T-302,T-400 | done | Lifecycle operations update Docker state and Rails status correctly |
| T-403 | P3 | Persist container runtime details on sync | T-302,T-402 | todo | `container_state`, timestamps, and last error fields stay reconcilable |
| T-500 | P4 | Simplify create UI for direct-Docker baseline | T-400,T-202,T-600 | done | Create UI exposes only the fields needed for single-host Docker provisioning while keeping hostname/FQDN guidance |
| T-501 | P4 | Simplify detail UI for container-first operations | T-402,T-600 | done | Detail UI shows connection target, container/runtime info, and router publication instead of provider info |
| T-502 | P4 | Update index UI for direct-Docker summary fields | T-202,T-600 | done | Index UI reflects FQDN-based connection targets and container status cleanly |
| T-503 | P4 | Localize operator-facing UI copy to Japanese baseline | T-500,T-501,T-502 | in_progress | Default operator-facing copy is Japanese across the active screens |
| T-600 | P5 | Build authenticated layout shell | T-004,T-100 | done | Shared layout works for signed-in pages |
| T-601 | P5 | Build login page | T-100,T-004 | done | UI login works |
| T-700 | P6 | Remove provider coupling from app services | T-400,T-401,T-402 | done | Direct-Docker implementation no longer depends on execution-provider services |
| T-702 | P6 | Remove provider-era initializers and tests | T-205,T-700 | done | Provider initializers, provider service tests, and related fixtures are removed or replaced while router tests remain active |
| T-703 | P6 | Remove provider fields and references from controllers and UI | T-205,T-500,T-501,T-502,T-700 | done | Server controller responses and Inertia pages no longer expose provider concepts while preserving router data |
| T-701 | P6 | Remove legacy provider docs from active workflow | T-110,T-700 | todo | Restart docs no longer point to old provider docs as current truth |
| T-800 | P7 | Add model tests for direct-Docker rules | T-200,T-201,T-202,T-203 | todo | Core direct-Docker domain logic is covered |
| T-801 | P7 | Add request and authorization tests | T-400,T-401,T-402,T-500,T-501 | todo | Access control and create/lifecycle/delete flows are covered |
| T-802 | P7 | Add service tests for Docker client and allocators | T-302,T-303,T-400,T-401,T-402 | todo | Critical Docker orchestration paths are covered |
| T-803 | P7 | Add acceptance checks for direct-Docker requirement criteria | T-400,T-401,T-402,T-500,T-501 | done | Main create/detail/delete/lifecycle paths are verifiable by automated checks |
| T-804 | P7 | Verify compose-managed `mc-router` ingress against managed containers | T-303,T-400,T-803 | done | A compose-managed `mc-router` service can load generated routes, reach `mc-server-<hostname>:25565` on `mc_router_net`, and accept an end-to-end connection on the shared public port |
| T-805 | P7 | Fix `mc-router` live route reload on bind-mounted config changes | T-303,T-804 | done | Route changes written by Rails are picked up by the running compose-managed `mc-router` service without requiring a manual restart |
| T-900 | P8 | Document single-host setup and local development workflow | T-300,T-304,T-400 | todo | New contributor can boot the project with docker.sock mounted |
| T-903 | P8 | Audit `.env` ownership, required keys, and `.env.example` coverage | T-304,T-900 | todo | `.env` remains untracked, every actively consumed env key is classified as required or optional, required local/bootstrap keys stay uncommented, and optional keys are safe to leave commented in `.env.example` |
| T-904 | P8 | Define Kamal deployment topology and env/secret mapping | T-903 | todo | Kamal target host roles, accessory strategy, secret injection path, and the mapping from local `.env` keys to deploy-time env are fixed before implementation |
| T-901 | P8 | Document direct-Docker operations and safety notes | T-302,T-401,T-402 | todo | Operators can manage containers and understand docker.sock risks |
| T-905 | P8 | Implement Kamal deployment baseline | T-904 | todo | Repository includes the initial Kamal config, deploy hooks, and secret/env wiring needed to boot the Rails app on the target single host without reworking existing env names |
| T-902 | P8 | Document release, migration, and rollback procedure | T-803,T-900,T-901,T-905 | todo | Release workflow is written and reviewable for the new architecture, including Kamal-based deploy, migration, and rollback steps |
| T-1000 | P9 | Define Discord auth, invite URL, and bot/RCON architecture contract | T-900,T-901 | done | Discord OAuth-only sign-in, manual invite URL issuance, Rails-side bot API, and RCON execution boundaries are fixed in docs before implementation |
| T-1001 | P9 | Add Discord identity fields and OAuth provider integration | T-1000,T-101 | done | Users can be resolved by Discord identity and Rails can complete the Discord OAuth callback |
| T-1002 | P9 | Add manual invite-token model and issuance flow | T-1000,T-1001,T-106 | done | An authenticated operator can mint, view, revoke, and expire one-time invite URLs without sending email automatically |
| T-1003 | P9 | Replace password login with Discord-only login entry | T-1001,T-1002,T-503,T-601 | todo | Login UI and session entry path no longer depend on local passwords or password reset screens |
| T-1004 | P9 | Implement invite redemption and first-login account linking | T-1001,T-1002,T-107 | done | Only invited Discord users can finish first login, and repeated logins resolve to the same local user safely |
| T-1005 | P9 | Define Discord bot trust boundary and command API contract | T-1000,T-106,T-402 | todo | Bot authentication, allowed commands, per-server authorization checks, and audit expectations are fixed before endpoint implementation |
| T-1006 | P9 | Add Rails-side RCON client and server connection model | T-1000,T-200,T-400 | todo | Rails can connect to a managed server over RCON using app-managed configuration and timeout/error handling rules |
| T-1007 | P9 | Implement bot-facing lifecycle and RCON command endpoints | T-1005,T-1006,T-402 | todo | Discord bot can invoke start/stop/restart/status plus bounded RCON actions through Rails APIs without bypassing policy checks |
| T-1008 | P9 | Add tests for Discord auth, invite redemption, and bot commands | T-1003,T-1004,T-1007 | todo | OAuth login, invite consumption, rejected access, and bot command flows are covered by automated tests |
| T-1009 | P9 | Document Discord auth, invite issuance, and bot operations | T-1008,T-900,T-901 | todo | Operators can issue invites manually, configure Discord OAuth/Bot credentials, and understand the RCON security model |

## Critical Path Tasks

The current critical path is:

`T-110 -> T-200 -> T-201 -> T-202 -> T-203 -> T-204 -> T-300 -> T-301 -> T-302 -> T-303 -> T-304 -> T-400 -> T-402 -> T-500 -> T-501 -> T-803 -> T-804 -> T-805 -> T-900 -> T-903 -> T-904 -> T-901 -> T-905 -> T-902 -> T-1000 -> T-1001 -> T-1002 -> T-1003 -> T-1004 -> T-1005 -> T-1006 -> T-1007 -> T-1008 -> T-1009`

## Known Blockers

- No active blockers are recorded.
- Legacy provider docs and schema columns still exist as migration debt; active services and tests no longer depend on them.
- `mc-router` remains part of the active architecture and should not be treated as cleanup debt.

## Recent Decisions

- `T-300`: initial Docker integration uses direct `/var/run/docker.sock` mounting for the Rails app without a socket proxy.
- `T-300`: `mc-router` and app-managed Minecraft containers share one bridge network.
- `T-301`: router backends use `<container_name>:25565`.
- `T-301`: managed container names use `mc-server-<hostname>` and managed volume names use `mc-data-<hostname>`.
- `T-200`: `minecraft_servers` stores direct-Docker runtime identity in `container_name`, `container_id`, `volume_name`, `container_state`, and `last_started_at`, while provider columns remain as cleanup debt.
- `T-201`: the normalized hostname slug is the stored `hostname`, and shared normalization now lives in `MinecraftServerHostname`.
- `T-202`: public connection targets are always rendered from normalized hostname via `MinecraftPublicEndpoint`.
- `T-203`: direct-Docker status transitions and router-publication-eligible statuses are centralized in `MinecraftServerStatus`.
- `T-204`: `RouterRoute` now derives its published server address and backend from the related `MinecraftServer`.
- `T-303`: route publication apply/rollback is centralized in `Router::PublicationSync` so create/delete flows share one `mc-router` update path.
- `T-302`: Docker Engine access is wrapped behind Excon-based Unix socket transport with managed labels, names, and the minimal lifecycle API surface.
- `T-302`: the wrapper defaults to unversioned Engine API paths and only prefixes `/v1.xx` when `DOCKER_ENGINE_API_VERSION` is explicitly set.
- `T-304`: direct-Docker defaults are fixed through env-backed `MinecraftPublicEndpoint`, `MinecraftRuntime`, the `marctv` create payload, compose defaults, and the dedicated env contract doc.
- `T-304`: the create-form `minecraft_version` value now maps to the selected `marctv` image tag rather than an env payload field.
- Local Compose now reads checked-in `.env` defaults for `LOCAL_UID`, `LOCAL_GID`, `DOCKER_GID`, and `MINECRAFT_RUNTIME_IMAGE`.
- `T-400`: `Servers::ProvisionServer` now creates a managed volume/container through `DockerEngine`, starts it, persists runtime state, and then publishes the route.
- `T-400`: create retries once with `DockerEngine#pull_image` when the selected runtime image is missing locally.
- `T-400`: `MEMORYSIZE` now reserves JVM headroom below the Docker memory limit to avoid immediate OOM kill on boot.
- `T-803`: acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync flows against the direct-Docker baseline.
- `T-804`: compose-managed `mc-router` ingress is verified end-to-end on the shared public port after loading the generated routes.
- `T-805`: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after route rewrites, avoiding unreliable bind-mounted file-watch behavior.
- `T-805`: the compose-managed `mc-router` service now carries a stable Docker label so Rails can resolve the reload target without depending on generated container names.
- `T-804`: `compose.yaml` now defines a compose-managed `mc-router` service on the shared bridge network, and shared-port ingress has been verified against it.
- `T-903` planning direction: `.env` stays untracked as the live local file, `.env.example` is the checked-in template, uncommented entries should be limited to required local/bootstrap values, and optional deploy-era keys should stay commented until needed.
- `T-904` / `T-905` planning direction: the eventual deployment baseline should use Kamal while preserving the current env key names so local Compose and deploy automation do not drift.
- `T-401` / `T-402`: direct-Docker lifecycle/delete behavior is fixed in `docs/direct_docker_lifecycle_contract.md` before service replacement, including Docker-state mapping and tolerated `NotFound` cleanup.
- `T-401`: `Servers::DestroyServer` now unpublishes the route first, tolerates missing managed container/volume cleanup, and only destroys the DB record after Docker cleanup succeeds.
- `T-402`: `Servers::StartServer`, `StopServer`, `RestartServer`, and `SyncServerState` now use Docker Engine operations plus `inspect_container`-based reconciliation instead of `ExecutionProvider`.
- `T-500`: create page props are reduced to the direct-Docker baseline form fields and connection preview metadata, dropping fixed runtime/template display props from the controller contract.
- `T-501`: detail page now centers public connection target, router publication state, Docker runtime identifiers, and lifecycle actions without fixed template/provider framing.
- `T-502`: index page now summarizes public connection targets plus container/router state, and no longer depends on backend-oriented runtime labels from the listing payload.
- `T-503`: layout/create/index/detail copy is being shifted further toward Japanese, active server screens now hide Docker backend identifiers behind simpler player-facing status and connection language, the app shell has moved to a flat Minecraft-inspired dark theme with `/` routed directly to the server index, and create-form validation now enforces a 4GB memory ceiling plus stricter hostname input rules.
- Local env handling now treats `.env.example` as the checked-in template while `.env` stays untracked for machine-specific values.
- `T-205`: legacy provider dependency inventory now lives in `docs/provider_cleanup_inventory.md`.
- `T-700` / `T-702`: provider service classes, initializer, and dedicated provider tests are removed from the active code path.
- `T-703`: controller create flow no longer accepts or injects provider-era template input; `template_kind` is retained only as internal schema debt for now.
- Discord login direction is now fixed as Discord OAuth-only sign-in with manual invite URLs instead of local password distribution.
- Discord bot integration will call Rails-owned APIs for lifecycle and RCON operations; the bot must not talk to Docker or Minecraft containers directly.
- `T-1000`: the strategy contract for Discord auth, invite URLs, and bot mediated RCON now lives in `docs/discord_auth_and_bot_strategy.md`.
- `T-1001`: `users` now carry Discord identity fields, and Rails can complete a Discord OAuth callback to resolve already-linked users.
- `T-1002`: manual invite issuance now uses digest-only stored tokens; the raw invite URL is shown only once when an authenticated user creates the invite from `/discord-invitations`.
- Initial owner bootstrap is expected to use `BOOTSTRAP_DISCORD_USER_ID=... bin/rails db:seed` until the Discord-only login and invite redemption path is complete.
- `T-1004`: invite redemption now begins at `/invites/:token`; a matching pending invite can create the first local user during the Discord OAuth callback, and mismatched or inactive invites are rejected.
