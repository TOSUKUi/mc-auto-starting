---
name: task-implementer
description: Implement a bounded change from a task-scoped brief without reloading the whole project history. Use when Codex already has an implementation brief or research pack and should keep coding context narrow.
---

Use this skill when the task has already been scoped and the main job is to change code or docs within that boundary.

## Inputs

Provide:
- `implementation_brief`
- selected artifacts or file paths
- optional constraints and acceptance checks

## Workflow

1. Read the implementation brief before reading more project context.
2. Inspect only the selected files and the nearest required adjacency.
3. Confirm the invariants and done definition.
4. Implement the smallest credible change that satisfies the brief.
5. Run targeted checks that match the brief.
6. Return an implementation result with:
   - changed files
   - checks run
   - assumptions
   - unresolved issues
   - suggested write-back targets

## Expansion Policy

Expand context only when blocked.

- Prefer nearby code, tests, configs, or docs over broad repo reads.
- Record why extra context was needed.
- If the brief is materially insufficient, say exactly what is missing instead of silently redesigning the task.

## Guardrails

- Do not rewrite task planning, current state, or restart docs unless the brief explicitly includes them.
- Do not turn implementation into an architecture redesign.
- Keep notes factual and task-scoped.
- Respect the existing `done_definition` instead of inventing a new scope.

## Output Contract

Use this section order unless the user asks for something else:

```markdown
# Implementation Result
## Changed Files
## Checks Run
## Assumptions
## Unresolved Issues
## Suggested Write-Back Targets
```

## Resources

- `references/implementation-brief.md`: required fields and how to react when the brief is incomplete.
