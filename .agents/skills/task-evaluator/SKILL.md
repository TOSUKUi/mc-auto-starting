---
name: task-evaluator
description: Evaluate a task result against its stated scope, risks, and doc consistency. Use when Codex should review an implementation against a done definition instead of continuing to design or code inside the same session.
---

Use this skill to review a task result after implementation and before write-back.

## Inputs

Provide:
- `implementation_brief`
- changed files or diff
- checks run and results
- optional touched docs or restart artifacts

## Workflow

1. Read the done definition and invariants first.
2. Inspect the changed files or diff and the relevant checks.
3. Look for:
   - requirement gaps
   - behavioral regressions
   - missing or weak tests
   - docs or restart-material drift
4. Separate blocking findings from suggestions.
5. Produce an `evaluation_report` with:
   - `decision`
   - `findings`
   - `residual_risks`
   - `doc_mismatches`
   - `write_back_targets`

## Guardrails

- Findings come first.
- Judge against the stated task scope before proposing broader redesigns.
- If there are no findings, say so explicitly and mention residual risks or testing gaps.
- Do not edit code while evaluating unless the user explicitly asks for combined fix-up work.

## Output Contract

Use this section order unless the user asks for something else:

```markdown
# Evaluation Report
## Findings
## Decision
## Residual Risks
## Doc Mismatches
## Required Write-Back
```

## Resources

- `references/evaluation-checklist.md`: practical checklist for deciding pass, fail, or partial accept.
