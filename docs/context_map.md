# Context Map

## Purpose
This file tells any contributor or agent where to find authoritative information after a context reset.

## Read First
- `AGENTS.md`

## Architecture and Implementation Design
- `docs/implementation_breakdown.md`
  Use for planned screens, routes, directory structure, and initial implementation decomposition.

## Full Project Plan and Critical Path
- `docs/project_execution_plan.md`
  Use for phase ordering, dependency flow, critical path, completion criteria, and milestone planning.

## Shared Progress Tracking
- `docs/task_board.md`
  Use for unified task IDs, status tracking, blockers, and assignment across contributors or sub-agents.

## Disposable Session Context
- `.local/session_context.md`
  Use for temporary restart notes, recent findings, in-flight command plans, and handoff notes that should not be committed.

## Bootstrap / Environment Files
- `Dockerfile`
- `compose.yaml`
- `.gitignore`

## Current Start State
- Rails application skeleton has been generated in-place.
- Docker bootstrap exists.
- MariaDB `10.11.16` is the chosen database runtime.
- Mantine version target is `8.3.1`.
- Bootstrap is complete through `T-005`; the next active entry point is `T-004` for frontend baseline work.
