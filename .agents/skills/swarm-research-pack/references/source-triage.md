# Source Triage

Use this reference when deciding which local artifacts belong in a research pack.

## Read Order

1. Start with the task statement, issue text, or commit diff.
2. Read the smallest code file closest to the change.
3. Read the nearest tests.
4. Read config or build files that shape behavior.
5. Read docs, notes, ADRs, or design comments only when they answer an active question.

## Keep

- Files that directly answer the decision question
- Tests that encode expected behavior
- Config files that change runtime, build, or indexing behavior
- Notes that capture constraints or prior decisions

## Drop

- Large files with no direct bearing on the current task
- Duplicate sources that restate the same fact
- Screenshots or logs without a clear decision impact
- Historical notes that conflict with current code and are not authoritative

## Pack Shape

- Facts: things visible in the artifacts
- Inferences: your interpretation
- Unknowns: what is still missing
- Suggested next reads: the next 2-5 artifacts if the current pack is not enough
