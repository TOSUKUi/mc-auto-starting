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
| T-102 | P1 | Generate `MinecraftServer` model and migration | T-101 | done | Server model stores owner, status, backend, provider identifiers |
| T-103 | P1 | Generate `ServerMember` model and migration | T-102 | done | Membership and role model works |
| T-104 | P1 | Generate `RouterRoute` model and migration | T-102 | done | Route state can be persisted |
| T-105 | P1 | Generate `AuditLog` model and migration | T-101 | done | Audit events can be recorded |
| T-106 | P1 | Add authorization framework and policies | T-101,T-102,T-103 | done | Owner/member visibility rules are enforced |
| T-107 | P1 | Add server visibility scopes and request protections | T-106 | todo | Users cannot fetch other users' servers |
| T-200 | P2 | Define hostname normalization rules | T-102 | done | Allowed characters, lowercase rule, reserved words documented and coded |
| T-201 | P2 | Add hostname unique index and validations | T-200 | done | Duplicate hostname cannot persist |
| T-202 | P2 | Define fqdn and `hostname:port` generation rules | T-200 | done | Shared formatting logic exists |
| T-203 | P2 | Define server status transition model | T-102 | done | State machine or equivalent rules are documented and coded |
| T-300 | P3 | Confirm external execution-provider API contract | T-102,T-200 | blocked | Endpoints, auth, and backend discovery are known |
| T-301 | P3 | Implement provider base client interface | T-300 | todo | Unified create/delete/start/stop/restart/status contract exists |
| T-302 | P3 | Implement concrete provider client | T-301 | todo | Provider client can talk to target API or a stubbed equivalent |
| T-303 | P3 | Add provider config and initialization | T-301 | todo | Environment-driven provider selection works |
| T-400 | P4 | Confirm mc-router config and reload contract | T-200 | blocked | Input format and reload mechanism are known |
| T-401 | P4 | Implement route definition builder | T-400,T-104 | todo | Route definition can be built from DB state |
| T-402 | P4 | Implement config renderer | T-401 | todo | Whole router config can be rendered |
| T-403 | P4 | Implement config applier and reload | T-402 | todo | Config can be written and reload triggered safely |
| T-404 | P4 | Implement route health checking | T-403 | todo | Route/application health can be persisted |
| T-500 | P5 | Implement server create controller flow | T-102,T-106,T-201,T-301 | todo | Create request stores provisional record and queues work |
| T-501 | P5 | Implement create job end-to-end | T-500,T-302,T-403 | todo | Provider create, backend save, route apply, ready transition all work |
| T-502 | P5 | Implement rollback and failure-state handling | T-501 | todo | Failed create does not leave inconsistent publication state |
| T-503 | P5 | Implement delete flow | T-403,T-302,T-106 | todo | Deletion removes route and updates DB state |
| T-504 | P5 | Implement start/stop/restart/sync flows | T-302,T-106 | todo | Lifecycle operations update status correctly |
| T-505 | P5 | Implement audit event recording for lifecycle actions | T-105,T-500 | todo | Important events are stored consistently |
| T-600 | P6 | Build authenticated layout shell | T-004,T-100 | todo | Shared layout works for signed-in pages |
| T-601 | P6 | Build login page | T-100,T-004 | todo | UI login works |
| T-602 | P6 | Build server index page | T-107,T-600 | todo | User sees only owned/member servers |
| T-603 | P6 | Build server creation page | T-500,T-600,T-202 | todo | User can submit create request and see status |
| T-604 | P6 | Build server detail page | T-504,T-600 | todo | User can inspect and operate server |
| T-605 | P6 | Build members management page | T-103,T-106,T-600 | todo | Owner can manage memberships |
| T-606 | P6 | Build audit log page | T-105,T-505,T-600 | todo | User can read relevant event history |
| T-607 | P6 | Build monitoring page | T-700,T-701,T-702,T-703,T-704,T-600 | todo | Admin can inspect platform health |
| T-700 | P7 | Implement mc-router process and port health monitoring | T-403 | todo | Router liveness is detectable |
| T-701 | P7 | Implement DB vs router consistency check | T-403,T-104 | todo | Missing/extraneous routes are detectable |
| T-702 | P7 | Implement DB vs execution-provider consistency check | T-302,T-102 | todo | Missing/extraneous provider servers are detectable |
| T-703 | P7 | Implement backend connectivity checks | T-302,T-102 | todo | Backend reachability is persisted |
| T-704 | P7 | Implement unknown hostname detection | T-400 | todo | Unknown hostnames are logged and counted |
| T-800 | P8 | Add model tests | T-101,T-102,T-103,T-104,T-105,T-201,T-203 | todo | Core domain logic is covered |
| T-801 | P8 | Add request and authorization tests | T-106,T-107,T-500,T-503,T-504 | todo | Access control regressions are caught |
| T-802 | P8 | Add service and job tests | T-301,T-302,T-403,T-501,T-701,T-702 | todo | Critical async and service paths are covered |
| T-803 | P8 | Add acceptance checks for requirement criteria | T-501,T-503,T-704 | todo | Main acceptance conditions are verifiable |
| T-900 | P9 | Document setup and local development workflow | T-003,T-004,T-005 | todo | New contributor can boot project locally |
| T-901 | P9 | Document provider and router integration operations | T-403,T-501 | todo | Operational integration steps are written |
| T-902 | P9 | Document release, migration, and rollback procedure | T-803 | todo | Release workflow is written and reviewable |

## Critical Path Tasks
The main critical path currently is:

`T-000 -> T-001 -> T-002 -> T-003 -> T-100 -> T-101 -> T-102 -> T-200 -> T-201 -> T-300 -> T-301 -> T-302 -> T-400 -> T-401 -> T-402 -> T-403 -> T-500 -> T-501 -> T-700/T-701/T-702 -> T-602/T-603/T-604 -> T-803`

## Known Blockers
- `T-300`: final execution-provider API contract is not confirmed
- `T-400`: final mc-router config/reload contract is not confirmed
