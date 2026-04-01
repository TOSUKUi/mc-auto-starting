# Production Compose And Komodo Deployment Topology

## Purpose

This document closes `T-911`.

It fixes the production deployment topology and secret contract after the repository pivot away from Kamal and toward:

- a checked-in `docker-compose.production.yml`
- a prebuilt app image published by GitHub Actions
- Komodo-driven pull and rollout on the target host

The goal is to preserve the current direct-Docker and `mc-router` architecture without reintroducing host-local image builds or Rails credentials.

## Scope

This baseline covers:

- target host services
- container and network shape
- image distribution flow
- env and secret injection contract
- the boundary between checked-in config and host-only secret data

It does not yet define the final checked-in `docker-compose.production.yml` or the GitHub Actions workflow details. Those are `T-912` and `T-913`.

## Deployment Topology

### Single Host

The initial production target remains one Linux host running:

- Docker Engine with Compose support
- Komodo
- the Rails app container
- Redis
- `mc-router`
- Rails-managed Minecraft runtime containers
- access to an external MariaDB instance

No multi-host scheduling, remote Docker API, or separate runtime host is introduced.

### Role Split

- Rails app
  - serves the web UI and app APIs
  - mounts `/var/run/docker.sock`
  - rewrites `mc-router` routes
  - connects to managed Minecraft containers over `mc_router_net`
- Redis
  - remains containerized on the same host
  - backs Rails cache and queue-related features
- `mc-router`
  - remains a long-lived sibling service
  - is not created or destroyed by Rails
  - continues to publish the shared public Minecraft port
- MariaDB
  - remains external to the host-level app stack
  - is not managed by the production Compose file

## Image Distribution

### Build And Push

The app image should be built outside the production host by GitHub Actions using `Dockerfile.production`.

The workflow should:

- build the production image from the repository checkout
- tag it with at least an immutable revision tag
- optionally also publish a moving tag such as `latest`
- push it to the selected external registry

The production host should not build the app image locally during normal rollout.

### Pull And Rollout

Komodo should update the host by running the equivalent of:

```bash
docker compose -f docker-compose.production.yml pull
docker compose -f docker-compose.production.yml up -d
```

If a release includes schema work, the release runbook may add explicit `db:prepare` or `db:migrate` steps, but image pull remains the entrypoint.

## Container And Network Shape

### Docker Socket

The Rails app container must mount:

```text
/var/run/docker.sock:/var/run/docker.sock
```

This remains the control path for:

- Minecraft container create
- inspect
- start / stop / restart
- remove
- `mc-router` reload targeting by Docker labels

No socket proxy is added in this baseline.

### Runtime Network

`mc_router_net` remains the shared bridge network for:

- the long-lived `mc-router` container
- the Rails app container
- Rails-created Minecraft runtime containers

This is required because Rails-owned RCON features talk to managed containers by `container_name`, not by published host ports.

### Public Ports

- the Rails app continues to expose its HTTP port separately from Minecraft ingress
- `mc-router` continues to own `${MINECRAFT_PUBLIC_PORT}:25565`

The single shared Minecraft ingress port model does not change.

## Shared Volumes

Production must not rely on the development bind mount at `./tmp/mc-router`.

The production baseline should prefer persistent Docker named volumes over bind-mounted host directories.

Expected shared volumes:

- `mc_router_config`
  - inside Rails app container: `/rails/shared/mc-router`
  - inside `mc-router`: `/config`
- `app_storage`
  - inside Rails app container: `/app/storage`

This keeps the generated routes file visible to both the Rails app and the long-lived router container while avoiding host-path coupling in the checked-in Compose file.

## Secret And Env Contract

### Source Of Truth Split

- checked-in files define topology, image names, volumes, and non-secret defaults
- Komodo or host-local env files provide deploy-time secrets
- `.env` remains local-development-only input
- production boot must not depend on Rails credentials, `config/master.key`, or `RAILS_MASTER_KEY`

### Local-Only Keys

These keys remain development-only and should not be carried into steady-state production env:

- `LOCAL_UID`
- `LOCAL_GID`
- `DOCKER_GID`
- `DB_NAME_DEVELOPMENT`
- `DB_NAME_TEST`

### One-Time Bootstrap Keys

These are not steady-state app env and should be injected only for setup or maintenance tasks:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

### Production Mapping Table

| Local key | Production scope | Secret | Note |
| --- | --- | --- | --- |
| `DB_HOST` | app | no | external MariaDB hostname or private IP |
| `DB_PORT` | app | no | MariaDB port, usually `3306` |
| `DB_USERNAME` | app | no | database username |
| `DB_PASSWORD` | app | yes | application database password |
| `DB_NAME_PRODUCTION` | app | no | production database name |
| `REDIS_URL` | app | no | points at the production Redis container |
| `DOCKER_ENGINE_API_VERSION` | app | no | normally unset |
| `MINECRAFT_PUBLIC_DOMAIN` | app | no | public DNS suffix shown in the UI and written to router routes |
| `MINECRAFT_PUBLIC_PORT` | app and `mc-router` | no | shared public Minecraft port |
| `DISCORD_CLIENT_ID` | app | yes | production OAuth client id |
| `DISCORD_CLIENT_SECRET` | app | yes | production OAuth client secret |
| `APP_BASE_URL` | app | no | public base URL used for callbacks and login hints |
| `DISCORD_BOT_API_TOKEN` | app | yes | internal bot API bearer token |
| `MINECRAFT_RCON_PASSWORD_SECRET` | app | yes | required production secret for stable per-server RCON password derivation |
| `RAILS_LOG_LEVEL` | app | no | carried through unchanged when needed |

### Fixed Production Defaults To Preserve

- Docker socket path remains `/var/run/docker.sock`
- Docker Engine timeouts stay fixed at open `5s`, read `30s`, write `30s`
- `mc-router` route output path stays `/rails/shared/mc-router/routes.json` in production
- `mc-router` reload stays fixed to Docker signal `HUP`, resolved by the stable label `app.kubos.dev/component=mc-router`
- `paper` and `vanilla` continue to provision through `itzg/minecraft-server`

## Production Compose Baseline

The planned `docker-compose.production.yml` should:

- use `image:` for the Rails app instead of `build:`
- pull the prebuilt app image from the external registry
- mount `/var/run/docker.sock`
- mount persistent Docker volumes for the shared `mc-router` routes and Rails storage paths
- attach the Rails app, `mc-router`, and Redis to the required networks
- keep MariaDB external rather than declaring a local DB service
- avoid bind-mounting the full repository source tree
- avoid shipping secrets inside the image

## Deployment Boundaries

- Rails may manage only app-labeled Minecraft runtime containers and volumes
- Rails must not create or destroy the `mc-router` sibling container
- Komodo may restart or replace the Rails app, Redis, and `mc-router` services defined in the production Compose file
- the production host remains responsible for external MariaDB availability and registry access

## Follow-On Work

- `T-912`: make the production image safely publishable from GitHub Actions
- `T-913`: add the checked-in `docker-compose.production.yml`
- `T-914`: rewrite operator and release runbooks around the Compose + Komodo flow
- `T-915`: remove or demote obsolete Kamal-specific files from the active restart path
