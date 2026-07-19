---
inclusion: manual
---
# Delegation Adapter: kiro-cli

Load only when delegating. Implements the abstract operations in `delegation/core.md`.

## Spawn primitive

The `subagent` tool. One call takes a DAG of stages; stages with no `depends_on` run in
parallel. **Blocking only** — background mode is not implemented, so you wait for the whole
DAG. Plan a single fan-out per call rather than incremental spawning.

```
subagent({
  task: "<overall task>",
  mode: "blocking",
  stages: [
    { name: "scan-a", role: "worker-cheap",
      prompt_template: "[WORKER-BRIEF v1] tier=cheap\nGoal: ..." },
    { name: "scan-b", role: "worker-cheap",
      prompt_template: "[WORKER-BRIEF v1] tier=cheap\nGoal: ..." },
    { name: "verify", role: "reviewer",
      depends_on: ["scan-a", "scan-b"],
      prompt_template: "[WORKER-BRIEF v1] tier=reviewer\nGoal: ..." }
  ]
})
```

## Capability limits

| Capability | Status |
|---|---|
| Parallel fan-out | Yes — independent stages in one call |
| Background / fire-and-forget | **No** (schema says "not yet implemented") |
| Per-spawn model selection | Yes — pinned per tier in the worker agent specs; the per-stage `model` param is an override only. (Unpinned agents silently run on the session default — Opus at 2.2x.) |
| Custom lightweight workers | Yes — AIM agent specs (see below). Without one, `role` must be an installed agent (`kiro_default`, `amzn-builder`, ...) which loads the FULL steering stack per spawn (~30–50K token prefix) |
| Loops | Yes — `loop_to` with trigger text + max_iterations (review→fix cycles) |

## Tier → agent map (models pinned in the agent specs — update there)

| Tier | `role` | Pinned model | Credit rate |
|---|---|---|---|
| worker-cheap | `worker-cheap` | `claude-haiku-4.5` | 0.4 |
| worker-cheap (internal web/code search) | `worker-research` | `claude-haiku-4.5` | 0.4 |
| worker-standard | `worker-standard` | `claude-sonnet-4.6` | 1.3 |
| reviewer | `reviewer` | `claude-opus-4.8` | 2.2 |

Only `worker-research` carries MCP tools — builder-mcp filtered to `ReadInternalWebsites`,
`InternalCodeSearch`, `InternalSearch` via `--include-tools`, so it loads 3 tool schemas
instead of the full catalog. Use it for wiki/docs reading and cross-Amazon code search
briefs; the other workers are local-file only and will (correctly) report themselves
blocked on such tasks.

Selecting the tier = selecting the `role`; the model rides along automatically, so a
forgotten `model` param can no longer silently run on the session default (Opus). Pass
`model` per stage only to deliberately override a pin (e.g. `claude-fable-5` for a
high-stakes review — never on customer data/PII/ITAR).

Discover live IDs: `kiro-cli chat --list-models --format json`.

## Minimal worker agents

The economics only work with lean workers. The four tier specs live in
`delegation/workers/kiro/agents/`; install with
`aim agents install --local <...>/delegation/workers/kiro`. Each carries a ~1K-token system
prompt, its pinned model, minimal tools, and none of the org steering (smoke-tested: a
one-file brief on `worker-cheap` costs ~0.03 credits vs 2.12 on an unpinned default-model agent).
If they are not installed, fall back to `kiro_default` with an explicit `model` per stage,
accept the ~30–50K-token prefix cost, and raise the delegation threshold accordingly.
