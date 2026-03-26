# Docker Engine Contract

## Purpose
This document fixes the initial Docker Engine integration contract for Phase 2 tasks `T-300` through `T-302`.

## Locked Decisions
- Rails talks to Docker Engine directly through `/var/run/docker.sock`.
- Initial implementation optimizes for speed and simplicity over hard isolation.
- Rails does not shell out to `docker` CLI for normal lifecycle operations.
- Rails uses a small Ruby wrapper around the Docker Engine HTTP API over the Unix socket.

## Network Topology
- `mc-router` and app-managed Minecraft containers join the same dedicated bridge network.
- `mc-router` is provided as compose-managed infrastructure, not as a Rails-managed runtime resource.
- Minecraft containers do not publish per-server host ports.
- `mc-router` is the only component that publishes the shared public Minecraft port.
- Router backends use `container_name:25565` on the shared bridge network.

## Managed Resource Rules
- Rails only creates and manages Docker resources for this app.
- Managed container names use `mc-server-<hostname>`.
- Managed volume names use `mc-data-<hostname>`.
- Managed resources must include these labels:
  - `app=mc-auto-starting`
  - `managed_by=rails`
  - `minecraft_server_id=<db id>`
  - `minecraft_server_hostname=<hostname>`

## Wrapper Scope
The Docker wrapper only exposes operations needed by the current app responsibilities.

- `ping!`
- `version`
- `inspect_container(id_or_name:)`
- `inspect_volume(name:)`
- `list_managed_containers`
- `create_volume(name:, labels:)`
- `remove_volume(name:)`
- `create_container(name:, image:, env:, mounts:, labels:, network_name:, memory_mb:)`
- `start_container(id:)`
- `stop_container(id:, timeout_seconds:)`
- `restart_container(id:, timeout_seconds:)`
- `remove_container(id:, force: false)`

The wrapper does not expose:

- arbitrary `docker` CLI execution
- `exec`
- `logs`
- image build
- prune or system-wide cleanup
- non-managed container listing helpers

## Engine API Mapping
- `GET /_ping`
- `GET /version`
- `GET /containers/{id}/json`
- `GET /volumes/{name}`
- `GET /containers/json?all=1&filters=...`
- `POST /volumes/create`
- `DELETE /volumes/{name}`
- `POST /containers/create?name=...`
- `POST /containers/{id}/start`
- `POST /containers/{id}/stop?t=...`
- `POST /containers/{id}/restart?t=...`
- `DELETE /containers/{id}?force=...`

## Compose Strategy
- The `app` service mounts `/var/run/docker.sock`.
- The `mc-router` service is defined and lifecycle-managed in `compose.yaml`.
- The `mc-router` service joins the shared bridge network as an external named Docker network.
- The `mc-router` service reads the generated routes file from a bind-mounted host path and watches it for changes.
- The `mc-router` service publishes `${MINECRAFT_PUBLIC_PORT}:25565`.
- App-created Minecraft containers join the same shared bridge network at create time.
- No Docker socket proxy is introduced in the initial implementation.

## Rails Integration Shape
- `DockerEngine::Connection`
  - Handles Unix socket HTTP transport and response normalization.
- `DockerEngine::Client`
  - Owns the allowed Engine API surface and uses unversioned paths by default, with optional explicit version prefixing via configuration.
- `DockerEngine::ManagedLabels`
  - Builds the required labels for app-managed resources.
- `DockerEngine::ManagedName`
  - Builds container and volume names from normalized hostnames.
- `DockerEngine::Configuration`
  - Holds socket path, optional API version override, and timeout settings for the wrapper.

## mc-router Backend Contract
- `RouterRoute` publication resolves the backend to `<container_name>:25565`.
- Backend host values come from app-managed container names, not host IPs or provider allocations.
- Route publication remains a full desired-state config render.
