# Direct Docker Lifecycle Contract

## Purpose
This document fixes the lifecycle, sync, and delete contract for direct-Docker tasks `T-401` through `T-403`.

## Scope
- `Servers::StartServer`
- `Servers::StopServer`
- `Servers::RestartServer`
- `Servers::SyncServerState`
- `Servers::DestroyServer`

These services operate only on app-managed Minecraft containers and their paired managed volumes / router routes.

## Managed Resource Preconditions
- Lifecycle operations target the server's managed container via `container_id` when present.
- If `container_id` is missing, services may fall back to `container_name` only for reconciliation or cleanup.
- Services must not operate on arbitrary containers outside the app-managed naming / label contract.

## Docker API Usage
- `start`
  - `POST /containers/{id}/start`
- `stop`
  - `POST /containers/{id}/stop?t=...`
- `restart`
  - `POST /containers/{id}/restart?t=...`
- `sync`
  - `GET /containers/{id}/json`
- `delete`
  - `DELETE /containers/{id}?force=1`
  - `DELETE /volumes/{name}`

`sync` is based on Docker inspect state, not on stale DB state.

## Lifecycle Transition Rules
- `start`
  - Docker call succeeds: transition to `starting`
  - `container_state` should be updated to `running`
  - `last_started_at` should be refreshed
- `stop`
  - Docker call succeeds: transition to `stopping`
  - `container_state` should be updated to `exited`
- `restart`
  - Docker call succeeds: transition to `restarting`
  - `container_state` should be updated to `running`
  - `last_started_at` should be refreshed
- `sync`
  - inspect result is mapped onto both `container_state` and Rails `status`
  - conflicting or missing runtime state degrades the server instead of trusting stale DB values

## Docker State to Rails Status Mapping
The initial direct-Docker mapping is:

- `created` -> `stopped`
- `running` -> `ready`
- `paused` -> `degraded`
- `restarting` -> `restarting`
- `removing` -> `deleting`
- `exited` -> `stopped`
- `dead` -> `degraded`

Unknown Docker states should map to `degraded`.

## Sync Reconciliation Rules
- `sync` should read `container_id` first.
- If `container_id` is blank, `sync` may inspect by `container_name` when present.
- When inspect succeeds:
  - persist canonical `container_id`
  - persist `container_state`
  - clear `last_error_message`
  - transition Rails status to the mapped state when that transition is allowed
- When inspect returns `NotFound`:
  - clear `container_id`
  - clear `container_state`
  - set `last_error_message`
  - transition to `degraded` if possible
- When mapped status conflicts with the current transition graph:
  - keep the inspected `container_state`
  - transition to `degraded` if possible

## Delete Flow Order
The direct-Docker delete sequence is:

1. transition server to `deleting`
2. unpublish the router route through `Router::PublicationSync(enabled: false)`
3. remove the managed container with `force: true`
4. remove the managed volume
5. destroy the server record

This order keeps the public route from pointing at a runtime that is being torn down.

## Delete Error Handling
- Route unpublish failure is fatal for the delete request.
- Container `NotFound` during delete is tolerated and treated as already gone.
- Volume `NotFound` during delete is tolerated and treated as already gone.
- Other Docker errors leave the server record in `deleting` with `last_error_message` populated.
- Delete must not destroy the DB record until route unpublish and Docker cleanup have both succeeded or been explicitly tolerated as already absent.

## Last Error Handling
- Successful lifecycle and sync operations should clear `last_error_message`.
- Failed lifecycle, sync, and delete operations should persist a user-visible `last_error_message`.

## Router Publication Expectations
- `start`, `stop`, and `restart` do not rewrite router config directly.
- `sync` may leave the route enabled while the server is `stopped`, because stopped servers remain within the current publication-eligible status set.
- `destroy` is the operation that must unpublish the route.

## Non-Goals
- No automatic container recreation during `sync`
- No implicit volume recreation during `start`
- No host-port publishing
- No orchestration of non-managed Docker resources
