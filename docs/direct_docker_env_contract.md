# Direct Docker Environment Contract

## Purpose
This document fixes the initial environment and configuration contract for the direct-Docker baseline in task `T-304`.

## Required Runtime Configuration
- `DOCKER_ENGINE_SOCKET_PATH`
  Path to the Docker Engine Unix socket visible from the Rails app. Default: `/var/run/docker.sock`.
- `DOCKER_ENGINE_API_VERSION`
  Optional Docker Engine API version prefix used by the wrapper. Default: unset, which keeps requests unversioned. Set it only when a deployment needs an explicit `/v1.xx` override.
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
- `MINECRAFT_RUNTIME_NETWORK_NAME`
  Shared bridge network name joined by `mc-router` and app-managed Minecraft containers. Default: `mc_router_net`.
- `MC_ROUTER_ROUTES_CONFIG_PATH`
  App-visible path where Rails writes the full desired `mc-router` routes JSON. Default: `tmp/mc-router/routes.json` under the app root.
- `MC_ROUTER_RELOAD_STRATEGY`
  Router reload mode after config write. Allowed values: `watch`, `command`, `manual`. Default: `watch`.

## Conditionally Required Configuration
- `MC_ROUTER_RELOAD_COMMAND`
  Required when `MC_ROUTER_RELOAD_STRATEGY=command`.
- `MC_ROUTER_API_URL`
  Optional operational endpoint for future router inspection or tooling.

## Compose Baseline
- Local development should keep `LOCAL_UID`, `LOCAL_GID`, and `DOCKER_SOCKET_GID` in the repository `.env` file so `docker compose up` uses the same user/group mapping consistently.
- The Rails `app` service mounts `/var/run/docker.sock`.
- The Rails `app` service should join the host Docker socket group via `group_add`, typically by passing `DOCKER_SOCKET_GID=$(stat -c '%g' /var/run/docker.sock)` to Compose.
- The Rails `app` service should export the direct-Docker defaults above unless deployment overrides them.
- The Rails `app` service should leave `DOCKER_ENGINE_API_VERSION` unset unless the target daemon requires an explicit override.
- The same `MINECRAFT_RUNTIME_NETWORK_NAME` value must be used by both Rails and the eventual `mc-router` service definition.

## App Usage Contract
- `MinecraftPublicEndpoint` is the single source of truth for public FQDN and connection-target formatting.
- `MinecraftRuntime` is the single source of truth for the baseline runtime image and shared bridge network name.
- `DockerEngine` reads only Docker transport settings.
- `Router` reads only route file and reload settings.

## Non-Goals
- Per-server host port publishing is not supported.
- DNS automation and SRV record management remain out of scope.
- Image build configuration is not part of the initial env contract.
