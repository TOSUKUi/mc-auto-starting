# Operating Rules

Use these rules to keep `swarm-meeting` reliable and not unnecessarily noisy.

## Default Execution Mode

- Emulate roles locally by default.
- Keep role memos short and independent.
- Synthesize centrally in the main thread.

## When To Stay Local

Stay local when:
- the user asked for a normal design review
- the issue count is small enough to compare in one pass
- the meeting is mostly about tradeoffs, framing, or recommendation
- the environment does not clearly support parallel delegation

## When To Spawn Subagents

Spawn subagents only when at least one of these is true:
- the user explicitly asks for subagents, delegation, or parallel roles
- the user wants independent passes from clearly separated roles
- the meeting depends on multiple independent evidence-gathering tasks that can run in parallel

## When Not To Spawn Subagents

Do not spawn subagents when:
- the next step is blocked on a single local decision
- the topic is narrow enough for one coherent pass
- extra agent output would mostly duplicate the same reasoning
- the overhead of integration is likely larger than the value of parallelism

## Suggested Subagent Mapping

- `moderator`: keep local
- `skeptic`: may delegate if the user explicitly wants independent review
- `pragmatist`: may delegate for implementation-scope checks
- `retrieval-architect`: may delegate if there is a distinct code or docs slice to inspect
- `granary-workflow-lead`: may delegate if workflow artifacts are separate from retrieval artifacts

## Integration Rules

- Ask each delegated role for a short memo, not a free-form debate.
- Merge conclusions in the main thread.
- Resolve conflicts explicitly in synthesis.
- Do not paste raw subagent transcripts into the final answer.

## Ambiguous Input Rule

If the user invokes `swarm-meeting` vaguely:
- show a short assist block
- assume `balanced` unless there is a clear reason not to
- assume `options, objections, and recommendation` unless a different need is obvious
- continue with one reasonable assumption instead of stalling
