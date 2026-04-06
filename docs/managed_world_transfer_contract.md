# Managed World Transfer Contract

## Purpose

This document fixes the contract for `T-1200` before any managed world download/upload implementation begins.

## Scope

In scope:

- web-driven export of a managed server world archive
- web-driven upload of a replacement world archive
- authority, safety, staging, and Docker-volume sequencing for that flow

Out of scope in this phase:

- the actual controller/service/UI implementation from `T-1201`
- bot-driven world transfer
- partial in-place edits to a running server
- host-side manual `docker` CLI procedures as the supported product path

## Locked Decisions

### 1. World transfer is Rails-owned and volume-based

- The first-pass `world` transfer feature operates on the managed Docker data volume mounted at `/data`.
- Export and import both treat the managed volume as the canonical source of truth for server data.
- The transfer artifact therefore represents the managed `/data` volume contents, not a narrower path such as only `/data/world`.

Rationale:

- the current runtime mounts one managed volume at `/data`
- world state, whitelist state, and adjacent server files already live under that managed volume
- a full-volume archive avoids ambiguous path selection in the first implementation pass

### 2. Authority is stronger than lifecycle authority

- `admin` may export or import any visible managed server.
- server `owner` may export or import owned servers.
- server-local `manager` membership may continue to use lifecycle actions, but may not export or import world data.
- `viewer` may not export or import world data.
- the first pass is web-only; no Discord bot world-transfer surface is part of the accepted contract.

Rationale:

- export can exfiltrate the full managed server data set
- import is destructive and replaces the managed server data set
- this is closer to ownership/admin authority than ordinary lifecycle control

### 3. Transfer requires a stopped managed server

- Export and import both require the effective server runtime to be stopped before work begins.
- The implementation should reconcile runtime state through the existing Docker inspect/sync path before deciding whether the request is allowed.
- Requests must reject any server in `ready`, `starting`, `restarting`, `stopping`, `deleting`, `provisioning`, or `degraded` states when Docker still indicates a running or unstable container.
- The feature must not auto-stop the server on behalf of the acting user.

Rationale:

- a live world write during export can produce an inconsistent archive
- import replaces volume contents and therefore cannot run safely against an active container
- the user should make the stop decision explicitly through the existing lifecycle path

### 4. Only app-managed volumes are eligible

- The request must target a server record that has a managed `volume_name`.
- The implementation must verify that the referenced Docker volume exists and still belongs to the app-managed label set before transfer starts.
- Rails must not read from or write to arbitrary Docker volumes outside the managed naming/label contract.

## Archive Contract

### Export format

- Export produces a single `.tar.gz` file.
- The archive root represents the contents of the managed `/data` volume.
- Export filenames should use a stable operator-readable pattern such as `<hostname>-world-<timestamp>.tar.gz`.
- The feature is a one-shot download surface, not a persistent archive catalog.

### Import format

- Import accepts `.tar.gz` only.
- The uploaded archive must expand into a relative-path tree that can become the managed `/data` volume root.
- Absolute paths, `..` traversal, device files, FIFOs, sockets, and hard links are rejected.
- Symbolic links are also rejected in the first pass to keep extraction behavior predictable.
- Empty archives are rejected.

### Size and safety limits

- Maximum compressed upload size: `5 GiB`.
- Maximum expanded archive size after validation: `10 GiB`.
- The implementation must validate both the uploaded byte size and the expanded total size before replacing managed volume contents.
- The implementation should fail closed when archive metadata cannot be parsed safely.

## Temporary Storage Contract

- Rails stages export and import work under `Rails.root.join("tmp/world_transfers")`.
- Each request must use an isolated subdirectory such as `tmp/world_transfers/<request_id>/`.
- Staged files are temporary operating artifacts, not durable backups.
- Success and failure paths must both attempt best-effort cleanup of the request staging directory.
- Cleanup failure should be logged and surfaced as an operator-readable warning, but it must not silently widen the storage scope into a persistent archive store.

## Docker Volume Operation Sequence

The implementation must use short-lived helper-container work rather than shelling out to host-side `docker` CLI commands from Rails.

### Export sequence

1. authorize the acting user as `admin` or server `owner`
2. reconcile runtime state and reject unless the server is stopped
3. verify the managed source volume exists and matches the app-managed ownership boundary
4. create a request-local staging directory under `tmp/world_transfers`
5. start a short-lived helper container that mounts:
   - the managed source volume read-only at `/source`
   - the request staging directory at `/staging`
6. inside the helper container, create `/staging/<filename>.tar.gz` from the contents of `/source`
7. stream or send the staged archive to the authorized caller
8. remove the helper container and delete the staging directory

### Import sequence

1. authorize the acting user as `admin` or server `owner`
2. reconcile runtime state and reject unless the server is stopped
3. validate upload extension, compressed size, and archive metadata
4. stage the uploaded file under `tmp/world_transfers/<request_id>/upload.tar.gz`
5. extract into a separate request-local validation directory and reject unsafe or oversized contents
6. start a short-lived helper container that mounts:
   - the validated extraction directory read-only at `/incoming`
   - the managed target volume read-write at `/target`
7. inside the helper container:
   - remove the existing contents of `/target`
   - copy the validated `/incoming` tree into `/target`
8. keep the server stopped after import; do not auto-start it
9. remove the helper container and delete the staging directory

## Failure Handling

- Export failure must leave the managed volume untouched.
- Import failure must leave the server stopped and return an operator-readable error.
- The first pass does not promise rollback of partially replaced volume contents after the destructive import step begins.
- Because import is destructive, the UI should direct operators to export first if they need a backup.

## UI And API Expectations

- The first pass is a server-detail web flow for owner/admin users.
- Export should be presented as a direct download action.
- Import should require an explicit replacement upload action with destructive wording.
- Manager/viewer users should not see actionable transfer controls.
- There is no multi-archive history, background job queue contract, or bot command surface in this phase.

## Follow-Up For `T-1201`

- add policy/controller enforcement for the stronger owner/admin-only boundary
- add helper-container support without widening Rails into arbitrary Docker control
- add archive validation, staging cleanup, and operator-visible error handling
- add request/service coverage for stopped-server enforcement and destructive import behavior
