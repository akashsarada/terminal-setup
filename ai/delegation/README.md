# Delegation (portable orchestrator/worker policy)

Replaces `orchestrator-agent.md`, `subagent-delegation.md`, and the delegation portions of
`claude-model-selection-guide.md` with a policy/adapter split that works across kiro-cli,
Claude Code, and Google Antigravity.

```
delegation/
├── core.md                    # runtime-agnostic policy — the ONLY always-loaded file
├── adapters/                  # load on demand, one per runtime
│   ├── kiro.md                # subagent DAG tool, per-stage model IDs, worker agent
│   ├── claude-code.md         # Task tool, .claude/agents/* workers
│   └── antigravity.md         # invoke_subagent / define_subagent, model tiers (flash_lite, flash, pro)
└── workers/                   # minimal worker definitions (the main cost lever)
    ├── antigravity/{worker-cheap,worker-standard,reviewer}.json
    ├── kiro/agents/*.agent-spec.json        # AIM requires the agents/ subdirectory
    ├── claude-code/{worker-cheap,worker-standard,reviewer}.md
    └── skill/SKILL.md         # open Agent Skills standard — shared by all runtimes
```

## Design principles

1. **Policy vs mechanics.** `core.md` names no tools and no model IDs — only abstract tiers
   (`cheap`/`standard`/`reviewer`) and operations. Each adapter maps those to its runtime and
   declares what the runtime *cannot* do. New model ships → edit one adapter table.
2. **Deterministic role detection.** Every brief starts with `[WORKER-BRIEF v1]`. No
   prompt-shape guessing.
3. **Context isolation is the real cost lever**, not model arbitrage. Hence the working-set
   delegation threshold, per-brief batching, hard output caps, and one delegation level.
4. **Lean workers.** Spawning a full default persona costs a 30–50K-token steering prefix per
   spawn; the worker definitions here carry ~1–2K. Install them before expecting savings.

## Install

**kiro-cli** — steering is wired by per-file symlinks in `~/.kiro/steering/`, so new files
never auto-load. Link core.md (already done on this box) and remove the old delegation
symlinks:

```
ln -sf ~/terminal-setup/ai/delegation/core.md ~/.kiro/steering/delegation-core.md
rm -f ~/.kiro/steering/orchestrator-agent.md ~/.kiro/steering/subagent-delegation.md
```

Install the four tier agents (`worker-cheap`→haiku, `worker-research`→haiku + builder-mcp filtered
to 3 internal-search tools, `worker-standard`→sonnet, `reviewer`→opus; models pinned in each
spec):

```
aim agents install --local ~/terminal-setup/ai/delegation/workers/kiro
```

(AIM scans the path for an `agents/` directory — pointing it at a directory without one fails
with "No AI capabilities components found".) Verify with
`kiro-cli chat --agent worker-cheap --non-interactive "<brief>"`. Load `adapters/kiro.md` only in
sessions that delegate.

**Claude Code** — reference `core.md` from CLAUDE.md (short pointer, not inline). Copy
`workers/claude-code/*.md` into `~/.claude/agents/` (global) or `.claude/agents/` (project).

**Antigravity** — copy `workers/skill/` to `~/.gemini/config/skills/delegation-core/`
(or `<project>/.agents/skills/delegation-core/`). Add one rule line to `GEMINI.md` or `.agents/rules/`:
"When decomposing tasks into subagents or delegating multi-file work, apply the delegation-core skill."
See `adapters/antigravity.md` for `invoke_subagent` and model tier mapping (`flash_lite`, `flash`, `pro`).

## Migration notes

- The old files' `Agent({...})` syntax, background-agent guidance, and API-only cost levers
  (`effort`, `cache_control`, Batch API) matched no runtime here and were dropped.
- The model catalog table survives only as the per-adapter tier maps; org caveats (Fable is
  dev-only — no customer data/PII/ITAR) live in `adapters/kiro.md`.
- The "delegate if 2+ research steps" trigger was replaced by the working-set rule — small
  tasks are cheaper inline once per-spawn overhead is priced in.
