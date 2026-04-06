# Evaluation Checklist

## Scope

- Does the change satisfy the `done_definition`?
- Were any non-goals or invariants violated?

## Code Risk

- Is there an obvious regression path?
- Are edge cases or failure paths unhandled?
- Did the checks actually cover the changed behavior?

## Documentation And Restart Risk

- Do touched docs still match the code?
- Do task status and restart notes need updates?
- Did the change alter critical-path assumptions or follow-up tasks?

## Decision Guidance

- `pass`: requirements met and no material drift
- `partial`: usable result but write-back or follow-up work is still required
- `fail`: blocking defect, unmet requirement, or major drift
