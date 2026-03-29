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
| T-403 | P3 | Persist container runtime details on sync | T-302,T-402 | done | `container_state`, timestamps, and last error fields stay reconcilable |
| T-404 | P3 | Enforce operator total-memory quota for server creation | T-400,T-107 | done | Create flow rejects operator requests when their owned servers' summed `memory_mb` plus the requested server exceeds `5120 MB`, while admins remain unrestricted and the UI shows current usage/remaining quota |
| T-500 | P4 | Simplify create UI for direct-Docker baseline | T-400,T-202,T-600 | done | Create UI exposes only the fields needed for single-host Docker provisioning while keeping hostname/FQDN guidance |
| T-501 | P4 | Simplify detail UI for container-first operations | T-402,T-600 | done | Detail UI shows connection target, container/runtime info, and router publication instead of provider info |
| T-502 | P4 | Update index UI for direct-Docker summary fields | T-202,T-600 | done | Index UI reflects FQDN-based connection targets and container status cleanly |
| T-503 | P4 | Localize operator-facing UI copy to Japanese baseline | T-500,T-501,T-502 | done | Default operator-facing copy is Japanese across the active screens, the create flow defaults to `Java Edition` with Japanese-first runtime labels, create-form validation errors render back into the active page instead of disappearing on 422, startup-settings presentation is grouped and simplified on create/detail, login now uses the same visual system as the authenticated shell while keeping only the page label plus a short service summary and a single `Discordでログイン` action, index exposes an explicit `詳細を見る` action, and the create/detail/index/invite/membership/login surfaces have shed most self-evident helper text under the `docs/ui_polish_audit_strategy.md` audit |
| T-512 | P4 | Audit all active pages against the UI polish strategy | T-503 | done | Create/detail/membership/login/invite and the remaining active pages are now reviewed against `docs/ui_polish_audit_strategy.md`, with a concrete per-page keep/remove/unify inventory captured in `docs/ui_polish_audit_inventory.md` before more UI edits land |
| T-513 | P4 | Redesign Discord login to match the app shell visual system | T-503,T-512,T-1003 | done | `/login` now uses the same dark visual system as the authenticated control plane, keeps only the Discord sign-in path plus minimal invite guidance, and no longer uses the earlier split-screen auth-specific theme |
| T-504 | P4 | Show owner username instead of email on server index | T-502,T-1001 | done | Server index owner display now uses `discord_global_name` / `discord_username` fallback instead of `email_address` |
| T-505 | P4 | Review and fix server index/detail display contract | T-501,T-502,T-503 | done | The intended fields, labels, ordering, and omissions for server index/detail are reviewed and captured in `docs/server_ui_display_review.md` before follow-up UI edits |
| T-506 | P4 | Gate server detail actions by lifecycle state | T-402,T-501,T-503,T-505 | done | The server detail page now only exposes lifecycle actions that match the current server state, so running servers no longer show a start action and transitional states converge on sync-only controls |
| T-507 | P4 | Poll server detail state during lifecycle transitions | T-402,T-501,T-506 | done | The server detail page now reloads its `server` props while `starting`, `stopping`, and `restarting` are in flight, and shows a simple spinner on the status badge until a stable state returns |
| T-508 | P4 | Remove duplicated route metadata and rebalance server layouts | T-503,T-505,T-506,T-507 | done | Server index/detail no longer surface `応答状態`, `最終反映`, or `最終ヘルスチェック`, repeated facts such as status/connection/runtime labels are shown only once per screen, and the primary detail layout clearly separates connection, action, ownership, and lower-priority technical metadata |
| T-509 | P4 | Surface route publication failures only when abnormal | T-303,T-505,T-508 | done | Normal server screens hide router metadata, but route apply/audit failures surface explicit warning UI and keep `attention_needed` meaningful |
| T-510 | P4 | Make transition-state polling converge via backend sync | T-402,T-507 | done | Detail-page polling now triggers backend reconciliation while `starting`, `stopping`, or `restarting`, so the visible status can move to a stable state without manual sync |
| T-511 | P4 | Provide a direct recovery action for publication failures | T-509 | done | Route failure warnings now tell operators the next step and expose a `公開設定を再適用` action for authorized users, while unauthorized users are told to contact an owner/admin |
| T-600 | P5 | Build authenticated layout shell | T-004,T-100 | done | Shared layout works for signed-in pages |
| T-601 | P5 | Build login page | T-100,T-004 | done | UI login works |
| T-700 | P6 | Remove provider coupling from app services | T-400,T-401,T-402 | done | Direct-Docker implementation no longer depends on execution-provider services |
| T-702 | P6 | Remove provider-era initializers and tests | T-205,T-700 | done | Provider initializers, provider service tests, and related fixtures are removed or replaced while router tests remain active |
| T-703 | P6 | Remove provider fields and references from controllers and UI | T-205,T-500,T-501,T-502,T-700 | done | Server controller responses and Inertia pages no longer expose provider concepts while preserving router data |
| T-701 | P6 | Remove legacy provider docs from active workflow | T-110,T-700 | done | Restart docs no longer point to old provider docs as current truth |
| T-800 | P7 | Add model tests for direct-Docker rules | T-200,T-201,T-202,T-203 | done | Core direct-Docker domain logic is covered |
| T-801 | P7 | Add request and authorization tests | T-400,T-401,T-402,T-500,T-501 | done | Access control and create/lifecycle/delete flows are covered |
| T-802 | P7 | Add service tests for Docker client and allocators | T-302,T-303,T-400,T-401,T-402 | done | Critical Docker orchestration paths are covered |
| T-803 | P7 | Add acceptance checks for direct-Docker requirement criteria | T-400,T-401,T-402,T-500,T-501 | done | Main create/detail/delete/lifecycle paths are verifiable by automated checks |
| T-804 | P7 | Verify compose-managed `mc-router` ingress against managed containers | T-303,T-400,T-803 | done | A compose-managed `mc-router` service can load generated routes, reach `mc-server-<hostname>:25565` on `mc_router_net`, and accept an end-to-end connection on the shared public port |
| T-805 | P7 | Fix `mc-router` live route reload on bind-mounted config changes | T-303,T-804 | done | Route changes written by Rails are picked up by the running compose-managed `mc-router` service without requiring a manual restart |
| T-900 | P8 | Document single-host setup and local development workflow | T-300,T-304,T-400 | done | New contributor can boot the project with docker.sock mounted |
| T-903 | P8 | Audit `.env` ownership, required keys, and `.env.example` coverage | T-304,T-900 | done | `.env` remains untracked, every actively consumed env key is classified as required or optional, required local/bootstrap keys stay uncommented, and optional keys are safe to leave commented in `.env.example` |
| T-904 | P8 | Define Kamal deployment topology and env/secret mapping | T-903 | done | Kamal target host roles, accessory strategy, secret injection path, and the mapping from local `.env` keys to deploy-time env are fixed before implementation |
| T-901 | P8 | Document direct-Docker operations and safety notes | T-302,T-401,T-402 | done | Operators can manage containers and understand docker.sock risks |
| T-905 | P8 | Implement Kamal deployment baseline | T-904 | done | Repository includes the initial Kamal config, deploy hooks, and secret/env wiring needed to boot the Rails app on the target single host without reworking existing env names |
| T-906 | P8 | Switch Kamal baseline to external MariaDB | T-904,T-905 | done | Kamal app env now expects external `DB_HOST` / `DB_PORT`, MariaDB is removed from Kamal accessories, `.kamal` secret examples drop root-password bootstrap, and deployment docs explain the external-DB shape while Redis remains the only accessory |
| T-902 | P8 | Document release, migration, and rollback procedure | T-803,T-900,T-901,T-905 | done | Release workflow is written and reviewable for the new architecture, including Kamal-based deploy, migration, and rollback steps |
| T-1000 | P9 | Define Discord auth, invite URL, and bot/RCON architecture contract | T-900,T-901 | done | Discord OAuth-only sign-in, manual invite URL issuance, Rails-side bot API, and RCON execution boundaries are fixed in docs before implementation |
| T-1001 | P9 | Add Discord identity fields and OAuth provider integration | T-1000,T-101 | done | Users can be resolved by Discord identity and Rails can complete the Discord OAuth callback |
| T-1002 | P9 | Add manual invite-token model and issuance flow | T-1000,T-1001,T-106 | done | An authenticated operator can mint, view, revoke, and expire one-time invite URLs without sending email automatically |
| T-1003 | P9 | Replace password login with Discord-only login entry | T-1001,T-1002,T-503,T-601 | done | `/login` is now a Discord-only entry for existing users, invite URLs remain the only signup path, password reset/local password routes are removed from the active path, and bootstrap-owner startup logs point operators at the first `/login` link |
| T-1004 | P9 | Implement invite redemption and first-login account linking | T-1001,T-1002,T-107 | done | Only invited Discord users can finish first login, and repeated logins resolve to the same local user safely |
| T-1005 | P9 | Define Discord bot trust boundary and command API contract | T-1000,T-106,T-402 | done | `docs/discord_bot_api_contract.md` fixes bot authentication, acting-user resolution, allowed commands, whitelist scope, per-server authorization checks, response envelopes, and audit expectations before endpoint implementation |
| T-1006 | P9 | Add Rails-side RCON client and server connection model | T-1000,T-200,T-400 | done | Rails can connect to a managed server over RCON using app-managed host/port/password derivation, the runtime enables RCON on managed containers, and timeout/error handling rules are centralized in service code |
| T-1007 | P9 | Implement bot-facing server-operation and bounded-RCON endpoints | T-1005,T-1006,T-402 | done | Discord bot can invoke status/start/stop/restart/sync, whitelist actions, and owner/admin-only bounded RCON commands through Rails APIs without bypassing policy checks or allowing forbidden commands such as `stop` via the RCON surface, while `/api/discord/bot/*` stays limited to the Docker private network plus bot-token authentication |
| T-1008 | P9 | Add tests for Discord auth, invite redemption, and bot commands | T-1003,T-1004,T-1007 | done | OAuth login, invite consumption, rejected access, and bot command flows are covered by automated tests |
| T-1009 | P9 | Document Discord auth, invite issuance, and bot operations | T-1008,T-900,T-901 | done | Operators can issue invites manually, configure Discord OAuth/Bot credentials, and understand the RCON security model |
| T-1014 | P9 | Define user-type hierarchy and invitation authority contract | T-1000,T-1002,T-106 | done | `admin` / `operator` / `reader` semantics, create quota, invite authority, and reader read-only behavior are fixed in `docs/access_policy_and_quota_contract.md` |
| T-1015 | P9 | Add global user-type model for `admin` / `operator` / `reader` | T-1014,T-101 | done | `users` carry the new global type and authorization code can resolve it independently from server-local membership roles |
| T-1016 | P9 | Restrict invitation authority by global user type | T-1014,T-1002,T-1015 | done | Admins can invite without restriction, operators can invite only readers, and readers cannot issue invites |
| T-1017 | P9 | Enforce create authorization by global user type at controller/policy level | T-1014,T-1015,T-107,T-404 | done | Admins can always create, operators are quota-limited, readers are denied, and controller-level authorization rejects unauthorized requests |
| T-1018 | P9 | Enforce combined global-type and membership authorization across web and bot surfaces | T-1014,T-1015,T-1005,T-1010 | done | `viewer` grants show-only access, `manager` grants lifecycle access, and destroy/member-management remain limited to owners or admins at controller/policy level |
| T-1019 | P9 | Rename server membership role `operator` to `manager` | T-1014,T-103 | done | Server-local membership roles now use `viewer` / `manager` consistently in schema, policies, controllers, fixtures, and UI copy |
| T-1020 | P9 | Define whitelist command and authority contract | T-1000,T-1006,T-1014 | done | `docs/whitelist_and_access_control_strategy.md` fixes Rails-owned RCON whitelist operations and their authority boundary before implementation |
| T-1021 | P9 | Add Rails-side whitelist command service over RCON | T-1006,T-1020 | done | Rails can inspect and mutate server whitelist entries through bounded RCON commands with timeout/error handling, explicit `rconrb` loading, Minecraft-compatible auth handling, and no direct container-console exposure |
| T-1022 | P9 | Add authorization and request/service tests for whitelist operations | T-1021,T-1018 | done | Only admins and owners can reach whitelist endpoints, stopped-server and RCON-failure handling are covered, and unauthorized users are rejected at controller/policy level |
| T-1023 | P9 | Add whitelist management UI to the server detail page | T-1021,T-1022,T-505 | done | Authorized users can view and edit desired whitelist state on server detail, running servers apply changes immediately through RCON, stopped servers stage changes that are applied on the next start, the detail page does not loop whitelist fetches, whitelist mutations re-sync only the card while safely handling non-JSON restart responses, and entries are rendered in monospace to reduce case-misread risk |
| T-1024 | P9 | Align future bot command scope with whitelist authority | T-1005,T-1020,T-1021 | done | The bot trust boundary now explicitly covers which whitelist read/write actions are allowed, keeps whitelist mutations owner/admin-only, and separates bounded RCON input from lifecycle operations in `docs/discord_bot_api_contract.md` |
| T-1025 | P9 | Make whitelist live-apply and restart reconciliation reliable end-to-end | T-1021,T-1023 | done | Running-server whitelist mutations now use verified RCON auth/response handling, `start` and `restart` both recreate the managed container with the current saved whitelist env, live verification confirmed DB/runtime-file/RCON agreement, and immediate-apply failures now return a clear saved-but-not-live-applied message |
| T-1010 | P9 | Define player count, server logs, and browser command-console contract | T-402,T-1006 | done | The source of truth, refresh strategy, authorization rules, and payload shape for player counts, recent logs, and owner/admin-only bounded browser RCON commands are fixed in `docs/player_observability_and_browser_console_contract.md` before UI work starts |
| T-1011 | P9 | Surface player counts in server index and detail views | T-1010,T-502 | done | Server index and detail now show RCON-derived player counts when available, the detail view refreshes player presence while visible, and unavailable counts degrade quietly without replacing the primary lifecycle state |
| T-1012 | P9 | Add browser log viewer and command console UI | T-1010,T-1007,T-501 | done | Server detail now exposes a manual-refresh recent-log panel for visible users and an owner/admin-only bounded RCON console with inline success/failure feedback, while keeping lifecycle and whitelist operations on their dedicated surfaces |
| T-1013 | P9 | Stop storing email addresses for Discord-auth users | T-1001,T-1004 | done | Discord OAuth now requests only `identify`, user creation/login/bootstrap flows stop persisting email fields, and the remaining member-management UI has been shifted from email lookup to Discord user IDs |
| T-1101 | P10 | Add Java server runtime family selection to create flow | T-304,T-400,T-500 | done | Operators can choose between the current runtime family and a standard Java-server path without breaking provisioning defaults |
| T-1100 | P10 | Research latest-version resolution and dynamic tag sourcing for the expanded Java runtimes | T-1101 | done | After Java runtime family selection exists, the source of truth for resolving `latest` to a concrete Minecraft version and the feasibility/fallback plan for dynamically building tag choices are documented |
| T-1102 | P10 | Persist and display resolved Minecraft version metadata | T-1100,T-1101,T-501,T-502 | done | When a runtime tag such as `latest` is selected, the app stores and shows the concrete Minecraft server version returned by the managed server instead of only the symbolic tag |
| T-1103 | P10 | Implement dynamic or synchronized Minecraft version option catalog | T-1100,T-1101 | done | The create UI can build version choices from a maintained catalog or dynamic source, with a documented fallback when live tag discovery is unavailable or unsafe |
| T-1104 | P10 | Define per-runtime version-source strategy and display contract | T-1102,T-1103 | done | `vanilla` now resolves from the Mojang version manifest, `paper` from the Paper-specific source, fallback catalog and live-source URLs are fixed in docs/config, and the UI contract now consistently separates user-facing `label`, submitted `value`, and persisted `resolved_minecraft_version` |
| T-1105 | P10 | Fetch `vanilla` options from the Mojang version manifest at request time | T-1104 | done | The create form can build `vanilla` version choices from the live Mojang manifest while preserving a safe fallback when the manifest is unavailable |
| T-1106 | P10 | Fetch `paper` options from the Paper version list at request time | T-1104 | done | The create form can build `paper` version choices from the Paper-specific source while preserving a safe fallback when that source is unavailable |
| T-1107 | P10 | Unify version-option presentation around label/value display rules | T-1104,T-1105,T-1106 | done | Operators see only the human-facing Minecraft version label, while the stored/submitted value remains the stable version key chosen for each runtime family |
| T-1110 | P10 | Define server startup-settings candidate contract | T-500,T-1101 | done | Candidate server startup settings, phasing, and create-vs-detail split now live in `docs/server_startup_settings_candidates.md` |
| T-1111 | P10 | Persist baseline startup settings alongside server desired state | T-1110,T-400 | done | `minecraft_servers` now persists baseline startup settings such as `hardcore`, `difficulty`, `max_players`, `motd`, `pvp`, and `gamemode`, and `MinecraftRuntime` includes them in the managed-container env contract used on create/start/restart |
| T-1112 | P10 | Add startup settings UI to create/detail flows | T-1110,T-1111,T-500,T-501 | done | Create flow now accepts the baseline startup settings, server detail shows them for visible users, and owner/admin users can update the desired state from detail with enum-like values rendered as `Select` controls plus explicit `hardcore` handling |
| T-1113 | P10 | Expose startup settings through the bot surface | T-1110,T-1111,T-1007 | done | Discord bot can now read and update the same startup-settings desired state through the internal Rails-owned bot API surface |
| T-1114 | P10 | Reframe startup settings as create-time defaults and move detail changes to structured RCON actions | T-1110,T-1111,T-1112,T-1012 | done | Startup settings remain part of create-time/default runtime config, detail and bot surfaces now treat them as read-only initial values, Rails no longer exposes startup-settings update endpoints, and mutable live-setting changes are handled through structured allowlisted RCON controls such as difficulty/weather/time/say/kick/save-all |
| T-1115 | P10 | Audit all input validation paths and block any server-side gaps | T-500,T-1002,T-1012,T-1114 | done | Browser-visible validation now matches controller/model/service enforcement across active create/invite/member/whitelist/RCON flows, including server-side rejection for unsupported create versions, invalid membership roles, invalid Discord user IDs, and raw browser RCON command fallback, with request/model/service coverage |
| T-1116 | P10 | Define structured RCON command catalog and argument schema | T-1114,T-1012 | done | Detail and bot RCON operations now use the shared catalog fixed in `docs/structured_rcon_command_catalog.md`, with `command_key + args` payloads including player-target schemas such as `gamemode(gamemode, player_name)`, while mutable live settings remain outside Rails desired-state storage |
| T-1117 | P10 | Add Rails-side structured RCON command builder and validation | T-1116 | done | Rails now converts `command_key + args` into bounded RCON commands server-side via `Servers::StructuredRconCommand`, validates required/optional arguments and player-target schemas such as `gamemode(gamemode, player_name)`, and keeps mutable live-setting changes out of DB-backed desired-state storage |
| T-1118 | P10 | Replace detail RCON cards with command-select plus argument form UI | T-1116,T-1117 | done | Server detail now exposes one structured RCON surface with a command select, schema-driven argument inputs, and shared result rendering instead of separate action cards or freeform command input |
| T-1119 | P10 | Align bot RCON contract with the structured command catalog | T-1116,T-1117,T-1007 | done | Discord bot RCON now uses the shared structured `command_key + args` catalog and schema, raw command fallback is rejected server-side, and the bot API contract/tests return the built command plus `command_key` through the shared validation boundary |
| T-1120 | P10 | Rework whitelist detail UX around toggle state and warnings | T-1023,T-505,T-508 | done | The whitelist card now sits above generic server operations, uses a toggle-style `有効 / 無効` control, warns strongly when enabled with zero entries, keeps a persistent warning while disabled, and points to the existing add-player area instead of embedding a dense warning-adjacent form |
| T-1121 | P10 | Revisit index-detail primary action visibility using list/card UI best practices | T-503,T-505,T-512 | done | The server index now uses the card itself as the stable primary path to detail, with `詳細を見る` reduced to a supporting cue instead of a small right-edge control or oversized full-width button |

## Critical Path Tasks

The current critical path is:

`T-110 -> T-200 -> T-201 -> T-202 -> T-203 -> T-204 -> T-300 -> T-301 -> T-302 -> T-303 -> T-304 -> T-400 -> T-402 -> T-500 -> T-501 -> T-803 -> T-804 -> T-805 -> T-900 -> T-903 -> T-904 -> T-901 -> T-905 -> T-902 -> T-1000 -> T-1001 -> T-1002 -> T-1003 -> T-1004 -> T-1005 -> T-1006 -> T-1007 -> T-1008 -> T-1009 -> T-1010 -> T-1011 -> T-1012 -> T-1101 -> T-1100 -> T-1103 -> T-1104 -> T-1105 -> T-1106 -> T-1107 -> T-1102`

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
- `T-304`: direct-Docker defaults are fixed through env-backed `MinecraftPublicEndpoint`, `MinecraftRuntime`, the `itzg` runtime payload, compose defaults, and the dedicated env contract doc.
- `T-304`: the create-form `minecraft_version` value is runtime-version input passed through the container `VERSION` env contract rather than a Docker image tag.
- Local Compose now reads checked-in `.env` defaults for `LOCAL_UID`, `LOCAL_GID`, `DOCKER_GID`, and `MINECRAFT_RUNTIME_IMAGE`.
- `T-400`: `Servers::ProvisionServer` now creates a managed volume/container through `DockerEngine`, starts it, persists runtime state, and then publishes the route.
- `T-400`: create retries once with `DockerEngine#pull_image` when the selected runtime image is missing locally.
- `T-400`: container `MEMORY` now reserves JVM headroom below the Docker memory limit to avoid immediate OOM kill on boot.
- `T-803`: acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync flows against the direct-Docker baseline.
- `T-804`: compose-managed `mc-router` ingress is verified end-to-end on the shared public port after loading the generated routes.
- `T-805`: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after route rewrites, avoiding unreliable bind-mounted file-watch behavior.
- `T-805`: the compose-managed `mc-router` service now carries a stable Docker label so Rails can resolve the reload target without depending on generated container names.
- `T-804`: `compose.yaml` now defines a compose-managed `mc-router` service on the shared bridge network, and shared-port ingress has been verified against it.
- `T-900`: `README.md` now acts as the setup entrypoint, while `docs/single_host_setup.md` documents the external network prerequisite, local `.env` adjustments, Dockerized boot path, and bootstrap-owner flow for new contributors.
- `T-903` planning direction: `.env` stays untracked as the live local file, `.env.example` is the checked-in template, uncommented entries should be limited to required local/bootstrap values, and optional deploy-era keys should stay commented until needed.
- `T-904`: `docs/kamal_deployment_topology.md` fixed the original single-host Kamal shape, and `T-906` now updates that baseline so MariaDB is external, Redis remains the only Kamal accessory, `mc-router` stays a long-lived sibling service, and deploy env continues to map cleanly from local `.env`.
- `T-901`: `docs/operator_runbook.md` now documents the current usable deployment path, daily server operations, safe host-side inspection commands, and the Docker safety boundary around app-managed resources.
- `T-905`: the repo now ships `config/deploy.yml`, `config/deploy.production.yml`, `.kamal` hook and secret templates, plus `bin/deploy-mc-router` and `docker/mc-router/deploy.compose.yml` for the long-lived router sibling service.
- `T-903`: `.env.example` now keeps the local Compose and bootstrap-owner baseline uncommented, while optional Discord OAuth, bot, router-command, and Docker API override examples stay commented until needed.
- Future operator UI work should put current player count ahead of lower-priority metadata on server screens, and browser-side log viewing / bounded command execution should reuse the same Rails-owned trust boundary as bot-triggered commands.
- Future runtime-catalog work should cover standard Java-server selection, concrete version resolution for symbolic tags such as `latest`, and a documented decision on whether version choices are built dynamically or from a synchronized catalog.
- `T-1101`: create flow now exposes `runtime_family` as a user-facing choice, persists it through the legacy `template_kind` column for now, keeps `vanilla` (`Java Edition`) as the default, and provisions both runtime families through `itzg/minecraft-server`.
- `T-1100` / `T-1103`: a checked-in synchronized catalog file remains as the fallback source instead of live registry access or DB-backed storage.
- `T-1105` / `T-1106` / `T-1107`: create UI now resolves `vanilla` and `paper` version choices on the Rails side during page load, caches them briefly, falls back to the checked-in catalog, and exposes only the runtime-family-specific select choices without a freeform version field.
- `T-1107`: index/detail screens also show runtime `Type` alongside Minecraft version so the current runtime-family choice is visible after creation.
- `T-1107`: version option `label` is the Minecraft version text shown to operators, and submitted `value` is the stable version key sent through the runtime `VERSION` contract; Docker image tags are no longer shown as the primary user-facing value.
- `itzg/minecraft-server` nuance: the official docs use `TYPE` + `VERSION` as the Minecraft version selector, so runtime/version work must not assume image tag equals Minecraft version.
- The current live sources are `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` for `vanilla` and `https://qing762.is-a.dev/api/papermc` for `paper`.
- `T-1102`: servers now persist `resolved_minecraft_version` during create flow, using the runtime-family-specific live source or fallback catalog, and index/detail screens show that concrete version while still indicating symbolic selections such as `latest`.
- `T-401` / `T-402`: direct-Docker lifecycle/delete behavior is fixed in `docs/direct_docker_lifecycle_contract.md` before service replacement, including Docker-state mapping and tolerated `NotFound` cleanup.
- `T-401`: `Servers::DestroyServer` now unpublishes the route first, tolerates missing managed container/volume cleanup, and only destroys the DB record after Docker cleanup succeeds.
- `T-402`: `Servers::StartServer`, `StopServer`, `RestartServer`, and `SyncServerState` now use Docker Engine operations plus `inspect_container`-based reconciliation instead of `ExecutionProvider`.
- `T-500`: create page props are reduced to the direct-Docker baseline form fields and connection preview metadata, dropping fixed runtime/template display props from the controller contract.
- `T-501`: detail page now centers public connection target, router publication state, Docker runtime identifiers, and lifecycle actions without fixed template/provider framing.
- `T-502`: index page now summarizes public connection targets plus container/router state, and no longer depends on backend-oriented runtime labels from the listing payload.
- `T-503`: layout/create/index/detail copy is being shifted further toward Japanese, active server screens now hide Docker backend identifiers behind simpler player-facing status and connection language, the app shell has moved to a flat Minecraft-inspired dark theme with `/` routed directly to the server index, the header now shows the signed-in user's global role, shared navigation/member/invite copy is being localized, and create-form validation enforces a 4GB memory ceiling plus stricter hostname input rules.
- `T-508`: index/detail no longer show `応答状態` or router timestamp noise, and the detail page now separates primary connection/action cues from ownership/version information and lower-priority technical metadata without repeating the same facts in multiple sections.
- `T-509`: route publication failures are now audited against the rendered routes file and shown only when abnormal, with explicit warning UI instead of always-visible router metadata.
- `T-510`: transition-state polling now sends a dedicated poll header so the server detail endpoint performs `SyncServerState` during polling and the displayed status can converge without manual sync.
- `T-511`: route failure warnings now include the next user action, and authorized users can reapply publication directly from the detail page without leaving the current flow.
- Local env handling now treats `.env.example` as the checked-in template while `.env` stays untracked for machine-specific values.
- `T-205`: legacy provider dependency inventory now lives in `docs/provider_cleanup_inventory.md`.
- `T-700` / `T-702`: provider service classes, initializer, and dedicated provider tests are removed from the active code path.
- `T-703`: controller create flow no longer accepts or injects provider-era template input; `template_kind` is retained only as internal schema debt for now.
- Discord login direction is now fixed as Discord OAuth-only sign-in with manual invite URLs instead of local password distribution.
- Discord bot integration will call Rails-owned APIs for lifecycle and RCON operations; the bot must not talk to Docker or Minecraft containers directly.
- `T-1000`: the strategy contract for Discord auth, invite URLs, and bot mediated RCON now lives in `docs/discord_auth_and_bot_strategy.md`.
- `T-1014`: user-type hierarchy and create/invite quota policy now live in `docs/access_policy_and_quota_contract.md`; the active global types are `admin` / `operator` / `reader`, operator create quota is `5120 MB`, admins are unrestricted, and readers are read-only.
- `T-1001`: `users` now carry Discord identity fields, and Rails can complete a Discord OAuth callback to resolve already-linked users.
- `T-1002`: manual invite issuance now uses digest-only stored tokens; the raw invite URL is shown only once when an authenticated user creates the invite from `/discord-invitations`.
- `T-1003`: `/login` is now a Discord-only entry page with no email/password form, `/discord/login` guards the Discord OAuth start path before handing off to OmniAuth, invite-only signup still starts at `/invites/:token`, and bootstrap-owner startup logs can point the initial operator at `/login`.
- `T-1004`: invite redemption now begins at `/invites/:token`; a matching pending invite can create the first local user during the Discord OAuth callback, and mismatched or inactive invites are rejected.
