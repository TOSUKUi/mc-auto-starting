# Direct Docker Environment Contract

## Purpose
This document fixes the initial environment and configuration contract for the direct-Docker baseline in task `T-304`.

## Template Policy
- The live `.env` file is local-only runtime data and must remain untracked.
- `.env.example` is the checked-in template and should be the authoritative inventory of supported keys.
- Keys required for the current local bootstrap path should stay uncommented in `.env.example`.
- Keys that are not required for the current local bootstrap path should be kept as commented examples in `.env.example` until the feature or deploy path is active.
- The bootstrap-owner Discord seed variables remain part of the required local bootstrap set so the initial operator can sign in before invite-based onboarding takes over.

## Required Runtime Configuration
- `DOCKER_ENGINE_SOCKET_PATH`
  Path to the Docker Engine Unix socket visible from the Rails app. Default: `/var/run/docker.sock`.
- `DOCKER_ENGINE_OPEN_TIMEOUT`
  Socket open timeout in seconds. Default: `5`.
- `DOCKER_ENGINE_READ_TIMEOUT`
  Read timeout in seconds. Default: `30`.
- `DOCKER_ENGINE_WRITE_TIMEOUT`
  Write timeout in seconds. Default: `30`.
- `MINECRAFT_PUBLIC_DOMAIN`
  Public DNS suffix used to build `<hostname>.<public_domain>`. Default: `mc.tosukui.xyz`.
- `MINECRAFT_PUBLIC_PORT`
  Shared public Minecraft ingress port shown to users. Default: `42434`.
- `MINECRAFT_RUNTIME_IMAGE`
  Baseline Minecraft container image family used by create flow and UI previews. Default: `itzg/minecraft-server`.
- `MINECRAFT_RUNTIME_VANILLA_IMAGE`
  Optional override for the standard Java server image family used when the create flow selects the `vanilla` runtime family. Default: `itzg/minecraft-server`.
- `MINECRAFT_RUNTIME_VANILLA_VERSION_MANIFEST_URL`
  Optional override for the live `vanilla` version source. Default: `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json`.
- `MINECRAFT_RUNTIME_PAPER_VERSION_MANIFEST_URL`
  Optional override for the live `paper` version source. Default: `https://qing762.is-a.dev/api/papermc`.
- `MINECRAFT_RUNTIME_VERSION_OPTIONS_CACHE_TTL`
  Cache TTL in seconds for runtime-family version choices fetched during create-page load. Default: `300`.
  The `itzg/minecraft-server` image family uses `TYPE` + `VERSION` to resolve the actual Minecraft server build, so do not assume the Docker image tag itself equals the Minecraft version.
- `MC_ROUTER_IMAGE`
  Compose-managed `mc-router` image. Default: `itzg/mc-router`.
- `MINECRAFT_RUNTIME_NETWORK_NAME`
  Shared bridge network name joined by `mc-router` and app-managed Minecraft containers. Default: `mc_router_net`.
- `MC_ROUTER_ROUTES_CONFIG_PATH`
  App-visible path where Rails writes the full desired `mc-router` routes JSON. Default: `tmp/mc-router/routes.json` under the app root.
- `MC_ROUTER_RELOAD_STRATEGY`
  Router reload mode after config write. Allowed values: `watch`, `command`, `docker_signal`, `manual`. Default: `docker_signal`.

## Conditionally Required Configuration
- `DOCKER_ENGINE_API_VERSION`
  Optional Docker Engine API version prefix used by the wrapper. Default: unset, which keeps requests unversioned. Set it only when a deployment needs an explicit `/v1.xx` override.
- `MC_ROUTER_RELOAD_COMMAND`
  Required when `MC_ROUTER_RELOAD_STRATEGY=command`.
- `MC_ROUTER_RELOAD_SIGNAL`
  Required when `MC_ROUTER_RELOAD_STRATEGY=docker_signal`. Default: `HUP`.
- `MC_ROUTER_RELOAD_CONTAINER_LABELS`
  Required when `MC_ROUTER_RELOAD_STRATEGY=docker_signal`. Comma-separated Docker label filters that uniquely identify the compose-managed `mc-router` container.
- `MC_ROUTER_API_URL`
  Optional operational endpoint for future router inspection or tooling.
- `DISCORD_CLIENT_ID`
  Discord OAuth application client id used by OmniAuth. Default: unset.
- `DISCORD_CLIENT_SECRET`
  Discord OAuth application client secret used by OmniAuth. Default: unset.
- `APP_BASE_URL`
  Optional public app base URL used for startup login hints such as `http://localhost:3000/login`. Default: unset in production, `http://localhost:3000` fallback in development.
- `BOOTSTRAP_DISCORD_USER_ID`
  Optional Discord user id used by `bin/rails db:seed` to create the initial owner. Default: unset.
- `BOOTSTRAP_DISCORD_USERNAME`
  Optional Discord username used during bootstrap seeding. Default: unset.
- `BOOTSTRAP_EMAIL_ADDRESS`
  Optional fallback local email used during bootstrap seeding. Default: unset.
- `DISCORD_BOT_TOKEN`
  Reserved for the future Discord bot process and local integration testing. Default: unset.
- `DISCORD_BOT_PUBLIC_KEY`
  Reserved for the future Discord interactions verification path. Default: unset.
- `DISCORD_BOT_APPLICATION_ID`
  Reserved for future Discord bot setup and command registration. Default: unset.
- `DISCORD_BOT_SHARED_SECRET`
  Reserved for future bot-to-Rails machine authentication. Default: unset.
- `DB_HOST`
  Database host. Default: `db`.
- `DB_PORT`
  Database port. Default: `3306`.
- `DB_USERNAME`
  Database username. Default: `app`.
- `DB_PASSWORD`
  Database password. Default: `password`.
- `DB_ROOT_PASSWORD`
  MariaDB root password used by local Compose. Default: `rootpassword`.
- `DB_NAME_DEVELOPMENT`
  Development database name. Default: `mc_auto_starting_development`.
- `DB_NAME_TEST`
  Test database name. Default: `mc_auto_starting_test`.
- `DB_NAME_PRODUCTION`
  Production database name. Default: `mc_auto_starting_production`.
- `RAILS_LOG_LEVEL`
  Rails log level. Default: `info`.

## Compose Baseline
- Local development should keep the full runtime configuration in a local `.env` file copied from `.env.example` so `docker compose up` and one-off `docker compose run` commands share the same values consistently.
- `compose.yaml` now uses `.env` as the single local source for Rails, MariaDB, Docker transport, Discord OAuth, bootstrap owner seeding, and future bot-related secrets.
- `.env.example` should leave only the current local/bootstrap baseline uncommented; optional Discord OAuth, bot, and deployment-only overrides should stay commented until they are needed.
- The Rails `app` service mounts `/var/run/docker.sock`.
- `mc-router` is expected to be a compose-managed sibling service, not a container created by Rails.
- The `mc-router` compose service should carry a stable label such as `app.kubos.dev/component=mc-router` so Rails can target reloads without relying on generated container names.
- The `mc-router` compose service should publish `${MINECRAFT_PUBLIC_PORT}:25565` and read the shared routes file via a bind mount such as `./tmp/mc-router:/config`.
- The shared `MINECRAFT_RUNTIME_NETWORK_NAME` network is treated as an external named bridge network so compose-managed `mc-router` can join the same network as Rails-created Minecraft containers.
- The Rails `app` service should join the host Docker group via `group_add`, using the host Docker group GID from `DOCKER_GID`.
- On Linux development hosts, derive `DOCKER_GID` from the `docker` group, for example with `grep '^docker:' /etc/group | cut -d: -f3`.
- The Rails `app` service should export the direct-Docker defaults above unless deployment overrides them.
- The Rails `app` service should leave `DOCKER_ENGINE_API_VERSION` unset unless the target daemon requires an explicit override.
- The same `MINECRAFT_RUNTIME_NETWORK_NAME` value must be used by both Rails and the eventual `mc-router` service definition.
- On the current local bind-mount setup, live file-watch pickup was unreliable, so the active baseline is explicit `SIGHUP` reload against the compose-managed `mc-router` container after each config write.

## App Usage Contract
- `MinecraftPublicEndpoint` is the single source of truth for public FQDN and connection-target formatting.
- `MinecraftRuntime` is the single source of truth for the baseline runtime image, shared bridge network name, live version-source URLs, and per-family container env payload.
- `MinecraftRuntime` resolves both `paper` and `vanilla` against the `itzg/minecraft-server` image family, switching only the `TYPE` env value.
- The create form now separates `runtime_family` from `minecraft_version`; `minecraft_version` is runtime-version input passed through the container `VERSION` contract rather than a Docker image tag.
- `MEMORY` is derived from the selected container memory with reserved JVM headroom; it is not equal to the Docker memory limit.
- `DockerEngine` reads only Docker transport settings.
- `Router` reads only route file and reload settings.

## Non-Goals
- Per-server host port publishing is not supported.
- DNS automation and SRV record management remain out of scope.
- Image build configuration is not part of the initial env contract.
