# Operator Runbook

## Purpose

This document is the `T-901` operator-facing runbook for the current direct-Docker architecture.

It is written for the current repository state on `2026-03-27`:

- direct Docker lifecycle is implemented
- local single-host bootstrap is documented
- Kamal topology is defined
- Kamal deployment automation is not yet checked into the repository

## Which Deployment Path To Use Today

### Usable Today

If you want to run the app yourself right now, use the single-host Docker Compose path described in [docs/single_host_setup.md](single_host_setup.md).

That is the current usable deployment and operations path in this repository.

### Not Yet Checked In

Kamal is the planned deployment baseline, but the executable Kamal config and helper files are still `T-905` work.

Use [docs/kamal_deployment_topology.md](kamal_deployment_topology.md) as the source of truth for the intended production shape, but do not expect the repository to be deployable with `kamal` commands yet.

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
- `BOOTSTRAP_EMAIL_ADDRESS`

If the host UID, GID, or Docker group differ from the local defaults, also update:

- `LOCAL_UID`
- `LOCAL_GID`
- `DOCKER_GID`

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
- `BOOTSTRAP_EMAIL_ADDRESS`

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
- [docs/direct_docker_env_contract.md](direct_docker_env_contract.md)
- [docs/direct_docker_lifecycle_contract.md](direct_docker_lifecycle_contract.md)
- [docs/docker_engine_contract.md](docker_engine_contract.md)
- [docs/router_api_contract.md](router_api_contract.md)
