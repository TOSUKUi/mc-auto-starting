# Task Board

## Usage Rules
- Every task has a stable ID.
- Status values are `todo`, `in_progress`, `blocked`, `done`.
- Dependencies list prerequisite task IDs.
- Contributors and sub-agents should refer to task IDs in all progress reports.
- Add new tasks only if they cannot fit under an existing task.

## Status Summary
- `todo`: not started
- `in_progress`: actively being worked on
- `blocked`: cannot proceed due to dependency or decision gap
- `done`: finished with completion criteria met

## Core Board

| ID | Phase | Task | Dependencies | Status | Completion Criteria |
| --- | --- | --- | --- | --- | --- |
| T-000 | P0 | Validate Docker bootstrap files | - | done | `Dockerfile`, `compose.yaml`, `.gitignore` match current decisions |
| T-001 | P0 | Build app container | T-000 | done | `docker compose build app` succeeds |
| T-002 | P0 | Generate Rails app skeleton with MariaDB-compatible adapter | T-001 | done | Rails app skeleton exists and bootstrap docs were preserved |
| T-003 | P0 | Boot Rails app in Docker | T-002 | done | Rails boots and `bin/rails about` succeeds |
| T-004 | P0 | Configure Vite + Inertia + React + Mantine | T-003 | done | One Inertia page renders with Mantine provider through Vite |
| T-005 | P0 | Configure DB, Redis, env handling, queue baseline | T-003 | done | `bin/rails db:prepare` succeeds, env approach is documented, and dev UID/GID mapping is defined |
| T-100 | P1 | Choose and add authentication library | T-003 | done | Login/logout flow path is fixed and installed |
| T-101 | P1 | Generate `User` model and migration | T-100 | done | User model persists required attributes |
| T-102 | P1 | Baseline `MinecraftServer` model exists | T-101 | done | Existing model and table are available for pivot work |
| T-103 | P1 | Generate `ServerMember` model and migration | T-102 | done | Membership and role model works |
| T-106 | P1 | Add authorization framework and policies | T-101,T-102,T-103 | done | Owner/member visibility rules are enforced |
| T-107 | P1 | Add server visibility scopes and request protections | T-106 | done | Users cannot fetch other users' servers |
| T-110 | P0 | Pivot planning docs to direct Docker control | T-005 | done | Restart docs, design, plan, and task board reflect the `Rails + docker.sock` single-host approach |
| T-200 | P1 | Redesign `minecraft_servers` for direct Docker management | T-110,T-102 | todo | Direct-Docker fields and migration strategy are fixed |
| T-201 | P1 | Define slug normalization and uniqueness rules | T-200 | todo | `slug` format and DB uniqueness are enforceable |
| T-202 | P1 | Define `public_host:public_port` connection rules | T-200 | todo | Shared formatting logic is fixed for direct public-port access |
| T-203 | P1 | Define server status transition model | T-200 | todo | Direct-Docker state machine is documented and coded |
| T-204 | P1 | Plan removal of legacy `router_routes` data model | T-110,T-200 | todo | Cleanup order for router/provider-era schema is fixed |
| T-300 | P2 | Define docker.sock safety boundary and compose strategy | T-110 | todo | Compose and permission strategy for Docker Engine access are fixed |
| T-301 | P2 | Define Docker naming and label conventions | T-300,T-200 | todo | Container names, volume names, and labels are fixed |
| T-302 | P2 | Implement Docker Engine client wrapper | T-300 | todo | Rails can create/inspect/start/stop/restart/remove managed containers |
| T-303 | P2 | Implement public port allocator | T-200,T-300 | todo | Ports are reserved uniquely and released correctly |
| T-304 | P2 | Define direct-Docker environment contract | T-300,T-301 | todo | Required env such as image baseline, public host, and port range are documented |
| T-400 | P3 | Implement direct-Docker create flow | T-200,T-201,T-202,T-203,T-302,T-303 | todo | Create request persists a server, reserves a port, creates Docker resources, and stores identifiers |
| T-401 | P3 | Implement delete flow for direct-Docker servers | T-302,T-303,T-400 | todo | Delete removes managed container resources and frees the reserved port |
| T-402 | P3 | Implement start/stop/restart/sync flows | T-302,T-400 | todo | Lifecycle operations update Docker state and Rails status correctly |
| T-403 | P3 | Persist container runtime details on sync | T-302,T-402 | todo | `container_state`, timestamps, and last error fields stay reconcilable |
| T-500 | P4 | Simplify create UI for direct-Docker baseline | T-400,T-202,T-600 | todo | Create UI exposes only the fields needed for single-host Docker provisioning |
| T-501 | P4 | Simplify detail UI for container-first operations | T-402,T-600 | todo | Detail UI shows connection target and container/runtime info instead of provider/router info |
| T-502 | P4 | Update index UI for direct-Docker summary fields | T-202,T-600 | todo | Index UI reflects public ports and container status cleanly |
| T-503 | P4 | Localize operator-facing UI copy to Japanese baseline | T-500,T-501,T-502 | todo | Default operator-facing copy is Japanese across the active screens |
| T-600 | P5 | Build authenticated layout shell | T-004,T-100 | done | Shared layout works for signed-in pages |
| T-601 | P5 | Build login page | T-100,T-004 | done | UI login works |
| T-700 | P6 | Remove provider/router coupling from app services | T-400,T-401,T-402 | todo | Direct-Docker implementation no longer depends on provider/router services |
| T-701 | P6 | Remove legacy router/provider docs from active workflow | T-110,T-700 | todo | Restart docs no longer point to old provider/router docs as current truth |
| T-800 | P7 | Add model tests for direct-Docker rules | T-200,T-201,T-202,T-203 | todo | Core direct-Docker domain logic is covered |
| T-801 | P7 | Add request and authorization tests | T-400,T-401,T-402,T-500,T-501 | todo | Access control and create/lifecycle/delete flows are covered |
| T-802 | P7 | Add service tests for Docker client and allocators | T-302,T-303,T-400,T-401,T-402 | todo | Critical Docker orchestration paths are covered |
| T-803 | P7 | Add acceptance checks for direct-Docker requirement criteria | T-400,T-401,T-402,T-500,T-501 | todo | Main create/detail/delete/lifecycle paths are verifiable by automated checks |
| T-900 | P8 | Document single-host setup and local development workflow | T-300,T-304,T-400 | todo | New contributor can boot the project with docker.sock mounted |
| T-901 | P8 | Document direct-Docker operations and safety notes | T-302,T-401,T-402 | todo | Operators can manage containers and understand docker.sock risks |
| T-902 | P8 | Document release, migration, and rollback procedure | T-803,T-900,T-901 | todo | Release workflow is written and reviewable for the new architecture |

## Critical Path Tasks

The current critical path is:

`T-110 -> T-200 -> T-201 -> T-202 -> T-203 -> T-300 -> T-301 -> T-302 -> T-303 -> T-400 -> T-402 -> T-500 -> T-501 -> T-803 -> T-900 -> T-901 -> T-902`

## Known Blockers

- No active blockers are recorded.
- The repository still contains legacy provider/router code and docs; treat them as migration debt, not the current target architecture.
