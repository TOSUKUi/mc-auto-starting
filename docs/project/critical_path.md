# Critical Path

## Evidence Set
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/context_map.md`
- Recent git history:
  - `6cae399` Define next UI, world transfer, and bot planning tasks

## Current Goal
Keep the restart path aligned with the actual production direction, then advance the remaining Phase 11 follow-up work without reintroducing stale deployment assumptions.

## Active Dependency Chain
The currently evidenced open work is branch-shaped rather than one long serial chain.

- Restart-path cleanup:
  - `T-915` remove obsolete Kamal config/docs from the active restart path
- Small UI follow-up:
  - `T-1122` fix create-form memory-field alignment
- World-transfer track:
  - `T-1200` define managed world download/upload contract
  - `T-1201` implement managed world download/upload flow
- Repository-local bot runtime track:
  - `T-1202` define repository-local Discord bot runtime contract

## Known Blockers
- No active blockers are recorded for the open tasks above.
- `T-910` is explicitly `blocked`, but the board describes it as historical context from the abandoned Kamal path and not part of the active delivery chain.

## Recent Path Changes
- The deploy path has already pivoted to production Compose + Komodo, and `T-911` through `T-914` completed the checked-in topology, image-publish path, production Compose, and rewritten runbooks.
- The direct-Docker, Discord auth/bot API, structured RCON, whitelist, player observability, runtime catalog, and current UI baselines are complete through `T-1121`.
- Commit `6cae399` added the next open tasks for the remaining UI cleanup, world transfer, and repository-local bot runtime specification.

## Immediate Next Checks
- Finish `T-915` so restart guidance no longer competes with obsolete Kamal artifacts.
- Treat `T-1200` as the main prerequisite for any world export/import implementation work.
- Treat `T-1202` as the prerequisite for any separate-process bot implementation or deployment work.
- Keep `T-1122` scoped as a small UI correction, not a reopen of the broader `T-503` UI baseline.

## Unknowns And Assumptions
- The board does not declare a single active owner or in-progress task, so the ordering above is based on explicit dependencies plus restart-path safety, not on inferred staffing.
- `T-915` is presented here as the first cleanup target because it directly affects restart reliability, even though it is not a dependency for the Phase 11 tasks.

## Write-Back Targets
- Update this file when the current goal, open dependency chain, or blockers change.
