# Session Boundaries

Treat each phase as disposable.

## Research

- Inputs: task record, narrow local paths, relevant docs
- Output: `research_pack`
- Do not pass raw notes forward when the pack is enough

## Implementation

- Inputs: `implementation_brief`, selected artifacts, nearby code only if blocked
- Output: implementation result summary plus checks run
- Do not absorb unrelated project history

## Evaluation

- Inputs: `implementation_brief`, changed files or diff, checks run, touched docs
- Output: `evaluation_report`
- Do not restage implementation planning

## Write-Back

- Inputs: accepted implementation result, `evaluation_report`, target docs
- Output: `restart_note` and optional `plan_delta`
- Do not rewrite unchanged project history
