# Implementation Brief

The brief should fit on one screen and contain only what the implementer needs.

## Required Fields

- `task_id`
- `change_summary`
- `files_in_scope`
- `invariants`
- `checks_to_run`
- `done_definition`

## Optional Fields

- `selected_artifacts`
- `known_unknowns`
- `non_goals`

## When The Brief Is Thin

- Add the nearest missing context only.
- Prefer reading one adjacent file over broad discovery.
- If the missing context changes scope, return a short blocker note instead of improvising.
