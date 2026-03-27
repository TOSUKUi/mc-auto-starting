# Single-Host Setup And Local Development

## Purpose

This document is the `T-900` setup baseline for bringing up the app on a single Docker host with `/var/run/docker.sock` mounted into Rails.

## Topology Summary

- `app`: Rails, Vite, and the direct Docker control plane
- `db`: MariaDB for app data
- `redis`: cache and queue support baseline
- `mc-router`: single public Minecraft ingress on one shared port
- app-managed Minecraft containers: created directly by Rails on the same host

`mc-router` is Compose-managed. Minecraft containers are not.

## Host Prerequisites

- Docker Engine with Compose support
- A host user that can access Docker
- Linux-style access to `/var/run/docker.sock`
- A writable working copy of this repository

Do not install project gems on the host. Run Ruby and Rails commands through Docker.

## Environment File

Copy the checked-in template and keep the live file local-only.

```bash
cp .env.example .env
```

`.env.example` is the authoritative template. `.env` is the live local file and must stay untracked.

## Required Local Adjustments

### 1. Match the host UID, GID, and Docker group

If your host user is not `1000:1000` or the Docker group GID differs, update these values in `.env`:

```bash
id -u
id -g
grep '^docker:' /etc/group | cut -d: -f3
```

- `LOCAL_UID`
- `LOCAL_GID`
- `DOCKER_GID`

This keeps bind-mounted files writable from inside the container and lets the `app` service talk to Docker through the mounted socket.

### 2. Check the local database values

The default MariaDB settings in `.env.example` are intended for local development. Change them if the names or passwords collide with your environment.

### 3. Set the public endpoint values intentionally

- `MINECRAFT_PUBLIC_DOMAIN` controls the FQDN shown in the UI and written into router routes.
- `MINECRAFT_PUBLIC_PORT` is the single shared public Minecraft port exposed by `mc-router`.

For a local-only boot, the app can run with a placeholder domain. For real ingress testing, use a domain or hostname pattern you can resolve to the Docker host.

## Shared Docker Network

The Compose file expects the Minecraft runtime network to already exist because `mc-router` must join the same named bridge network as Rails-created Minecraft containers.

Create it once before the first `docker compose up`:

```bash
docker network create "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

If you keep the default `.env.example` values, this becomes:

```bash
docker network create mc_router_net
```

## Build And Boot

Build the app image first:

```bash
docker compose build app
```

Then start the full local stack:

```bash
docker compose up --build
```

This starts:

- Rails app container
- MariaDB
- Redis
- `mc-router`

The `app` service mounts:

- the repository at `/app`
- `/var/run/docker.sock` from the host

It also joins the shared runtime network in addition to the default Compose network.

## Database Preparation

In another shell, prepare the databases:

```bash
docker compose run --rm app bin/rails db:prepare
```

If you need seed data for the first operator, run:

```bash
docker compose run --rm app bin/rails db:seed
```

The bootstrap seed uses:

- `BOOTSTRAP_DISCORD_USER_ID`
- `BOOTSTRAP_DISCORD_USERNAME`

## Accessing The App

Open the Rails UI at:

```text
http://localhost:3000
```

`bin/dev` also exposes Vite on port `3036`.

If Discord OAuth is configured with `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, and optionally `APP_BASE_URL`, the server boot log can print a bootstrap owner sign-in hint for `/login`.

## Normal Local Development Commands

Run one-off Rails commands through Docker:

```bash
docker compose run --rm app bin/rails console
docker compose run --rm app bin/rails test
docker compose run --rm app bin/rails db:migrate
```

If you want a foreground development process outside `docker compose up`, use:

```bash
docker compose run --rm -p 3000:3000 -p 3036:3036 app bin/dev
```

`bin/dev` prefers `overmind`, then `hivemind`, then `foreman`, and finally falls back to running Rails and Vite directly in the same container.

## What A Successful Local Boot Looks Like

- `docker compose up --build` starts without a missing-network error
- `db` becomes healthy
- `redis` becomes healthy
- the Rails app responds on `http://localhost:3000`
- `mc-router` is running and binds `${MINECRAFT_PUBLIC_PORT}:25565`
- `docker compose run --rm app bin/rails db:prepare` succeeds

## Common Local Failure Cases

### Docker socket permission errors

Symptoms:

- Rails cannot inspect or create containers
- Docker Engine calls fail from inside the `app` container

Check:

- the host user is in the Docker-capable group
- `DOCKER_GID` in `.env` matches the host Docker group
- `/var/run/docker.sock` is mounted into the `app` service

### Missing external network

Symptoms:

- `docker compose up` fails before services start

Fix:

```bash
docker network create "${MINECRAFT_RUNTIME_NETWORK_NAME:-mc_router_net}"
```

### App files created with the wrong owner

Symptoms:

- files under the repo become owned by an unexpected UID or GID

Check:

- `LOCAL_UID`
- `LOCAL_GID`

These should match your host user.

### Bootstrap owner cannot sign in

Check:

- `BOOTSTRAP_DISCORD_USER_ID` is set before running `db:seed`
- Discord OAuth credentials are configured
- `APP_BASE_URL` matches the URL you are actually using when not relying on the local development default

## Scope Boundaries

- This setup is single-host only.
- Rails controls Docker directly through the mounted Unix socket.
- `mc-router` remains part of the active architecture.
- DNS automation and SRV record management are out of scope.

For env key semantics, use [docs/direct_docker_env_contract.md](direct_docker_env_contract.md).
