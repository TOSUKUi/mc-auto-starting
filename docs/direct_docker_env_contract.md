# Direct Docker Environment Contract

## Purpose
This document fixes the supported environment-variable contract for the current direct-Docker baseline after the env cleanup work through `T-907` and `T-908`.

## Template Policy
- The live `.env` file is local-only runtime data and must remain untracked.
- `.env.example` is the checked-in template and should list only the keys operators are expected to set.
- Fixed implementation choices belong in code or checked-in Compose config, not in operator-editable env.

## Required Local Compose Configuration
- `LOCAL_UID`
  Host user UID used to run the `app` container for writable bind mounts.
- `LOCAL_GID`
  Host user GID used to run the `app` container.
- `DOCKER_GID`
  Host Docker group GID added to the `app` container so Rails can use `/var/run/docker.sock`.
- `DB_HOST`
  Local MariaDB hostname for the app container. Default: `db`.
- `DB_PORT`
  Local MariaDB port. Default: `3306`.
- `DB_USERNAME`
  App MariaDB username. Default: `app`.
- `DB_PASSWORD`
  App MariaDB password. Default: `password`.
- `DB_ROOT_PASSWORD`
  MariaDB root password for the local Compose database container. Default: `rootpassword`.
- `DB_NAME_DEVELOPMENT`
  Development database name. Default: `mc_auto_starting_development`.
- `DB_NAME_TEST`
  Test database name. Default: `mc_auto_starting_test`.
- `MINECRAFT_PUBLIC_DOMAIN`
  Public DNS suffix used to build `<hostname>.<public_domain>`.
- `MINECRAFT_PUBLIC_PORT`
  Shared public Minecraft ingress port shown to users and published by `mc-router`.
- `DISCORD_CLIENT_ID`
  Discord OAuth application client id used by browser login.
- `DISCORD_CLIENT_SECRET`
  Discord OAuth application client secret used by browser login.
- `APP_BASE_URL`
  Public base URL used by login hints and production deploy config. Keep `http://localhost:3000` locally unless you deliberately front the app on another origin.

## One-Time Bootstrap Configuration
- `BOOTSTRAP_DISCORD_USER_ID`
  Discord user id used by `bin/rails db:seed` to create the initial owner.
- `BOOTSTRAP_DISCORD_USERNAME`
  Discord username used during initial owner seeding.

## Optional Configuration
- `DB_NAME_PRODUCTION`
  Production database name used by production Compose env and any production-mode maintenance commands. Default fallback: `mc_auto_starting_production`.
- `DOCKER_ENGINE_API_VERSION`
  Optional Docker Engine API version prefix used only when the host daemon needs an explicit `/v1.xx` override.
- `DISCORD_BOT_API_TOKEN`
  Shared bearer token for the internal `/api/discord/bot/*` surface. Set it when the external bot relay is in use.
- `RAILS_LOG_LEVEL`
  Rails log level. Default: `info`.

## Required Production Secrets
- `SECRET_KEY_BASE`
  Required Rails production secret used for cookies, sessions, and message verification when the app boots without credentials.
- `MINECRAFT_RCON_PASSWORD_SECRET`
  Required production secret used to derive stable per-server RCON passwords. The app no longer falls back to `secret_key_base`.

## Fixed Internal Configuration
- Docker socket path is fixed to `/var/run/docker.sock`.
- Docker Engine timeouts are fixed to open `5s`, read `30s`, write `30s`.
- The managed Minecraft runtime image family is fixed to `itzg/minecraft-server`.
- The shared Docker network name is fixed to `mc_router_net`.
- Local route output path is fixed to `tmp/mc-router/routes.json`; production uses `/rails/shared/mc-router/routes.json`.
- `mc-router` reload is fixed to Docker signal mode with `HUP`, targeting containers labeled `app.kubos.dev/component=mc-router`.
- `mc-router` itself is fixed to the `itzg/mc-router` image in checked-in Compose files.
- Runtime version sources are fixed to Mojang for `vanilla` and the Paper source for `paper`, with a `300s` cache TTL.
- Rails-owned RCON uses fixed transport defaults: port `25575`, connect timeout `5s`, command timeout `5s`, segmented-response wait `0.15s`.
- The bot API CIDR allowlist is fixed to `172.16.0.0/12`.

## Compose Baseline
- Local development should keep the supported runtime configuration in a local `.env` file copied from `.env.example` so `docker compose up` and one-off `docker compose run` commands share the same values consistently.
- `compose.yaml` uses `.env` as the source for operator-settable values only: database connection, public ingress values, Discord OAuth, first-owner seeding, and the optional bot/RCON secrets.
- The Rails `app` service mounts `/var/run/docker.sock`.
- `mc-router` is a compose-managed sibling service, not a container created by Rails.
- The `mc-router` compose service publishes `${MINECRAFT_PUBLIC_PORT}:25565`.
- The shared `mc_router_net` network is an external named bridge network so compose-managed `mc-router` can join the same network as Rails-created Minecraft containers.
- The Rails `app` service joins the host Docker group via `group_add`, using the host Docker group GID from `DOCKER_GID`.
- On Linux development hosts, derive `DOCKER_GID` from the `docker` group, for example with `grep '^docker:' /etc/group | cut -d: -f3`.

## App Usage Contract
- `MinecraftPublicEndpoint` is the single source of truth for public FQDN and connection-target formatting.
- `MinecraftRuntime` is the single source of truth for the fixed runtime image family, shared bridge network name, fixed version-source URLs, and per-family container env payload.
- `MinecraftRuntime` resolves both `paper` and `vanilla` against the fixed `itzg/minecraft-server` baseline, switching only the `TYPE` env value.
- `MinecraftRuntime` also enables RCON and `ENABLE_WHITELIST=TRUE` for managed servers, and injects the per-server `RCON_PASSWORD` derived by `MinecraftRcon`.
- `MinecraftRuntime` also projects the persisted desired whitelist state into container env through `ENABLE_WHITELIST`, `WHITELIST`, and `EXISTING_WHITELIST_FILE=SYNCHRONIZE`.
- Production boot should not depend on Rails credentials, `config/master.key`, or `RAILS_MASTER_KEY`; all app secrets are expected to come from direct env or deploy-orchestrator secret injection.
- The create form separates `runtime_family` from `minecraft_version`; `minecraft_version` is runtime-version input passed through the container `VERSION` contract rather than a Docker image tag.
- `INIT_MEMORY` and `MAX_MEMORY` are both set from the selected `memory_mb`, so the form value becomes the Minecraft JVM `Xms`/`Xmx`.
- Docker container memory is derived from the selected JVM heap so `memory_mb` uses 70% of the Docker limit rather than matching it one-to-one.
- `DockerEngine` reads only the optional API version override.
- `Router` reads only the fixed route file and fixed reload wiring.
- `MinecraftRcon` is the single source of truth for RCON host/port/password derivation.
- `Servers::StartServer` recreates the managed container before boot so the latest desired env, including staged whitelist settings, is applied to stopped servers.

## Non-Goals
- Per-server host port publishing is not supported.
- DNS automation and SRV record management remain out of scope.
- Image build configuration is not part of the supported env contract.
