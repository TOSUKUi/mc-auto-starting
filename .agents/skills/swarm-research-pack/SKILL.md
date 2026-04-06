---
name: swarm-research-pack
description: Build compact task-scoped evidence packs from local code, docs, notes, and diffs before implementation or design review. Use when Codex needs to triage many local artifacts, prepare briefing material for swarm-meeting, separate known facts from assumptions, or narrow what should be loaded into live context.
---

Use this skill to compress evidence before deeper reasoning.

## Inputs

Provide:
- topic
- one profile name
- optional questions
- relevant local paths
- optional constraints

## Workflow

1. Load exactly one profile from `profiles/`.
2. Start from the smallest relevant local artifacts, not the whole repo.
3. Produce a pack with facts, artifact previews, unknowns, and suggested next reads.
4. Keep the pack small. Prefer 4-8 artifacts by default.
5. Hand the pack to `swarm-meeting`, `task-supervisor-loop`, or `task-implementer`.

## Guardrails

- Do not dump whole files into the pack.
- Prefer a manifest plus short previews with file references.
- Call out stale, missing, or ambiguous artifacts.
- Separate facts from inferences.
- Treat the pack as disposable working context, not permanent truth.

## Resources

- `profiles/codebase-first.yaml`: default local-codebase triage.
- `profiles/decision-prep.yaml`: heavier pack for architecture or product decisions.
- `references/source-triage.md`: artifact selection guidance.
- `scripts/build_research_pack.py`: generate a compact pack from selected paths.
