# Artifact Contracts

Keep these artifacts small and task-scoped.

## `task_record`

- `task_id`
- `goal`
- `constraints`
- `done_definition`
- `non_goals`
- `write_back_targets`

## `research_pack`

- `task_id`
- `facts`
- `assumptions`
- `selected_artifacts`
- `why_selected`
- `exclusions`
- `open_questions`

## `implementation_brief`

- `task_id`
- `change_summary`
- `files_in_scope`
- `invariants`
- `checks_to_run`
- `done_definition`
- `known_unknowns`

## `evaluation_report`

- `task_id`
- `decision`
- `findings`
- `residual_risks`
- `doc_mismatches`
- `write_back_targets`

## `restart_note`

- `task_id`
- `latest_outcome`
- `next_action`
- `reload_set`
- `open_questions`

## `plan_delta`

Only create this when dependency order, task decomposition, or the critical path changed.

- `reason_for_change`
- `changed_dependencies`
- `changed_order`
- `new_follow_up_tasks`
