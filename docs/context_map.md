# Context Map

## Purpose
This file tells any contributor or agent where to find authoritative information after a context reset.

## Read First
- `AGENTS.md`

## Architecture and Implementation Design
- `docs/single_host_setup.md`
  Use for the single-host bootstrap path, local Docker/Compose setup, and the day-1 development workflow fixed by `T-900`.
- `docs/operator_runbook.md`
  Use for the current operator-facing deploy procedure, host-side verification commands, direct-Docker safety notes, and day-2 operations fixed by `T-901`.
- `docs/release_runbook.md`
  Use for the Kamal-based release, migration, and rollback procedure fixed by `T-902`.
- `docs/kamal_deployment_topology.md`
  Use for the single-host Kamal deployment shape, accessory strategy, secret injection path, and `.env` to deploy-time env mapping fixed by `T-904`.
- `config/deploy.yml`
  Use for the checked-in Kamal base configuration added in `T-905`.
- `config/deploy.production.yml`
  Use for the single-host production destination, proxy host, and web host mapping added in `T-905`.
- `docs/implementation_breakdown.md`
  Use for the active `Rails + docker.sock` single-host architecture, screen list, data model, and service decomposition.
- `docs/access_policy_and_quota_contract.md`
  Use for the active global user types, server-local `viewer` / `manager` roles, invitation authority, ownership-vs-membership authorization rules, and the operator-scoped `5120 MB` server-create quota fixed by `T-1014`.
- `docs/whitelist_and_access_control_strategy.md`
  Use for the whitelist-over-RCON plan and whitelist authority boundary fixed by `T-1020`.
- `docs/server_ui_display_review.md`
  Use for the agreed display contract for the server index/detail screens, including owner-name display, lifecycle-action visibility, transition-state polling expectations from `T-505`, and the next de-dup/layout cleanup plan captured in `T-508`.
- `docs/player_observability_and_browser_console_contract.md`
  Use for the player-count, recent-log, and browser bounded-command contract fixed by `T-1010`.
- `docs/provider_cleanup_inventory.md`
  Use for the legacy provider dependency inventory and the remaining schema/doc cleanup debt after `T-700` / `T-702` / `T-703`.
- `docs/docker_engine_contract.md`
  Use for the direct Docker Engine wrapper scope, shared bridge network rules, and managed resource conventions.
- `docs/direct_docker_env_contract.md`
  Use for the required env vars and config defaults for Docker transport, public endpoint rendering, runtime image, and router publication.
- `docs/direct_docker_lifecycle_contract.md`
  Use for the direct-Docker lifecycle, sync, and delete contract before implementing `T-401` through `T-403`.
- `docs/discord_auth_and_bot_strategy.md`
  Use for the authoritative Discord OAuth, manual invite URL, and Discord Bot to Rails to RCON strategy fixed by `T-1000`.
- `docs/discord_bot_api_contract.md`
  Use for the concrete bot credential, acting-user, endpoint, command-scope, whitelist-scope, and response-envelope contract fixed by `T-1005`.
- `docs/project_execution_plan.md`
  Use for the active phase ordering, dependency flow, milestones, and critical path.
- `docs/task_board.md`
  Use for the active `direct-Docker + mc-router` task system.

## Historical / Superseded References
- `docs/provider_api_contract.md`
  Historical reference from the abandoned Pterodactyl/Wings approach. Not current architecture.
- `docs/provider_template_env_setup.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/provider_router_operations.md`
  Historical reference from the abandoned external-provider approach. Not current architecture.
- `docs/router_api_contract.md`
  Active reference for the retained `mc-router` ingress contract.

## Disposable Session Context
- `.local/session_context.md`
  Use for temporary restart notes, recent findings, in-flight command plans, and handoff notes that should not be committed.

## Bootstrap / Environment Files
- `Dockerfile`
- `compose.yaml`
- `.env`
- `.env.example`
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
- Authenticated layout and current login/index/create/detail/members UI baselines already exist; the active server create/detail/index screens are direct-Docker-first.
- The planning pivot task `T-110` is complete.
- `T-200` is complete: `minecraft_servers` now has direct-Docker baseline fields for managed container/volume identity and runtime state.
- `T-201` through `T-204` are complete: hostname slug normalization, FQDN/public-port connection formatting, status transitions, and `router_routes` publication responsibilities are fixed in code.
- `T-302` is complete: Docker Engine access is wrapped behind `DockerEngine::Connection`, `DockerEngine::Client`, `DockerEngine::ManagedLabels`, and `DockerEngine::ManagedName`.
- `T-302` defaults to unversioned Docker Engine API paths so local daemons do not need to support a hard-coded minimum API version.
- The active architecture is now `Rails + docker.sock + mc-router` for single-host Minecraft container management.
- `Pterodactyl/Wings` are no longer the current target architecture, but `mc-router` remains active.
- `mc-router` and app-managed Minecraft containers are expected to share one bridge network, with router backends addressed by container name.
- `T-303` is complete: route publication apply/rollback is centralized and reused by the existing create/delete-era services.
- `T-304` is complete: Docker transport, public endpoint, runtime image/network, the `itzg` runtime payload, and router file/reload defaults are fixed in env-backed helpers and docs.
- The create-form `minecraft_version` field is runtime-version input passed through the container `VERSION` contract rather than a Docker image tag.
- `MinecraftRuntime` now derives container `MEMORY` below the Docker limit so the server keeps JVM headroom.
- Local Compose bootstrap now includes checked-in `.env` defaults for `LOCAL_UID`, `LOCAL_GID`, `DOCKER_GID`, and `MINECRAFT_RUNTIME_IMAGE`.
- `T-400` is complete: the create job now provisions managed Docker resources, persists runtime state, and publishes the `mc-router` mapping.
- `T-400` now pulls the selected runtime image on demand when Docker create fails with `No such image`.
- The direct-Docker lifecycle/delete contract is now fixed in `docs/direct_docker_lifecycle_contract.md` ahead of service replacement work.
- `T-401` and `T-402` are complete: delete/start/stop/restart/sync now use Docker Engine instead of the legacy provider path.
- `T-403` is complete: manual sync now also reconciles `last_started_at` from Docker inspect so runtime timestamps and error state stay aligned.
- `T-404` is complete: operator create requests are now quota-limited by owned `memory_mb` total `<= 5120`, the server-side create flow rejects over-quota requests, and the create UI shows current usage plus remaining quota.
- `T-500` is complete: create UI now exposes only the direct-Docker baseline inputs and the public connection preview contract.
- `T-501` and `T-502` are complete: detail/index UI now center connection targets and publication data, while current active screens de-emphasize Docker backend identifiers.
- `T-503` is complete: operator-facing copy and layout are now aligned to a Japanese-first, simpler presentation across the active path; the unused home page is gone in favor of routing `/` to the server index, the active app shell uses the flat Minecraft-inspired dark theme, the header exposes the signed-in user's global role, shared navigation/member/invite copy is localized, the server create form caps memory at 4GB while blocking invalid hostname characters earlier, the default runtime choice is `Java Edition`, create-page validation errors stay visible after 422 responses, the create/detail/index/invite/membership/login surfaces have dropped most self-evident helper text, the login page now keeps only the page label plus a short service summary and a single `Discordでログイン` action, the server index exposes an explicit `詳細を見る` action instead of relying on the name link alone, and the detail screen moves startup-settings save actions into the card header.
- The next `T-503` pass is now scoped by `docs/ui_polish_audit_strategy.md`, which fixes a page-by-page audit across login, create, detail, membership, invite, and the remaining active surfaces before more visual changes land.
- `T-512` is complete: the page-by-page keep/remove/unify inventory now lives in `docs/ui_polish_audit_inventory.md`, covering login, create, detail, membership, invite, index, and the shared shell before the next UI edits start.
- `T-513` is complete: `/login` now uses the same dark visual system as the authenticated control plane, the earlier split-screen auth-specific presentation is gone, and the page keeps only the Discord sign-in path plus minimal invite guidance.
- Inertia logout and unauthenticated redirects now use `X-Inertia-Location` when targeting the non-Inertia `/login` page, so logout/session-expiry flows no longer surface the login page as a modal-like invalid Inertia response.
- `T-505` is complete: the agreed index/detail display contract in `docs/server_ui_display_review.md` is now reflected in the active screens, including Discord-based owner labels and an uptime-oriented detail summary.
- `T-508` is complete: index/detail no longer show `応答状態` or router timestamp noise, and the detail layout now separates primary connection/action cues from ownership/version information and lower-priority technical metadata without repeating the same facts.
- `T-509` is complete: route publication failures are now audited against the rendered routes file and shown only when abnormal, instead of keeping router internals visible all the time.
- `T-510` is complete: transition-state polling now triggers backend reconciliation during detail-page polling, so `starting` / `stopping` / `restarting` can converge without manual sync.
- `T-511` is complete: publication-failure warnings now tell the user the next step, and authorized users can reapply publication directly from the server detail page.
- `T-205`, `T-700`, `T-702`, and `T-703` are complete: provider inventory is documented, provider services/initializer/tests are removed, and create requests no longer expose provider-era template input.
- `T-701` is complete: legacy provider design docs are explicitly historical references and no longer sit in the active restart path.
- `T-803` is complete: acceptance coverage now verifies the main create/detail/delete/start/stop/restart/sync paths against the direct-Docker baseline.
- `T-800` through `T-802` are complete: model, request/authorization, and Docker/router/server service coverage now exist for the direct-Docker baseline, so the earlier P7 test-hardening placeholders no longer represent open work.
- `compose.yaml` now defines a compose-managed `mc-router` service on the shared `mc_router_net` bridge network.
- `T-804` is complete: a live status ping through the shared public port reached a managed Minecraft server after `mc-router` loaded the generated routes.
- `T-805` is complete: Rails now reloads the compose-managed `mc-router` explicitly with `SIGHUP` after route rewrites, so live ingress updates no longer depend on bind-mounted file-watch behavior.
- `T-900` is complete: the single-host bootstrap path, external network prerequisite, local `.env` handling, and Dockerized development workflow are now documented for new contributors.
- `T-904` is complete: the single-host Kamal deployment topology, accessory strategy, secret-file split, shared router-routes mount, and local `.env` to deploy env mapping are now fixed in docs before implementation.
- `T-901` is complete: the current operator runbook now covers the usable Compose-based single-host deployment path, UI-driven lifecycle operations, host-side verification commands, and direct-Docker safety boundaries.
- `T-905` is complete: the repository now includes an initial Kamal base config, a production destination config, `.kamal` secret templates and hooks, and an `mc-router` deploy helper for the long-lived sibling service.
- `T-902` is complete: the Kamal-based release, migration, and rollback path now lives in `docs/release_runbook.md`.
- The runtime version-source/display contract cleanup through `T-1104` is complete; no remaining critical-path task depends on that contract row.
- The earlier server-screen follow-up tasks `T-505`, `T-506`, and `T-507` are now complete; `docs/server_ui_display_review.md` remains the display-contract reference for any future server-screen cleanup.
- `T-504` is complete: the server index now prefers the owner's Discord display identity over `email_address`, using `discord_global_name`, then `discord_username`, then a fixed fallback label.
- `T-506` is complete: server detail responses now gate lifecycle actions by current server status so `ready` only shows stop/restart, `stopped` shows start, and transitional/degraded states converge on sync-only controls.
- `T-507` is complete: the server detail page now polls only while `starting`, `stopping`, or `restarting`, and the status badge shows a simple spinner instead of timestamps or countdown-style progress.
- `T-1013` is complete: Discord OAuth now requests only `identify`, bootstrap/invite/login flows no longer persist email fields, and the remaining member-management UI resolves users by `discord_user_id` instead of email lookup.
- `T-1014` is complete: global user types, server-local `viewer` / `manager` roles, invitation authority, ownership-vs-membership authorization rules, and the operator-scoped `5120 MB` create quota are now fixed in `docs/access_policy_and_quota_contract.md`.
- `T-1015` is complete: `users.user_type` now carries the global `admin` / `operator` / `reader` role, existing rows are backfilled to `operator`, new records default to `reader`, and shared controller/policy code can resolve the global type independently from server membership.
- `T-1019` is complete: server-local membership terminology now uses `manager` instead of `operator`, so membership roles no longer collide with the global `operator` user type.
- `T-1016` is complete: invitation issuance now stores the invited global user type, admins can invite `admin` / `operator` / `reader`, operators can invite only `reader`, readers are denied at the policy/controller layer, and invite-based first login now applies the invited global role to the created user.
- `T-1017` is complete: server create authorization is now enforced at the policy/controller layer so `admin` and `operator` can open the create flow, while `reader` is denied before request handling reaches provisioning logic.
- `T-1018` is complete: server authorization now combines global type and server-local membership so `admin` has full visibility/management, `manager` membership grants lifecycle access, `viewer` grants read-only visibility, and destroy/member-management remain owner-or-admin only.
- `T-1020` is complete: whitelist planning now fixes Rails-owned RCON whitelist mutations and their authority boundary in `docs/whitelist_and_access_control_strategy.md`.
- `T-1006` is complete: Rails now has an app-owned RCON connection layer, managed containers enable RCON by default, and per-server RCON passwords are derived from a stable secret plus server identity instead of being stored as plain DB fields.
- Managed runtime env now also defaults `ENABLE_WHITELIST=TRUE`, so newly provisioned servers enforce whitelist mode from first boot.
- `T-1021` is complete: Rails now has a bounded whitelist service over RCON for list/add/remove/on/off/reload operations against running managed servers, explicitly loads `rconrb`, and authenticates with the Minecraft-compatible `ignore_first_packet` handling.
- `T-1022` is complete: whitelist endpoints are now controller/policy-gated to admins and owners, and request/service coverage includes unauthorized access plus stopped-server and RCON-failure handling.
- `T-1023` is complete: server detail now includes an owner/admin whitelist card backed by persisted desired whitelist state; running servers apply changes immediately through RCON, stopped servers stage changes that are applied on the next start because `StartServer` recreates the container with current env, the detail page no longer re-fetches whitelist data on every render, whitelist mutations now re-sync only the whitelist card while safely rejecting non-JSON restart/redirect responses, and whitelist entries are shown with code-like monospace styling to reduce case-misread risk.
- `T-1025` is complete: raw-socket verification showed this Minecraft runtime returns a single auth packet, so RCON auth now uses `ignore_first_packet: false`; `WhitelistManager` now reads response bodies instead of object inspection; `start` and `restart` both recreate the managed container so saved whitelist env is reapplied; live verification against `muuchannel` confirmed DB state, `WHITELIST`, `/data/whitelist.json`, and RCON `whitelist list` can agree; and immediate-apply failures now return a clear saved-but-not-live-applied message.
- A later runtime-catalog track is planned starting with `T-1101`, then `T-1100` through `T-1103`, to cover Java runtime family selection first, then `latest` version resolution and dynamic or synchronized version-choice sourcing.
- `T-1101` is complete: server create flow now offers runtime family selection, defaults to `vanilla` (`Java Edition`), and both runtime families provision through `itzg/minecraft-server`.
- `T-1100` and `T-1103` are complete: a checked-in `config/minecraft_runtime_catalog.yml` file remains as the fallback version source rather than live registry access or DB-backed storage.
- `T-1105` through `T-1107` are complete: the create UI resolves runtime-family-specific version choices on the Rails side when the page opens, caches them briefly, falls back to the checked-in catalog, and exposes only the runtime-family-specific select choices without a freeform version field.
- Index/detail screens now show both Minecraft version and runtime `Type`, keeping the operator-facing display aligned with the new runtime-family model.
- The UI now shows stable Minecraft version labels instead of Docker image tags; submitted values are stable version keys, with `latest` remaining a special symbolic option.
- `T-1104` is complete: the contract row is now aligned with the shipped behavior, fixing Mojang manifest for `vanilla`, the Paper-specific source for `paper`, and the `label` / submitted `value` / persisted `resolved_minecraft_version` split as the authoritative display model.
- `T-1110` is complete: startup-setting candidates are now grouped in `docs/server_startup_settings_candidates.md`, with the first recommended batch centered on `hardcore`, `difficulty`, `max_players`, `motd`, `pvp`, and `gamemode`.
- `T-1110` also fixes the startup-settings candidate scope and enum-like value expectations such as `difficulty` / `gamemode` defaulting to `Select`-style inputs where editing exists.
- `T-1111` through `T-1113` are complete: `minecraft_servers` now persists baseline startup settings, the create flow captures them, and the bot/detail read surface can return those initial values.
- `T-1114` is complete: startup settings are now treated as create-time defaults plus read-only initial values on detail/bot surfaces, while mutable live-setting changes move to structured allowlisted RCON actions instead of Rails desired-state updates.
- `T-1115` is complete: active create/invite/member/browser-RCON input paths now have matching server-side rejection for unsupported create versions, invalid membership roles, invalid Discord user IDs, and raw browser RCON command fallback, with request/model/service coverage backing the visible validation.
- `T-1116` through `T-1119` remain the next RCON-UX follow-up: mutable live-setting changes should stay out of DB-backed desired state, while detail and bot move toward a shared structured `command_key + args` catalog with schema-driven forms and player-target patterns such as `gamemode(mode, player_name)`.
- `T-1116` is complete: `docs/structured_rcon_command_catalog.md` now fixes the shared structured RCON command catalog and argument schema, including player-target patterns such as `gamemode(gamemode, player_name)`, before backend and UI implementation continue.
- `T-1117` is complete: the server-side structured command builder now exists in `Servers::StructuredRconCommand`, allowing the web detail controller path to validate `command_key + args` payloads and turn them into bounded RCON commands without persisting mutable live settings as Rails desired state.
- `T-1118` is complete: the browser detail RCON UI now uses a single command select plus schema-driven argument form and shared result area instead of the earlier card-per-command layout.
- `T-1120` is complete: whitelist detail UX now sits above server operations, uses a toggle-style mode switch, warns strongly when enabled with zero entries, keeps a persistent warning while disabled, and guides the user toward the existing add-player section instead of embedding another form into the warning.
- `T-1121` is complete: the index now treats each server card itself as the stable primary path to detail, while `詳細を見る` remains only as a supporting cue instead of a small right-edge button.
- The current startup-settings detail presentation now treats startup settings as read-only initial values, while real-time mutable operations live on the structured RCON surface.
- For `itzg/minecraft-server`, the official docs treat Minecraft version selection as the `TYPE` + `VERSION` container contract, not as a guarantee that image tag equals Minecraft version; keep that distinction in mind when touching `T-1102` and later runtime work.
- `T-1102` is complete: servers now persist `resolved_minecraft_version`, so list/detail screens can show a concrete numeric Minecraft version even when the stored selection is `latest`.
- The current live sources are Mojang's `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` for `vanilla` and `https://qing762.is-a.dev/api/papermc` for `paper`.
- The selected future auth direction is Discord OAuth-only login plus manually issued invite URLs, not distributed local passwords.
- The selected future bot direction is Discord Bot -> Rails API -> lifecycle/RCON execution, not direct bot access to Docker or containers.
- `docs/discord_auth_and_bot_strategy.md` is the strategy-level source of truth for the future Discord auth and bot track.
- `docs/discord_operator_runbook.md` is the operator-facing setup and troubleshooting entry point for Discord OAuth login, invite issuance, and the internal bot relay.
- `T-1005` is complete: `docs/discord_bot_api_contract.md` now fixes the bot credential model, acting Discord-user resolution, allowed lifecycle/read/whitelist commands, request/response envelopes, and audit expectations before endpoint implementation.
- `T-1024` is complete: the bot contract now keeps whitelist mutations owner/admin-only, treats `whitelist_list` as a read-class surface, and separates bounded RCON input from lifecycle/server-operation commands so forbidden commands such as `stop` are never accepted through the RCON path.
- Bot API network policy is now fixed at the strategy layer: `/api/discord/bot/*` should be reachable only from the Docker private network, while still requiring the dedicated bot bearer token.
- `T-1007` is complete: Rails now has the bot-side API under `/api/discord/bot/*`, including bot bearer auth, acting Discord-user resolution, Docker-private-network route gating, policy-checked status/lifecycle/whitelist endpoints, and owner/admin-only bounded RCON commands.
- `T-1008` is complete: Discord auth, invite redemption, and bot-command controller coverage now includes invite mismatch/revocation paths, invalid/expired invite access, bot network/token/user rejection, and whitelist/RCON failure cases.
- `T-1009` is complete: operator-facing setup and troubleshooting guidance for Discord OAuth, invite issuance, and the internal bot relay now lives in `docs/discord_operator_runbook.md`.
- `T-1010` is complete: player count now has an RCON-based read contract, recent logs are fixed as a Docker-log read surface, and browser bounded-command input is fixed to the same allowlist boundary as the bot in `docs/player_observability_and_browser_console_contract.md`.
- `T-1011` is complete: server index and detail now surface RCON-derived player counts when available, and the detail view refreshes player presence separately from the rest of the page.
- `T-1012` is complete: server detail now exposes a manual-refresh recent-log panel for any visible user, while owner/admin users can execute the same bounded RCON command set as the bot with inline success/failure feedback and forbidden-command blocking.
- `T-1001` is complete: `users` now store Discord identity fields, OmniAuth Discord is wired into the app, and linked users can complete the Discord OAuth callback into a normal Rails session.
- `T-1002` is complete: `discord_invitations` now stores digest-backed manual invite records, authenticated users can issue/revoke invites from `/discord-invitations`, and raw invite URLs are shown only at issuance time.
- `T-1003` is complete: `/login` is now a Discord-only entry page for existing users, `/discord/login` guards the OAuth handoff so misconfigured Discord env returns safely to `/login`, local password and password-reset routes are no longer part of the active path, and bootstrap-owner startup logs can surface the first `/login` link when Discord OAuth and bootstrap env are configured.
- `T-1004` is complete: invite redemption now starts at `/invites/:token`, pending invite tokens are held in the Rails session, and Discord OAuth callbacks can create/link the invited user on first login.
- Initial operator bootstrap should use `BOOTSTRAP_DISCORD_USER_ID=... bin/rails db:seed`, then follow the startup `/login` hint to sign in through Discord before invite-based onboarding takes over.
- Local configuration should now be driven from `.env`, using `.env.example` as the checked-in template; required local/bootstrap keys stay active there, while non-required Discord, bot, router-command, and deploy-era examples stay commented until needed.
