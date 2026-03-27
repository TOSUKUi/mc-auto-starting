# mc-auto-starting

Single-host Minecraft server manager built with Rails 8, Docker Engine, and `mc-router`.

Rails is the control plane. It talks to Docker through `/var/run/docker.sock`, creates and manages Minecraft containers directly, and rewrites `mc-router` routes so all public Minecraft traffic can stay on one shared port.

## Current Stack

- Ruby `3.4.9`
- Rails `8.1.2`
- MariaDB `10.11.16`
- Redis `7`
- Inertia.js + React + Mantine
- Docker Engine API over Unix socket
- `itzg/minecraft-server`
- `itzg/mc-router`

## Read First

- [AGENTS.md](AGENTS.md)
- [docs/context_map.md](docs/context_map.md)
- [docs/single_host_setup.md](docs/single_host_setup.md)

## Quick Start

1. Copy the local env template.

```bash
cp .env.example .env
```

2. If your host UID, GID, or Docker group GID differ from the defaults, update `.env`.

```bash
id -u
id -g
grep '^docker:' /etc/group | cut -d: -f3
```

3. Create the shared Docker bridge network once.

```bash
docker network create mc_router_net
```

4. Build and boot the local stack.

```bash
docker compose build app
docker compose up --build
```

5. Prepare the databases in a separate shell.

```bash
docker compose run --rm app bin/rails db:prepare
```

6. Open `http://localhost:3000`.

## Useful Commands

```bash
docker compose run --rm app bin/rails test
docker compose run --rm app bin/rails db:seed
docker compose run --rm -p 3000:3000 -p 3036:3036 app bin/dev
```

`bin/dev` falls back to direct Rails + Vite startup when `foreman` is not installed in the container.

## Local Bootstrap Notes

- Keep `.env` local and untracked. `.env.example` is the checked-in template.
- The `app` container must be able to access `/var/run/docker.sock`.
- `mc-router` runs as a Compose-managed sibling container on the shared external bridge network.
- To bootstrap the first owner, set `BOOTSTRAP_DISCORD_USER_ID` in `.env`, run `docker compose run --rm app bin/rails db:seed`, then complete sign-in from `/login` after Discord OAuth is configured.

## Detailed Setup

Use [docs/single_host_setup.md](docs/single_host_setup.md) for the full single-host setup and local development workflow.
