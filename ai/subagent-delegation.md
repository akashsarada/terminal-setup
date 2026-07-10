---
inclusion: always
---
# Subagent Delegation

Rules for spawning subagents (orchestrator) and rules for how subagents operate (subagents themselves).

Determine your role using the "Role Detection" section in [[orchestrator-agent]]. **Orchestrators:** read the full file. **Subagents:** skip to "Operating as a Subagent" below, ignore everything else.

---

## Operating as a Subagent

If you are a subagent (your task came from another agent, not a human):

1. **Execute your brief exactly** — do not expand scope, redesign the task, or second-guess the orchestrator's decomposition. If something seems wrong, flag it in your response instead of acting on assumptions.
2. **Do not delegate further** — never spawn your own subagents unless your brief explicitly says you may. You are the worker, not a coordinator.
3. **Return structured results** — your final message is data for the orchestrator, not prose for a human. Match the requested output format precisely.
4. **Keep output compact — you are writing into the orchestrator's context window** — your entire response is injected into the orchestrator's limited context, so verbosity directly consumes its budget. Return only what the brief asked for: conclusions plus the specific file paths, line numbers, or short snippets that back them. Do NOT paste full file contents, complete command output, long logs, or your step-by-step reasoning. Summarize findings and cite locations so the orchestrator can look closer if it needs to. If a large excerpt is unavoidable, trim it to the few relevant lines.
5. **Flag uncertainty explicitly** — if you couldn't verify something, say so clearly. Never fill gaps with plausible guesses.
6. **Report failure honestly** — if the task can't be completed as briefed (missing files, ambiguous instructions, access denied), state what blocked you and what partial results you found. A clear failure report is more useful than a padded partial answer.
7. **Stay within stated constraints** — "don't edit files", "search only this directory", and similar scope limits are literal, not suggestions.

---

## Orchestrator-Only: Delegation Mechanics

Everything below this line is for the orchestrator only.

## Model Tier Assignment

Pick the cheapest tier that handles the task without accuracy loss:

| Subagent task | Model | Effort | Rationale |
|---|---|---|---|
| File reading, search, listing, extraction | `haiku` | — | Shallow, well-specified, easy to validate |
| Classification, labeling, formatting | `haiku` | — | Constrained output space eliminates errors |
| Bulk repetitive edits (same pattern, many files) | `haiku` | — | Template-following, validate one then trust the rest |
| Summarization of a single file or section | `haiku` | — | Low reasoning required |
| Code generation (simple, well-specified) | `sonnet` | — | Needs some reasoning but not frontier |
| Multi-file investigation, bug hunting | `sonnet` | — | Needs to connect dots across files |
| Complex refactoring with judgment calls | `opus` | — | Architectural reasoning required |
| Security-sensitive code, correctness-critical logic | `opus` | — | Errors are expensive; don't cheap out |
| Independent code review or adversarial verification | `opus` | — | Needs the recall and precision of a top-tier model |

**Org constraint:** Sonnet 5 (`claude-sonnet-5`) is NOT available on this org. Anywhere you would use Sonnet 5, use `sonnet` (which resolves to the best available Sonnet, currently 4.6) or step up to `opus`.

## Writing Subagent Prompts

A subagent starts with zero context. Brief it like a smart colleague who just walked into the room:

1. **State the goal** — What are you trying to accomplish and why?
2. **Provide context** — What the subagent needs to know about the surrounding problem to make judgment calls.
3. **Specify inputs** — Exact file paths, line numbers, search terms, or data to work with.
4. **Define output format** — What you expect back (a list, a code block, a yes/no with reasoning, a structured object).
5. **Set scope boundaries** — What NOT to do (don't edit files, don't search outside this directory, report only confirmed issues).

### Prompt Template

```
Goal: [what to accomplish]
Context: [why this matters, what the surrounding task is]
Inputs: [file paths, search terms, specific data]
Expected output: [format and structure of the response]
Constraints: [what not to do, scope limits]
```

### Anti-Patterns in Prompts

- "Based on your findings, fix the bug" — pushes synthesis onto the subagent instead of doing it yourself
- "Look at the codebase and tell me what you find" — too open-ended, will burn tokens wandering
- Pasting the entire conversation history — brief on what matters, not everything
- "Do whatever you think is best" — the orchestrator decides, subagents execute

## Execution Patterns

### Parallel Fan-Out (default for independent work)

When you have 2+ independent tasks, spawn all subagents in a single message:

```
Agent({description: "Search for X", model: "haiku", prompt: "..."})
Agent({description: "Search for Y", model: "haiku", prompt: "..."})
Agent({description: "Search for Z", model: "haiku", prompt: "..."})
```

### Sequential Chain (when results feed forward)

When task B depends on task A's output, run A in the foreground (`run_in_background: false`), then use its result to formulate B's prompt.

### Fan-Out then Verify

For correctness-critical work:
1. Fan out cheap subagents (haiku/sonnet) to find candidates
2. Fan out verification subagents (opus) to confirm each candidate
3. Orchestrator synthesizes only verified results

## Handling Subagent Failures

- **Returns null or empty** — The subagent errored or was skipped. Re-dispatch with a clearer prompt or higher model tier.
- **Returns partial results** — Check if the scope was too broad. Split into smaller chunks and re-dispatch.
- **Returns clearly wrong information** — Do NOT attempt to fix it. Re-dispatch on a higher tier or investigate yourself.
- **Takes too long** — For background agents, wait for notification. Do not poll or sleep.

## Cost Awareness

Every subagent call has overhead (prompt construction, tool schema loading, response parsing). The break-even point:

- If the task takes < 5 seconds inline → do it yourself
- If the task is a single grep/read → do it yourself
- If you'd spawn only to get a one-line answer → do it yourself
- If the task involves reading 3+ files, searching broadly, or would block your reasoning while waiting → delegate

The goal is not maximum delegation — it's maximum value per token spent.
