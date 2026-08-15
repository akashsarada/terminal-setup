---
inclusion: manual
---
# Delegation Adapter: Claude Code

Load only when delegating. Implements the abstract operations in `delegation/core.md`.

## Spawn primitive

The `Task` tool. Multiple Task calls in one assistant message run in parallel; each returns
when the worker finishes (effectively blocking per batch).

```
Task({ subagent_type: "worker-cheap", description: "Scan util modules",
       prompt: "[WORKER-BRIEF v1] tier=cheap\nGoal: ..." })
Task({ subagent_type: "worker-cheap", description: "Scan test modules",
       prompt: "[WORKER-BRIEF v1] tier=cheap\nGoal: ..." })
```

## Capability limits

| Capability | Status |
|---|---|
| Parallel fan-out | Yes — multiple Task calls in one message |
| Background / fire-and-forget | No for agents (background Bash exists, but not agent tasks) |
| Per-spawn model selection | Yes — via `model` in the custom agent's frontmatter (aliases `haiku`/`sonnet`/`opus`), chosen by `subagent_type` |
| Custom lightweight workers | Yes — `.claude/agents/<name>.md` (project) or `~/.claude/agents/<name>.md` (global): own short system prompt + `tools` allowlist. **This is the main cost lever** — a worker defined this way does NOT inherit the orchestrator's system prompt |
| Loops | Manual — re-dispatch on a failed review; no built-in loop construct |

## Tier → worker map (update here only)

| Tier | subagent_type | frontmatter |
|---|---|---|
| worker-cheap | `worker-cheap` | `model: haiku`, tools: Read, Grep, Glob |
| worker-standard | `worker-standard` | `model: sonnet`, tools: + Edit, Bash |
| reviewer | `reviewer` | `model: opus`, tools: Read, Grep, Glob, Bash |

Definitions live in `delegation/workers/claude-code/` — symlink or copy them into
`.claude/agents/` per project (or `~/.claude/agents/` once, globally).

## Context loading caveats

- CLAUDE.md is loaded by subagents too — keep the always-on delegation footprint to core.md
  only, and reference this adapter from CLAUDE.md by path rather than inlining it.
- Workers inherit MCP tool schemas available to the session; trim their `tools` list to
  suppress what they don't need.
