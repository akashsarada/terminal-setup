---
inclusion: manual
---
# Delegation Adapter: Google Antigravity CLI (`agy`)

Load only when delegating. Implements the abstract operations in `delegation/core.md`.
Based on Antigravity 2.0 CLI (shipped May 2026, successor to Gemini CLI). Verify against
current docs — the platform is moving fast and this adapter predates stable documentation.

## Spawn primitive

**Dynamic subagents, orchestrator-defined.** There is no user-facing spawn tool: the native
orchestrator reads a high-level goal, decides the decomposition itself, and spawns subagents
with isolated context windows, running independent ones in parallel. You influence delegation
through the prompt and through Rules/Skills — not through a tool schema.

```
/goal <task>. Decompose into parallel subagents per the delegation-core skill:
one brief per bundle of related inputs, each returning a capped structured summary.
```

`/goal` runs to completion without approval pauses; omit it to approve each step.
`/grill-me` makes it ask clarifying questions before decomposing. Long-running work can go
async (Async Task Management) or on a cron via `/schedule`.

## Capability limits

| Capability | Status |
|---|---|
| Parallel fan-out | Yes — native, decided by the orchestrator |
| Background / fire-and-forget | Yes — async tasks (the only one of our three runtimes with real background) |
| Per-spawn model selection | **No** — model choice (Gemini 3.x / Claude / GPT-OSS) is session-level via the model selector; subagents aren't individually pinnable. Tiering by model is unavailable; don't pretend otherwise |
| Custom lightweight workers | Indirect — you can't define worker agents, but subagents get fresh isolated contexts by design, so the per-spawn steering-stack problem largely doesn't apply |
| Loops | No explicit construct — instruct iteration in the goal, or leave Artifact feedback |

## Mapping core.md onto Antigravity

- **Role detection:** the sentinel still works — instruct the orchestrator (via the skill
  below) to prepend `[WORKER-BRIEF v1]` to every subagent brief, so worker rules bind even
  though you didn't spawn the worker yourself.
- **Tiers:** collapse to session-level strategy — run the session on a strong model for
  planning-heavy tasks; the default (Gemini 3.5 Flash High) is already the cheap tier.
  The cost lever here is context isolation + output caps, not model arbitrage.
- **Working-set rule / batching / output caps:** enforce via the skill; the native
  orchestrator otherwise decomposes however it likes.

## Installation

Antigravity uses the open Agent Skills standard (same SKILL.md format as Claude Code), plus
always-on Rules:

| Layer | Path | Use for |
|---|---|---|
| Rules (always-on) | `~/.gemini/GEMINI.md` (global) or `.agent/rules/` (workspace) | 2–3 lines: "when decomposing into subagents, apply the delegation-core skill" |
| Skill (on-demand) | `~/.gemini/antigravity/skills/delegation-core/SKILL.md` or `<project>/.agent/skills/` | the full core.md content, wrapped in SKILL.md frontmatter |
| Workflows (user-triggered) | `.agent/workflows/fan-out.md` | optional `/fan-out` command embedding the brief template |

Because Skills are an open standard, `delegation/workers/skill/SKILL.md` (a SKILL-wrapped
copy of core.md) is shared verbatim between Antigravity and Claude Code.
