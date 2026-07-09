---
inclusion: always
---
# Claude Model Selection Guide

Which Claude model to use for each type of task, optimizing token spend without sacrificing accuracy. Pricing and capabilities current as of July 2026.

## Current Models at a Glance

| Model | Model ID | Context | Max Output | Input $/1M | Output $/1M | Tier |
|---|---|---|---|---|---|---|
| Claude Fable 5 | `claude-fable-5` | 1M | 128K | $10.00 | $50.00 | Frontier |
| Claude Opus 4.8 | `claude-opus-4-8` | 1M | 128K | $5.00 | $25.00 | High capability |
| Claude Opus 4.7 | `claude-opus-4-7` | 1M | 128K | $5.00 | $25.00 | High capability (prev-gen) |
| Claude Sonnet 5 | `claude-sonnet-5` | 1M | 128K | $3.00 (intro $2.00 through 2026-08-31) | $15.00 (intro $10.00) | Balanced |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | 1M | 128K | $3.00 | $15.00 | Balanced (prev-gen) |
| Claude Haiku 4.5 | `claude-haiku-4-5` | 200K | 64K | $1.00 | $5.00 | Fast / cheap |

Rule of thumb: **Haiku is 5x cheaper than Opus and 10x cheaper on output than Fable.** Every task routed down a tier without an accuracy loss is direct savings — but a wrong answer that needs a retry or human correction costs more than the model upgrade would have.

## Best Model by Task Type

### Route to Haiku 4.5 (fastest, cheapest)

Accuracy is not at risk on these because the tasks are shallow, well-specified, and easy to validate:

| Task | Notes |
|---|---|
| Classification / labeling | Constrain output with strict tool use or structured outputs; set `max_tokens` ~256 |
| Simple extraction (fields from short docs) | Use `output_config.format` with a JSON schema to guarantee parseable output |
| Routing / intent detection | Pair with enum-constrained schemas |
| Autocomplete, short rewrites, formatting | Latency-sensitive interactive features |
| High-volume moderation / filtering | Combine with the Batch API for 50% off |
| Subagent grunt work | Cheap parallel workers inside a larger agent pipeline |

### Route to Sonnet 5 (default workhorse)

Near-Opus quality on coding and agentic work at 60% of the input price. This should be the **default choice for most production workloads**:

| Task | Notes |
|---|---|
| Everyday coding (features, fixes, refactors) | `effort: "high"` default; `xhigh` for the hardest tasks |
| Summarization of long documents | 1M context; cache the document prefix if queried repeatedly |
| RAG / retrieval-augmented Q&A | Strong grounding; use citations for verifiability |
| Standard agentic loops and tool use | More tool-eager than 4.6 by default |
| Data analysis and report generation | Pair with the code execution server tool |
| Chat / conversational products | `effort: "medium"` or `"low"` for latency-sensitive chat |
| Content generation | Instruction-following is very literal — precise prompts pay off |

Note: Sonnet 5's tokenizer produces ~30% more tokens than Sonnet 4.6 for the same text — re-baseline budgets with `count_tokens` rather than reusing old numbers.

### Route to Opus 4.8 (hard problems, autonomy)

| Task | Notes |
|---|---|
| Long-horizon autonomous coding (multi-hour runs, large migrations) | State-of-the-art; give the full spec up front in one turn |
| Complex architecture and design decisions | `effort: "high"` or `"xhigh"` |
| Code review / bug hunting | Better recall and precision than any Sonnet; tell it to report everything and filter downstream |
| Knowledge work deliverables (docx/pptx/xlsx, financial analysis) | Visually verifies its own output |
| Vision-heavy work (screenshots, dense documents, computer use) | High-res support up to 2576px; 1080p screenshots balance cost/accuracy |
| Multi-agent orchestration (as the coordinator) | Use cheaper models for the subagents |
| Latency-critical high-quality output | Fast mode (`speed: "fast"`, beta) — up to 2.5x output speed at premium pricing |

### Route to Fable 5 (frontier — only when explicitly justified)

At $10/$50 per MTok, use only where Opus 4.8 demonstrably falls short:

| Task | Notes |
|---|---|
| Hardest unsolved reasoning problems | Start with your hardest problems, not routine ones |
| Longest-horizon agentic work (overnight runs, first-shot builds of well-specified systems) | Turns can run many minutes — plan streaming and async check-ins |
| Deep research and end-to-end enterprise deliverables | Excellent parallel subagent delegation |

Caveats: thinking is always on (omit the `thinking` param), safety classifiers can return `stop_reason: "refusal"` (ship a fallback to `claude-opus-4-8` via the server-side `fallbacks` beta), and it requires 30-day data retention. Not the default Opus upgrade path — routine work is cheaper *and* often faster on Opus 4.8.

## Token Optimization (without losing accuracy)

These levers cut spend; ordered by typical impact:

### 1. Prompt caching (~90% off repeated context)
Cache reads cost ~0.1x the input price. Put stable content (system prompt, tools, reference docs) first and mark it with `cache_control: {"type": "ephemeral"}`; keep volatile content (timestamps, per-request IDs) after the last breakpoint. Verify with `usage.cache_read_input_tokens` — zero across repeated requests means a silent invalidator (e.g. a timestamp in the system prompt).

### 2. Batch API (50% off everything)
Any non-latency-sensitive workload — evals, backfills, bulk classification, nightly reports — should go through `POST /v1/messages/batches`. All features supported; most batches finish within an hour.

### 3. Effort parameter (right-size the thinking)
`output_config: {"effort": ...}` controls thinking depth and total token spend on current models:

| Effort | Use for |
|---|---|
| `low` | Subagents, chat, simple lookups — fewer/consolidated tool calls, terse output |
| `medium` | Cost-sensitive routes; Sonnet 5 at `medium` ≈ Sonnet 4.6 at `high` |
| `high` | Default — the sweet spot balancing quality and token efficiency |
| `xhigh` | Hardest coding and agentic work (Claude Code's default) |
| `max` | Correctness matters more than cost; watch for overthinking on routine tasks |

Sweep effort levels on your own evals rather than defaulting to the top — higher effort up front sometimes *reduces* total cost on agentic work by cutting turn count, while `medium` matches `high` on many routes at lower latency.

### 4. Model routing (tier per request, not per app)
Don't pick one model for a whole application. Classify requests cheaply (Haiku can be the router) and send each to the lowest tier that handles it reliably. Keep one model per conversation, though — switching models mid-session invalidates the prompt cache; spawn a subagent on the cheaper model instead.

### 5. Structured outputs instead of retries
Malformed output that forces a retry doubles cost. `output_config.format` with a JSON schema (or `strict: true` on tools) guarantees valid, parseable output on the first attempt — this is a cost lever as much as a correctness one.

### 6. Task budgets for agentic loops (beta)
On Fable 5 / Sonnet 5 / Opus 4.8 / 4.7, `output_config.task_budget` (beta `task-budgets-2026-03-13`, min 20K tokens) gives the model a visible countdown so it paces itself and finishes gracefully instead of burning tokens then getting cut off.

### 7. Context hygiene
- Right-size `max_tokens`: ~256 for classification, ~16K non-streaming default, ~64K streaming.
- For long agent runs, use context editing (clear stale tool results) and compaction (server-side summarization) instead of resending an ever-growing transcript.
- Count tokens with `count_tokens` (never tiktoken — it undercounts Claude tokens by 15–20%+).

## Accuracy Guardrails When Downgrading

Before routing a task to a cheaper model, make failure detectable:

1. **Constrain the output** — structured outputs and enum schemas eliminate whole classes of small-model errors.
2. **Eval before switching** — run a representative sample on both tiers and compare; match by observed quality, not vibes.
3. **Escalate on low confidence** — have the cheap model flag uncertainty, and re-run flagged items on the higher tier. A 95/5 Haiku/Opus split is far cheaper than 100% Sonnet.
4. **Verify with a second pass** — for agent pipelines, a cheap verification agent (or a higher-tier judge on a sample) catches regressions early.
5. **Never blind-downgrade correctness-critical paths** — financial calculations, legal/compliance output, destructive actions, and security-sensitive code stay on Opus-tier or above.

## Quick Decision Table

| If the task is... | Use | Effort |
|---|---|---|
| Classify / route / extract short fields | Haiku 4.5 | — |
| High-volume, not time-sensitive | Haiku or Sonnet + **Batch API** | `low`–`medium` |
| Everyday coding, summarization, RAG, chat | Sonnet 5 | `high` (chat: `low`/`medium`) |
| Hardest coding, autonomous agents, code review, vision | Opus 4.8 | `high`–`xhigh` |
| Frontier reasoning, overnight autonomous runs | Fable 5 | `high`–`xhigh` |
| Anything with repeated context | Same model + **prompt caching** | — |
