# Kamal Deployment Topology And Env Mapping

## Purpose

This document fixes the `T-904` baseline and its external-DB follow-up for running the app on a single host with Kamal while preserving the current direct-Docker and `mc-router` architecture.

`T-905` implements this document through:

- [config/deploy.yml](../config/deploy.yml)
- [config/deploy.production.yml](../config/deploy.production.yml)
- [docker/mc-router/deploy.compose.yml](../docker/mc-router/deploy.compose.yml)
- [bin/deploy-mc-router](../bin/deploy-mc-router)

## Scope

This baseline covers:

- target host roles
- accessory strategy
- secret injection path
- mapping from local `.env` keys to deploy-time env

It does not yet define the exact `kamal` CLI commands or the final checked-in config shape. That is `T-905`.

## Deployment Topology

### Single Host

The initial deployment target is one Linux host running:

- Docker Engine
- Kamal-managed Rails app containers
- access to an external MariaDB instance
- Redis
- `mc-router`
- Rails-managed Minecraft server containers

No multi-host scheduling, cross-host Docker API, or remote container placement is introduced in this phase.

### Kamal-Managed App Role

The app deployment starts with one Kamal role:

- `web`
  - runs the Rails application
  - serves HTTP traffic for the web UI and app endpoints
  - mounts `/var/run/docker.sock` from the host
  - mounts a persistent shared directory for generated `mc-router` route files

There is no separate worker role in the initial baseline because production queue execution is not yet split into a dedicated service.

### Accessory Strategy

The single-host deployment baseline is:

- MariaDB: external service outside Kamal accessories
- Redis: Kamal accessory
- `mc-router`: host-level sibling service outside the Rails app container, kept aligned with the current compose-managed architecture

`mc-router` stays outside Rails lifecycle ownership. Rails may rewrite its routes file and signal reloads, but Rails must not create or destroy the router container itself.

For `T-905`, that means the repository should ship:

- Kamal config for the Rails app
- a Kamal-managed Redis accessory
- a checked-in deployment helper or compose file for the long-lived `mc-router` sibling service

The goal is to keep the app deployment Kamal-based without changing the architectural decision that `mc-router` is not managed by Rails.

## Container And Network Shape

### Docker Socket

The deployed Rails `web` container must mount:

```text
/var/run/docker.sock:/var/run/docker.sock
```

This stays the control path for:

- Minecraft container create
- inspect
- start / stop / restart
- remove
- `mc-router` reload targeting by Docker labels

No socket proxy is added in the initial deployment baseline.

### Runtime Network

`mc_router_net` remains the shared bridge network for:

- the long-lived `mc-router` container
- Rails-created Minecraft runtime containers

The Rails `web` container does not need to be attached to that network for the current baseline because it talks to Docker over the Unix socket rather than by container-to-container networking.

### HTTP And Minecraft Ports

- Kamal's HTTP entrypoint handles the Rails web UI on standard web ports
- `mc-router` continues to own `${MINECRAFT_PUBLIC_PORT}:25565`

This keeps browser traffic and Minecraft traffic on separate public entrypoints while preserving the single shared Minecraft ingress port model.

## Shared Host Paths

Deployment must stop relying on the local development bind mount at `./tmp/mc-router`.

The single-host deployment baseline should use a persistent host directory such as:

```text
/var/lib/mc-auto-starting/shared/mc-router
```

Expected mounts:

- host path `/var/lib/mc-auto-starting/shared/mc-router`
- inside Rails `web` container: `/rails/shared/mc-router`
- inside `mc-router`: `/config`

This keeps the generated routes file visible to both the Rails app and the long-lived router container.

## Secret Injection Path

### Source Of Truth Split

- Local development keeps using `.env`
- Deploy-time non-secret topology stays in checked-in Kamal config
- Deploy-time secrets stay in untracked Kamal secret files

### Planned Kamal Secret Files

The baseline deploy secret layout is:

- `.kamal/secrets-common`
  - shared secret values used across deploy environments
- `.kamal/secrets.production`
  - production-only secret overrides

These files must stay untracked.

### Checked-In Deploy Config

The checked-in deployment config should carry:

- app image / service name
- target server IP or hostname
- Kamal proxy and app port settings
- non-secret env
- accessory definitions
- volume mounts

Secrets should not be committed into the Kamal config file.

## Local `.env` To Deploy Mapping

### Local-Only Keys

These keys remain local development only and should not be carried into production deploy env:

- `LOCAL_UID`
- `LOCAL_GID`
- `DOCKER_GID`
- `DB_NAME_DEVELOPMENT`
- `DB_NAME_TEST`

### One-Time Bootstrap Keys

These keys are not part of the steady-state app env. They are injected only for initial owner seeding or maintenance tasks:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

### Deploy-Time Mapping Table

| Local key | Deploy scope | Secret | Deploy value / note |
| --- | --- | --- | --- |
| `DB_HOST` | app | no | external MariaDB hostname or private IP |
| `DB_PORT` | app | no | MariaDB port, usually `3306` |
| `DB_USERNAME` | app | no | database username |
| `DB_PASSWORD` | app | yes | application database password |
| `APP_DATABASE_PASSWORD` | app | yes | same secret value as `DB_PASSWORD`; app uses this name in production when present |
| `DB_NAME_PRODUCTION` | app | no | production database name |
| `REDIS_URL` | app | no | points at the Redis accessory |
| `DOCKER_ENGINE_API_VERSION` | app | no | unset by default unless the host daemon needs an override |
| `MINECRAFT_PUBLIC_DOMAIN` | app | no | public DNS suffix shown in the UI and written to router routes |
| `MINECRAFT_PUBLIC_PORT` | app + `mc-router` sibling service | no | shared public Minecraft port |
| `DISCORD_CLIENT_ID` | app | yes | production OAuth client id |
| `DISCORD_CLIENT_SECRET` | app | yes | production OAuth client secret |
| `APP_BASE_URL` | app | no | public HTTPS base URL used for login hints and callback-related app behavior |
| `DISCORD_BOT_API_TOKEN` | app | yes | secret bearer token for the internal bot API when the external relay is in use |
| `MINECRAFT_RCON_PASSWORD_SECRET` | app | yes | optional explicit secret used to derive stable per-server RCON passwords |
| `RAILS_LOG_LEVEL` | app | no | carried through unchanged |

## Production Defaults To Preserve

`T-905` should preserve these current code assumptions:

- `DOCKER_ENGINE_API_VERSION` stays unset by default
- Docker socket path remains `/var/run/docker.sock`
- Docker Engine timeouts stay fixed at open `5s`, read `30s`, write `30s`
- `mc-router` route output path stays `/rails/shared/mc-router/routes.json` in production
- `mc-router` reload stays fixed to Docker signal `HUP`, resolved by the stable label `app.kubos.dev/component=mc-router`
- `paper` and `vanilla` continue to provision through `itzg/minecraft-server`

## Deployment Boundaries

- Kamal deploys the Rails app image and the Redis accessory
- Rails continues to manage only app-labeled Minecraft runtime containers and volumes
- `mc-router` remains a long-lived sibling service and must not be folded into Rails runtime lifecycle
- No production env rename should be required just because the app moved from local Compose to Kamal deploy

## Follow-On Work For `T-905`

- add Kamal to the project toolchain
- check in the initial Kamal config
- wire the external MariaDB env plus the Redis accessory
- define the persistent shared mount for router routes
- add the app container mount for `/var/run/docker.sock`
- add the deployment helper or config for the long-lived `mc-router` sibling service
