# Operator Runbook

## Purpose

This document is the `T-901` and `T-914` operator-facing runbook for the current direct-Docker architecture.

It is written for the current repository state on `2026-04-02`:

- direct Docker lifecycle is implemented
- local single-host bootstrap is documented
- production deployment has pivoted to `docker-compose.production.yml` plus Komodo
- the app image is expected to be built by GitHub Actions and pulled on the target host
- production boot no longer depends on Rails credentials or `master.key`

## Which Deployment Path To Use Today

### Local Development

If you want to run the app yourself right now on a development machine, use the single-host Docker Compose path described in [docs/single_host_setup.md](single_host_setup.md).

### Production Deployment

For the production-like single-host deployment path, use:

- [docker-compose.production.yml](../docker-compose.production.yml)
- [docs/compose_komodo_deployment_topology.md](compose_komodo_deployment_topology.md)
- [docs/release_runbook.md](release_runbook.md)

The production baseline now assumes:

- Komodo drives `docker compose pull` and `docker compose up -d`
- the Rails app uses a prebuilt registry image
- MariaDB is external
- Redis remains containerized on the same host
- `mc-router` remains a long-lived sibling service in the same production Compose stack
- the Rails app, `mc-router`, and managed Minecraft containers share `mc_router_net`
- app secrets are injected directly by env or secret management, not by Rails credentials

## Current Single-Host Production Procedure

Use this when deploying the app to one Docker host with the current repository state.

### 1. Prepare the host

- install Docker Engine with Compose support
- install and configure Komodo if you want UI-driven rollout
- ensure the operator can access `/var/run/docker.sock`
- create or confirm the shared runtime network

```bash
docker network create mc_router_net || true
```

### 2. Prepare the production env file

Create a host-local env file such as `.env.production`.

At minimum, set:

- `APP_IMAGE`
- `DB_HOST`
- `DB_PORT`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_NAME_PRODUCTION`
- `MINECRAFT_PUBLIC_DOMAIN`
- `MINECRAFT_PUBLIC_PORT`
- `APP_BASE_URL`
- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`
- `DISCORD_BOT_API_TOKEN` if the bot relay is in use
- `MINECRAFT_RCON_PASSWORD_SECRET`

Optional but commonly useful:

- `APP_HTTP_PORT`
- `RAILS_LOG_LEVEL`
- `REDIS_URL`
- `DOCKER_ENGINE_API_VERSION`

Do not set `RAILS_MASTER_KEY`. Production is expected to boot without it.

### 3. Pull and start the production stack

```bash
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

This should start:

- `app`
- `redis`
- `mc-router`

It should not create a local MariaDB container.

### 4. Prepare the database

For first boot or schema updates:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml run --rm app bin/rails db:prepare
```

### 5. Bootstrap the first owner if needed

Inject these only for the seed run:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

Then run:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml run --rm app bin/rails db:seed
```

### 6. Verify the app

```bash
curl -f "${APP_BASE_URL}/up"
```

Then confirm:

- `/login` is reachable
- `/servers` loads after sign-in
- the `mc-router` container is present with `app.kubos.dev/component=mc-router`
- the app container is attached to `mc_router_net`

## Day-2 Operations

## Discord Bot API Baseline

The Rails app now exposes an internal-only bot surface under `/api/discord/bot/*`.

Current safety baseline:

- reachable only from the Docker private network
- requires `Authorization: Bearer <DISCORD_BOT_API_TOKEN>`
- requires `X-Discord-User-Id` on every request
- reuses the same Rails policy checks as the web UI

Current command categories:

- read/status
- lifecycle `start/stop/restart/sync`
- whitelist read/write
- owner/admin-only bounded RCON commands

Bounded RCON intentionally rejects lifecycle-style commands such as `stop`, `start`, `restart`, and `reload`, even for owner/admin callers.

The detailed request/response contract lives in [docs/discord_bot_api_contract.md](discord_bot_api_contract.md).

Operator-facing Discord login, invite, and bot relay setup now lives in [docs/discord_operator_runbook.md](discord_operator_runbook.md).

### Preferred control path

Use the web UI for normal server lifecycle operations:

- create: `/servers/new`
- inspect: `/servers/:id`
- start: POST `/servers/:id/start`
- stop: POST `/servers/:id/stop`
- restart: POST `/servers/:id/restart`
- sync: POST `/servers/:id/sync`
- delete: DELETE `/servers/:id`

The supported direct-Docker lifecycle contract is documented in [docs/direct_docker_lifecycle_contract.md](direct_docker_lifecycle_contract.md).

### What each lifecycle action does

- `start`
  - calls Docker start on the managed container
  - updates Rails status toward `starting`
- `stop`
  - calls Docker stop on the managed container
  - updates Rails status toward `stopping`
- `restart`
  - calls Docker restart on the managed container
  - updates Rails status toward `restarting`
- `sync`
  - inspects Docker state and reconciles Rails status and `container_state`
- `delete`
  - unpublishes the `mc-router` route
  - force-removes the managed container
  - removes the managed volume
  - destroys the DB record only after cleanup succeeds or tolerated `NotFound` cases are handled

## Safe Host-Side Verification Commands

These host-side commands are safe for inspection and troubleshooting.

### Check the production stack

```bash
docker compose --env-file .env.production -f docker-compose.production.yml ps
docker compose --env-file .env.production -f docker-compose.production.yml logs app --tail=200
docker compose --env-file .env.production -f docker-compose.production.yml logs mc-router --tail=200
```

### Check Rails health

```bash
curl -f "${APP_BASE_URL}/up"
```

### Check app-managed Minecraft containers

```bash
docker ps -a --filter label=app=mc-auto-starting --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
```

### Check app-managed volumes

```bash
docker volume ls --filter label=app=mc-auto-starting
```

### Check the shared runtime network

```bash
docker network inspect mc_router_net
```

### Check the rendered router config

Use a temporary shell in the app container:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml exec app cat /rails/shared/mc-router/routes.json
```

## Docker Safety Rules

`/var/run/docker.sock` gives the Rails app high-privilege control over the Docker host. Treat it as equivalent to host-level control.

### Allowed operational boundary

Rails is allowed to manage only resources labeled as app-managed:

- `app=mc-auto-starting`
- `managed_by=rails`
- `minecraft_server_id=<db id>`
- `minecraft_server_hostname=<hostname>`

These labels are the ownership boundary for managed Minecraft containers and volumes.

### Do not do these manually

- do not rename managed containers
- do not rename managed volumes
- do not edit or remove app management labels
- do not attach unrelated containers to the shared runtime network unless you intentionally want `mc-router` reachability there
- do not use `docker system prune`
- do not use `docker volume prune`
- do not remove the shared runtime network while the app is in service
- do not stop or recreate `mc-router` without preserving its label and route-sharing contract

### Be careful with direct Docker intervention

If you manually stop, remove, or replace a managed container on the host, the Rails record can drift from Docker state until a sync or cleanup path runs.

When in doubt:

1. inspect through the UI
2. run `sync`
3. use read-only Docker inspection commands first

## Common Operator Checks

### A server looks stale in the UI

Use the server detail page and run `sync`.

If needed, verify on the host:

```bash
docker ps -a --filter label=app=mc-auto-starting
```

### A route looks wrong

Check the rendered routes file:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml exec app cat /rails/shared/mc-router/routes.json
```

Then confirm the `mc-router` container is up and still labeled correctly:

```bash
docker ps --filter label=app.kubos.dev/component=mc-router
```

### The app cannot manage Docker resources

Usually this means one of:

- `/var/run/docker.sock` is not mounted into the app container
- the app container cannot access the socket
- the host Docker daemon is unavailable

### The production stack will not start

The first thing to check is whether the shared runtime network exists:

```bash
docker network inspect mc_router_net
```

If it does not exist:

```bash
docker network create mc_router_net
```

## References

- [docs/single_host_setup.md](single_host_setup.md)
- [docs/compose_komodo_deployment_topology.md](compose_komodo_deployment_topology.md)
- [docker-compose.production.yml](../docker-compose.production.yml)
- [docs/direct_docker_env_contract.md](direct_docker_env_contract.md)
- [docs/direct_docker_lifecycle_contract.md](direct_docker_lifecycle_contract.md)
- [docs/docker_engine_contract.md](docker_engine_contract.md)
- [docs/router_api_contract.md](router_api_contract.md)
