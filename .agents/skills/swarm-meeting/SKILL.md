---
name: swarm-meeting
description: Run structured multi-role design reviews and architecture debates for technical decisions. Use when Codex needs to compare options, pressure-test tradeoffs, recommend an MVP path, or simulate a meeting with distinct evaluation roles such as moderator, skeptic, pragmatist, minimalist, maximalist, retrieval architect, Granary workflow lead, semantic purist, lightweight contrarian, context economist, or workflow conservative.
---

Use this skill to turn a vague "let's discuss" request into a bounded decision meeting.

## Inputs

Provide:
- topic
- need
- profile name
- optional artifacts, constraints, decision owner, and timebox

If the request spans many files or docs, prepare a brief pack first with `swarm-research-pack` or by reading the smallest relevant local artifacts directly.

## Ambiguous Input Assist

When the user asks for a meeting without enough structure, do not stop immediately. Convert the vague request into a short guided start.

1. Infer `balanced` as the default profile unless the user clearly asks for stronger conflict or a deeper architecture review.
2. Infer a default `need` of `options, objections, and recommendation` when the user does not specify one.
3. Rephrase the likely topic from the active conversation or nearest artifact.
4. Show a short kickoff block before the meeting if key inputs are missing.

Use a compact pattern like this:

```markdown
I can run this as a `balanced` swarm meeting.

- Topic: <inferred topic or "please provide one sentence">
- Need: options, objections, and recommendation
- Other profiles: `architecture-debate`, `extreme-diversity`

Examples:
- `Use the swarm-meeting skill. Topic: ... Need: ...`
- `Use swarm-meeting with profile: architecture-debate ...`
```

Keep this assist block short. Do not turn it into a questionnaire unless the missing information would materially change the outcome.

## Workflow

1. Load exactly one profile from `profiles/`.
2. Load only the role prompts needed for that profile from `prompts/`.
3. Rephrase the decision in 1-2 sentences and define the agenda.
4. Collect independent role memos before synthesis. Keep each memo short: 3-7 bullets or short paragraphs.
5. Run the objection round if the profile requires it.
6. Force a recommendation, open questions, and concrete next actions.
7. Separate facts from inferences. Mark assumptions explicitly.

## Guardrails

- Treat roles as evaluation biases, not personalities.
- Keep `max_agents` between 4 and 6 unless the user explicitly asks for a larger meeting.
- Prefer local role emulation by default. Only spawn subagents when the user explicitly asks for delegation or parallel agents, or when the environment clearly allows it.
- Do not let any single role dominate the summary.
- Avoid unbounded brainstorming. End with a decision or a clearly framed fork.
- If the user input is underspecified, provide the short assist block above, make one reasonable default assumption, and continue.

## Output Contract

Use this section order unless the user asks for a different format:

```markdown
# Design Review
## Problem Statement
## Agenda
## Role Memos
## Options Considered
## Recommended Architecture
## MVP Plan
## Risks and Failure Modes
## Open Questions
## Concrete Next Actions
```

## Resources

- `profiles/balanced.yaml`: default 5-role review for most implementation decisions.
- `profiles/architecture-debate.yaml`: stronger architecture pressure with semantics and platform concerns.
- `profiles/extreme-diversity.yaml`: intentionally conflicting evaluation axes for high-stakes tradeoffs.
- `prompts/*.md`: short role cards. Load only selected roles.
- `references/prompt-examples.md`: ready-to-copy invocation examples for common meeting intents.
- `references/operating-rules.md`: explicit rules for when to stay local versus when to spawn subagents.
- `references/task-scoped-context-review.md`: migrated example from the original one-off prompt.
- `scripts/select_profile.py`: recommend or inspect a profile without external dependencies.
- `scripts/render_meeting_context.py`: render a meeting brief from a profile plus topic, need, and artifacts.

## Role Selection Rules

- Always include `moderator`.
- Include `skeptic` unless the user explicitly wants a fast, low-friction pass.
- Prefer `pragmatist` when delivery pressure is real.
- Prefer `minimalist` for MVP, operational simplicity, or "ship this week".
- Prefer `maximalist` for platform or long-horizon design.
- Prefer `retrieval-architect` when the topic involves search, indexing, code selection, Tree-sitter, LSP, or semantics.
- Prefer `granary-workflow-lead` when the topic involves task hubs, handoff, checkpointing, CLI flow, or session lifecycle.
- Prefer `semantic-purist` when correctness depends on type, symbol, or compiler information.
- Prefer `lightweight-contrarian` when a simple `rg`/diff/docs index may beat a heavy platform.
- Prefer `context-economist` when token budget, context pollution, or fresh-session strategy matters.
- Prefer `workflow-conservative` when tool sprawl is the main risk.
