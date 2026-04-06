# Evidence Checklist

Start from the smallest artifacts that can answer the target docs.

## Good Sources

- existing `AGENTS.md`
- `docs/project/*`
- task board or execution-plan docs
- architecture or contract docs
- root `README`
- primary configs or compose files
- recent accepted commits when present

## Questions To Answer

- What is the product and current delivery phase?
- Which technical decisions are stable enough to belong in durable state?
- What work is active right now?
- What dependency chain currently blocks progress?
- What risks are real and current?

## Bad Sources

- stale scratch notes without confirmation
- broad transcript history
- speculative TODOs with no accepted status
- details that belong in runbooks or contracts instead of state docs

## Unknowns Rule

When evidence is incomplete:

- mark the field as unknown
- list the missing source
- avoid inferring specifics that are not supported by repo evidence
