# Release, Migration, And Rollback Runbook

## Purpose

This document closes `T-902` and `T-914`.

It defines the operator-facing release, migration, and rollback procedure for the current single-host production baseline:

- Komodo or an operator runs `docker compose pull` and `docker compose up -d`
- the Rails app image is published by GitHub Actions
- MariaDB is external
- Redis runs in the production Compose stack
- `mc-router` remains a long-lived sibling service in the production Compose stack
- Rails continues to control Minecraft containers through `/var/run/docker.sock`
- the Rails app, `mc-router`, and managed runtime containers continue to share `mc_router_net`

Use this together with:

- [docs/operator_runbook.md](operator_runbook.md)
- [docs/compose_komodo_deployment_topology.md](compose_komodo_deployment_topology.md)
- [docker-compose.production.yml](../docker-compose.production.yml)

## Preconditions

Before a release, confirm:

- the target host has an up-to-date `.env.production`
- `APP_IMAGE` points at the intended image tag
- `SECRET_KEY_BASE` is present in `.env.production` or the corresponding Komodo secret store
- the shared runtime network exists
- the external MariaDB instance is reachable from the target host using `DB_HOST`, `DB_PORT`, `DB_USERNAME`, and `DB_NAME_PRODUCTION`
- the current production app answers `GET /up`
- the target host still exposes `/var/run/docker.sock` to the Rails app container

## Standard Release

### 1. Review the deploy diff

Run locally from the release checkout:

```bash
git log --oneline --decorate -n 10
git status --short
```

The tree should be clean before tagging or merging the release commit.

### 2. Confirm the image to deploy

Check the image tag that production will pull.

Examples:

- `ghcr.io/OWNER/REPO:latest`
- `ghcr.io/OWNER/REPO:sha-...`
- `ghcr.io/OWNER/REPO:v1.2.3`

Prefer an immutable tag for controlled releases.

### 3. Pull and start the release

On the target host or through Komodo:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

This is the normal release path for code-only releases.

### 4. Verify the release

Check:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml ps
curl -f "${APP_BASE_URL}/up"
```

Then verify in the UI:

- `/login` is reachable
- `/servers` loads
- an existing server detail page loads
- at least one RCON-backed surface such as player count or whitelist data loads for an existing running server if one is available

### 5. Verify the router sibling service

On the target host:

```bash
docker ps --filter label=app.kubos.dev/component=mc-router
docker logs --tail=100 $(docker ps -q --filter label=app.kubos.dev/component=mc-router)
```

This confirms the sibling router service remained healthy across the app release.

## Release With Database Migration

Use this path when a release needs schema changes.

### 1. Pull and start the new app image

```bash
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

### 2. Run the migration step

```bash
docker compose --env-file .env.production -f docker-compose.production.yml run --rm app bin/rails db:prepare
```

Use `db:prepare` as the default because it is safe across first boot and normal migration runs.

### 3. Validate schema-dependent pages

Check at least:

- `/login`
- `/servers`
- one create-related flow
- one lifecycle action against a non-critical test server if available

## Service Maintenance

If Redis was changed and needs a clean restart:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml up -d redis
```

Then re-run:

```bash
curl -f "${APP_BASE_URL}/up"
docker compose --env-file .env.production -f docker-compose.production.yml ps
```

## Rollback

Use rollback when the new app version is unhealthy but the underlying host, Redis, and `mc-router` remain usable.

### 1. Confirm the failure mode

Examples:

- `/up` fails after deploy
- `/login` or `/servers` returns a server error
- a critical controller path fails after a code release

### 2. Point `APP_IMAGE` back to the previous known-good tag

Edit `.env.production` or the corresponding Komodo env/secret setting so `APP_IMAGE` references the previous release.

### 3. Pull and restart using the previous image

```bash
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

### 4. Verify the previous release

```bash
docker compose --env-file .env.production -f docker-compose.production.yml ps
curl -f "${APP_BASE_URL}/up"
```

Then confirm `/login` and `/servers` again in the browser.

### 5. Roll back the database only if required

Do not automatically roll back the database on every app rollback.

Use a DB rollback only when:

- the failed release introduced a reversible migration
- the rollback target code cannot run against the new schema
- you have confirmed the migration is safe to reverse

Command:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml run --rm app bin/rails db:rollback
```

If the migration is destructive or not safely reversible, prefer a forward fix instead of forcing schema rollback.

## Failure Handling Notes

### App deploy failed but Redis and `mc-router` are healthy

- point `APP_IMAGE` back to the previous known-good tag
- run the rollback steps above
- verify `/up`
- leave `mc-router` running as-is

### App is healthy but `mc-router` is unhealthy

On the target host:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml up -d mc-router
docker ps --filter label=app.kubos.dev/component=mc-router
```

Do not use Rails operations to recreate `mc-router`.

### Migration failed midway

- stop at the migration failure
- inspect the exact migration error
- verify whether the current app release can still boot
- prefer a forward-fix migration when data safety is unclear
- roll back the app image only if the previous release is known-good against the current schema state

## Post-Release Checklist

- `curl -f "${APP_BASE_URL}/up"` succeeds
- `/login` works
- `/servers` works
- at least one existing server detail page works
- `mc-router` container is still running
- `docker compose ... ps` shows a healthy `app` container
