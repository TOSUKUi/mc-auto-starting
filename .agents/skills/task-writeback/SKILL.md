---
name: task-writeback
description: Update restart notes, task records, and plan deltas after a task without bloating AGENTS.md. Use when Codex should write back the minimum durable context needed for the next fresh session.
---

Use this skill after evaluation to keep durable artifacts aligned with the latest accepted task result.

## Inputs

Provide:
- accepted implementation result or summary
- `evaluation_report`
- target docs or durable artifacts
- optional current task-board or critical-path context

## Workflow

1. Identify the minimum durable artifacts that actually changed.
2. Update `restart_note` first.
3. Update task status or current-state docs only where the accepted result changed facts.
4. Create a `plan_delta` only when dependency order, task decomposition, or the critical path changed.
5. Return a concise write-back summary with:
   - updated targets
   - restart note summary
   - optional plan delta
   - remaining follow-ups

## Guardrails

- Keep `AGENTS.md` as a thin constitution. Do not move operational detail back into it.
- Prefer patching the affected section over rewriting entire docs.
- Keep `current_state` compressed. Detailed reasoning belongs in decision docs or task artifacts, not in the restart note.
- Mark assumptions explicitly when write-back depends on inference.
- Do not emit a critical-path change unless the task actually changed sequencing or dependencies.

## Output Contract

Use this section order unless the user asks for something else:

```markdown
# Write-Back Summary
## Updated Targets
## Restart Note
## Plan Delta
## Remaining Follow-Ups
```

## Resources

- `references/writeback-policy.md`: when to update restart material, current state, and the critical path.
