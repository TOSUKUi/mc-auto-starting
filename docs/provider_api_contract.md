# Execution Provider API Contract

## Purpose
This document fixes the execution-provider contract for `T-300`.

## Selected Provider
- Provider family: `Pterodactyl Panel + Wings`
- Selection status: fixed for the current implementation baseline
- Basis:
  - The implementation draft already assumes `execution_provider/pterodactyl_client.rb`.
  - The project requires an external control API and does not allow Rails to manage Docker directly.

## Version Baseline
- Panel reference: `pterodactyl/panel` public upstream
- Confirmed latest release observed during this investigation: `v1.12.1` on February 14, 2026
- Contract target:
  - Prefer Panel `1.12.x`
  - Keep the Rails-side interface tolerant of nearby `1.x` releases where endpoint semantics remain unchanged

## API Split
Pterodactyl has two relevant HTTP API surfaces.

- Application API:
  - Administrative API
  - Used for provisioning and destructive admin operations
  - Base path: `/api/application`
  - Auth: application API key in `Authorization: Bearer ...`
- Client API:
  - Per-user server control API
  - Used for runtime lifecycle operations and resource/status reads
  - Base path: `/api/client`
  - Auth: client API key in `Authorization: Bearer ...`

## Required Authentication Model
- Rails must hold two credentials:
  - `application_api_key` for create/delete and panel metadata lookups
  - `client_api_key` for lifecycle operations and runtime status checks
- The client API key should belong to a dedicated service account with access to all provider-managed servers.
- Inference from the official route split:
  - create/delete do not exist on the client API
  - start/stop/restart/resources do not exist on the application API

## Required Endpoints

### Provisioning and destructive admin operations
- Create server:
  - `POST /api/application/servers`
- Fetch server:
  - `GET /api/application/servers/{server}`
- Delete server:
  - `DELETE /api/application/servers/{server}`

### Provider metadata lookups needed before create
- List or inspect nodes:
  - `GET /api/application/nodes`
  - `GET /api/application/nodes/{node}`
- List allocations on a node:
  - `GET /api/application/nodes/{node}/allocations`
- List nests and eggs:
  - `GET /api/application/nests`
  - `GET /api/application/nests/{nest}/eggs`
  - `GET /api/application/nests/{nest}/eggs/{egg}`

### Runtime lifecycle and status
- Fetch server detail:
  - `GET /api/client/servers/{server}`
- Fetch current utilization/state:
  - `GET /api/client/servers/{server}/resources`
- Start/stop/restart/kill:
  - `POST /api/client/servers/{server}/power`
- Fetch websocket token/socket for richer runtime integrations if needed later:
  - `GET /api/client/servers/{server}/websocket`

## Lifecycle Mapping for Rails
- `create`:
  - Application API `POST /api/application/servers`
- `delete`:
  - Application API `DELETE /api/application/servers/{server}`
- `start`:
  - Client API `POST /api/client/servers/{server}/power` with `signal=start`
- `stop`:
  - Client API `POST /api/client/servers/{server}/power` with `signal=stop`
- `restart`:
  - Client API `POST /api/client/servers/{server}/power` with `signal=restart`
- `status`:
  - Client API `GET /api/client/servers/{server}/resources`
  - Read `attributes.current_state`

## Create Request Shape
The upstream `StoreServerRequest` confirms that the create payload requires at least the following fields.

- `name`
- `owner_id`
- `node_id`
- `egg_id`
- `limits.memory`
- `limits.swap`
- `limits.disk`
- `limits.io`
- `limits.cpu`
- `limits.threads`
- `limits.oom_killer`
- `feature_limits.allocations`
- `feature_limits.backups`
- `feature_limits.databases`
- `allocation.default`
- `environment`
- `skip_scripts`

Important implication:
- Our current Rails create-page scaffolding is not enough for real provisioning yet.
- We need a Rails-side mapping from app-level template/version choices to:
  - Pterodactyl owner account
  - node selection policy
  - egg selection
  - startup environment variables
  - allocation selection

## Backend Host and Port Discovery
Rails needs a stable source for `backend_host` and `backend_port`.

Contract decision:
- `backend_port` = the selected primary allocation port
- `backend_host` = the selected primary allocation IP or alias from the node allocation record

Reasoning:
- Wings documentation defines an allocation as an IP+Port pair assigned to a server.
- The create payload uses `allocation.default`, which is an allocation ID.
- Therefore Rails can resolve backend connection data by looking up the chosen allocation on the target node.

Operational note:
- When the node is behind NAT, Wings documentation explicitly allows allocations to use the internal IP.
- Therefore `backend_host` is the provider backend target for router integration, not necessarily a public IP.

## Status Mapping Baseline
Initial Rails mapping from Pterodactyl runtime state should be:

- `running` -> Rails `ready`
- `starting` -> Rails `starting`
- `stopping` -> Rails `stopping`
- `offline` -> Rails `stopped`

Additional rule:
- If the provider lookup fails or the panel reports a conflicting or missing server while DB state expects one, treat as `degraded` until reconciliation logic is implemented.

## Known Follow-up Work
- `T-301`: define the Ruby interface around the split Application/Client API model
- `T-302`: implement the concrete Pterodactyl client(s)
- `T-303`: configure both application and client credentials
- `T-502`: harden rollback and failure-state handling around partial provisioning or route-apply failures
- `T-504`: use the persisted provider server identifier for client-API lifecycle operations

## Sources
- Official site: https://pterodactyl.io/
- Official terminology docs: https://pterodactyl.io/project/terms.html
- Official Wings docs:
  - https://pterodactyl.io/wings/1.0/installing.html
  - https://pterodactyl.io/community/config/nodes/add_node.html
- Official panel source:
  - https://github.com/pterodactyl/panel
  - `routes/api-application.php`
  - `routes/api-client.php`
  - `app/Http/Requests/Api/Application/Servers/StoreServerRequest.php`
  - `app/Http/Controllers/Api/Client/Servers/PowerController.php`
