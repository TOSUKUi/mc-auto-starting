# Critical Path

## Evidence Set
- `docs/project_execution_plan.md`
- `docs/task_board.md`
- `docs/context_map.md`
- Recent git history:
  - `6cae399` Define next UI, world transfer, and bot planning tasks

## Current Goal
Advance the remaining post-baseline follow-up work without reintroducing stale deployment assumptions or reopening the retired Kamal path.

## Active Dependency Chain
The currently evidenced open work is now a single remaining branch.

- Repository-local bot runtime track:
  - `T-1202` define repository-local Discord bot runtime contract

## Known Blockers
- No active blockers are recorded for the open tasks above.
- `T-910` is explicitly `blocked`, but the board describes it as historical context from the abandoned Kamal path and not part of the active delivery chain.

## Recent Path Changes
- The deploy path has already pivoted to production Compose + Komodo, and `T-911` through `T-914` completed the checked-in topology, image-publish path, production Compose, and rewritten runbooks.
- The direct-Docker, Discord auth/bot API, structured RCON, whitelist, player observability, runtime catalog, and current UI baselines are complete through `T-1121`.
- `T-1122` completed the remaining create-form memory-field alignment cleanup, and the remaining Phase 11 follow-up is now the repository-local bot-runtime branch after the world-transfer contract follow-up landed.
- `T-1200` fixed the managed world transfer contract, so the world-transfer branch now advances through `T-1201` implementation instead of remaining blocked on archive/staging authority decisions.
- `T-1201` completed the first-pass managed world export/import flow.
- `T-1203` completed the follow-up archive UX/format contract, fixing `.zip` as the next user-facing world-transfer format while keeping direct folder upload out of scope and preserving the existing Rails-owned transfer boundary.
- Commit `6cae399` added the next open tasks for the remaining UI cleanup, world transfer, and repository-local bot runtime specification.

## Immediate Next Checks
- Treat `T-1202` as the prerequisite for any separate-process bot implementation or deployment work.

## Unknowns And Assumptions
- The board does not declare a single active owner or in-progress task, so the ordering above is based on explicit dependencies plus restart-path safety, not on inferred staffing.

## Write-Back Targets
- Update this file when the current goal, open dependency chain, or blockers change.
