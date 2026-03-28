# Operator Runbook

## Purpose

This document is the `T-901` operator-facing runbook for the current direct-Docker architecture.

It is written for the current repository state on `2026-03-28`:

- direct Docker lifecycle is implemented
- local single-host bootstrap is documented
- Kamal topology is defined
- the initial Kamal deployment baseline is checked into the repository
- the dedicated release and rollback runbook is now checked in

## Which Deployment Path To Use Today

### Usable Today

If you want to run the app yourself right now, use the single-host Docker Compose path described in [docs/single_host_setup.md](single_host_setup.md).

That is the current usable deployment and operations path in this repository.

### Not Yet Checked In

Kamal is the planned deployment baseline, and the initial config files are now checked in under:

- [config/deploy.yml](../config/deploy.yml)
- [config/deploy.production.yml](../config/deploy.production.yml)
- [docker/mc-router/deploy.compose.yml](../docker/mc-router/deploy.compose.yml)
- [bin/deploy-mc-router](../bin/deploy-mc-router)

The dedicated release and rollback procedure now lives in [docs/release_runbook.md](release_runbook.md).

## Kamal Deployment Baseline

Use this path when you are ready to move from the current Compose-operated host to the Kamal-based single-host deployment.

### 1. Prepare local deploy secrets

Copy the example files:

```bash
cp .kamal/secrets-common.example .kamal/secrets-common
cp .kamal/secrets.production.example .kamal/secrets.production
```

Then fill in at least:

- `KAMAL_REGISTRY_PASSWORD`
- `RAILS_MASTER_KEY`
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`
- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`

### 2. Export the required non-secret deploy variables

```bash
export KAMAL_IMAGE=registry.example.com/mc-auto-starting
export KAMAL_REGISTRY_USERNAME=your-registry-user
export KAMAL_REGISTRY_SERVER=registry.example.com
export DEPLOY_WEB_HOST=app.example.com
export APP_BASE_URL=https://app.example.com
export DB_USERNAME=app_user
export DB_NAME_PRODUCTION=app_production
export MINECRAFT_PUBLIC_DOMAIN=mc.example.com
export MINECRAFT_PUBLIC_PORT=25565
```

Optional overrides can also be exported if you need non-default Docker or runtime settings.

### 3. Prepare the target host for `mc-router`

SSH to the target host and run:

```bash
bin/deploy-mc-router
```

This helper:

- creates the shared runtime network if it is missing
- creates the shared router config directory
- starts the long-lived `mc-router` sibling service

### 4. Run the first Kamal setup

From the repository checkout used for deployment:

```bash
kamal setup -d production
```

This should bootstrap accessories, push env, and deploy the app using the checked-in baseline.

### 5. Verify the deployed app

- open `${APP_BASE_URL}`
- check `${APP_BASE_URL}/up`
- confirm `/login` works
- confirm the `mc-router` container is still present with `app.kubos.dev/component=mc-router`

### 6. Later app updates

```bash
kamal deploy -d production
```

If an accessory image changes, reboot that accessory explicitly:

```bash
kamal accessory reboot mariadb -d production
kamal accessory reboot redis -d production
```

## Current Single-Host Deployment Procedure

Use this when deploying the app to one Docker host with the current repository state.

### 1. Prepare the host

- install Docker Engine with Compose support
- ensure the operator can access `/var/run/docker.sock`
- clone the repository on the target host

### 2. Create the env file

```bash
cp .env.example .env
```

Review at minimum:

- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`
- `DB_NAME_PRODUCTION`
- `MINECRAFT_PUBLIC_DOMAIN`
- `MINECRAFT_PUBLIC_PORT`
- `APP_BASE_URL`
- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`
- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

If the host UID, GID, or Docker group differ from the local defaults, also update:

- `LOCAL_UID`
- `LOCAL_GID`
- `DOCKER_GID`

If you plan to run the Discord Bot relay on the same Docker private network, also set:

- `DISCORD_BOT_API_TOKEN`
- `DISCORD_BOT_ALLOWED_CIDRS`

For the current baseline, `DISCORD_BOT_ALLOWED_CIDRS` should stay on the Docker private-network default unless the bot deployment shape is explicitly revised.

### 3. Create the shared runtime network

```bash
docker network create "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

This only needs to be done once per host.

### 4. Build and start the stack

```bash
docker compose build app
docker compose up -d --build
```

### 5. Prepare the database

```bash
docker compose run --rm app bin/rails db:prepare
```

### 6. Bootstrap the first owner if needed

```bash
docker compose run --rm app bin/rails db:seed
```

This seed path uses:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

### 7. Verify the app

```bash
curl -f http://localhost:3000/up
```

Then open:

```text
http://localhost:3000/login
```

If Discord OAuth is configured correctly, the initial owner can sign in there and start issuing invite URLs from `/discord-invitations`.

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

### Check the app stack

```bash
docker compose ps
docker compose logs app --tail=200
docker compose logs mc-router --tail=200
```

### Check Rails health

```bash
curl -f http://localhost:3000/up
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
docker network inspect "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

### Check the rendered router config

For the current Compose deployment path:

```bash
cat tmp/mc-router/routes.json
```

For the planned Kamal deployment shape, the routes file moves to the shared host path described in [docs/kamal_deployment_topology.md](kamal_deployment_topology.md).

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
- do not stop or recreate `mc-router` without preserving its label and route-file mount contract

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
cat tmp/mc-router/routes.json
```

Then confirm the `mc-router` container is up and still labeled correctly:

```bash
docker ps --filter label=app.kubos.dev/component=mc-router
```

### The app cannot manage Docker resources

Usually this means one of:

- `/var/run/docker.sock` is not mounted into the app container
- the effective container user cannot access the socket
- `DOCKER_GID` is wrong for the host

### The compose stack will not start

The first thing to check is whether the shared runtime network exists:

```bash
docker network inspect "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

If it does not exist:

```bash
docker network create "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

## References

- [docs/single_host_setup.md](single_host_setup.md)
- [docs/kamal_deployment_topology.md](kamal_deployment_topology.md)
- [config/deploy.yml](../config/deploy.yml)
- [config/deploy.production.yml](../config/deploy.production.yml)
- [docs/direct_docker_env_contract.md](direct_docker_env_contract.md)
- [docs/direct_docker_lifecycle_contract.md](direct_docker_lifecycle_contract.md)
- [docs/docker_engine_contract.md](docker_engine_contract.md)
- [docs/router_api_contract.md](router_api_contract.md)
