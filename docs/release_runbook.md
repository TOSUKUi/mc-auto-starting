# Release, Migration, And Rollback Runbook

## Purpose

This document closes `T-902`.

It defines the operator-facing release, migration, and rollback procedure for the current single-host deployment baseline:

- Kamal deploys the Rails app
- MariaDB is provided externally
- Redis runs as a Kamal accessory
- `mc-router` remains a long-lived sibling service
- Rails continues to control Minecraft containers through `/var/run/docker.sock`

Use this together with:

- [docs/operator_runbook.md](operator_runbook.md)
- [docs/kamal_deployment_topology.md](kamal_deployment_topology.md)
- [config/deploy.yml](../config/deploy.yml)
- [config/deploy.production.yml](../config/deploy.production.yml)

## Preconditions

Before a release, confirm:

- `.kamal/secrets-common` and `.kamal/secrets.production` are present and current
- `bin/deploy-mc-router` has already been run on the target host
- the shared runtime network exists
- the external MariaDB instance is reachable from the target host using `DB_HOST`, `DB_PORT`, `DB_USERNAME`, and `DB_NAME_PRODUCTION`
- the current production app answers `GET /up`
- the target host still exposes `/var/run/docker.sock` to the Rails app container

## Standard Release

### 1. Review the deploy diff

Run locally from the deploy checkout:

```bash
git log --oneline --decorate -n 10
git status --short
```

The tree should be clean before deploying.

### 2. Verify Kamal env locally

Confirm the required non-secret deploy env is exported:

```bash
env | grep -E '^(KAMAL_IMAGE|KAMAL_REGISTRY_USERNAME|KAMAL_REGISTRY_SERVER|DEPLOY_WEB_HOST|APP_BASE_URL|DB_USERNAME|DB_NAME_PRODUCTION|MINECRAFT_PUBLIC_DOMAIN|MINECRAFT_PUBLIC_PORT)='
```

### 3. Deploy the app

```bash
kamal deploy -d production
```

This is the normal release path for code-only and code-plus-migration releases.

### 4. Verify the release

Check:

```bash
kamal app details -d production
curl -f "${APP_BASE_URL}/up"
```

Then verify in the UI:

- `/login` is reachable
- `/servers` loads
- an existing server detail page loads

### 5. Verify the router sibling service

On the target host:

```bash
docker ps --filter label=app.kubos.dev/component=mc-router
docker logs --tail=100 $(docker ps -q --filter label=app.kubos.dev/component=mc-router)
```

`mc-router` is not redeployed by `kamal deploy`, so this check confirms the sibling service remained healthy across the app release.

## Release With Database Migration

The current baseline uses the same `kamal deploy -d production` entrypoint, then an explicit migration check.

### 1. Deploy first

```bash
kamal deploy -d production
```

### 2. Run the migration step if needed

```bash
kamal app exec -d production -- bin/rails db:migrate
```

If the deploy already ran migrations through hooks for that release, this command should be a no-op.

### 3. Validate schema-dependent pages

Check at least:

- `/login`
- `/servers`
- one create-related flow
- one lifecycle action against a non-critical test server if available

## Accessory Maintenance

If the Redis image/config changed, restart it explicitly after the app deploy:

```bash
kamal accessory reboot redis -d production
```

Then re-run:

```bash
curl -f "${APP_BASE_URL}/up"
kamal app details -d production
```

## Rollback

Use rollback when the new app version is unhealthy but the underlying host and Redis accessory remain usable.

### 1. Confirm the failure mode

Examples:

- `/up` fails after deploy
- `/login` or `/servers` returns a server error
- a critical controller path fails after a code release

### 2. Roll back the app

```bash
kamal rollback -d production
```

### 3. Verify the previous release

```bash
kamal app details -d production
curl -f "${APP_BASE_URL}/up"
```

Then confirm `/login` and `/servers` again in the browser.

### 4. Roll back the database only if required

Do not automatically roll back the database on every app rollback.

Use a DB rollback only when:

- the failed release introduced a reversible migration
- the rollback target code cannot run against the new schema
- you have confirmed the migration is safe to reverse

Command:

```bash
kamal app exec -d production -- bin/rails db:rollback
```

If the migration is destructive or not safely reversible, prefer a forward fix instead of forcing schema rollback.

## Failure Handling Notes

### App deploy failed but Redis accessory is healthy

- run `kamal rollback -d production`
- verify `/up`
- leave `mc-router` running as-is

### App is healthy but `mc-router` is unhealthy

On the target host:

```bash
bin/deploy-mc-router
docker ps --filter label=app.kubos.dev/component=mc-router
```

Do not use Rails or Kamal app commands to recreate `mc-router`.

### Migration failed midway

- stop at the migration failure
- inspect the exact migration error
- verify whether the current app release can still boot
- prefer a forward fix migration when data safety is unclear
- use `kamal rollback -d production` only if the previous app release is known-good against the current schema state

## Post-Release Checklist

- `curl -f "${APP_BASE_URL}/up"` succeeds
- `/login` works
- `/servers` works
- at least one existing server detail page works
- `mc-router` container is still running
- no unexpected app boot loop appears in Kamal app details
