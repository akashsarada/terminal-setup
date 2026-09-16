---
inclusion: manual
---
# Delegation Adapter: Google Antigravity (`agy`)

Load only when delegating. Implements the abstract operations in `delegation/core.md` for
Antigravity (AGY CLI & Antigravity IDE).

## Spawn primitive

The `invoke_subagent` tool. Multiple subagents in the `Subagents` array run in parallel.
Execution is asynchronous; the orchestrator automatically resumes upon completion (do NOT poll).

```json
invoke_subagent({
  "Subagents": [
    {
      "TypeName": "worker-cheap",
      "Role": "Search Worker",
      "Workspace": "inherit",
      "Prompt": "[WORKER-BRIEF v1] tier=cheap\nGoal: ...\nInputs: ...\nExpected output: ..."
    },
    {
      "TypeName": "worker-standard",
      "Role": "Code Implementer",
      "Workspace": "inherit",
      "Prompt": "[WORKER-BRIEF v1] tier=standard\nGoal: ...\nInputs: ...\nExpected output: ..."
    }
  ]
})
```

## Capability limits

| Capability | Status |
|---|---|
| Parallel fan-out | Yes — multiple subagents in one `invoke_subagent` call |
| Background / async execution | Yes — native non-blocking execution with reactive resume |
| Per-spawn model selection | Yes — via `Model` (`flash_lite`, `flash`, `pro`, `inherit`) |
| Custom lightweight workers | Yes — definitions in `ai/agents/antigravity/` or built-in `research`/`self` |
| Workspace isolation | Yes — `Workspace: "inherit" | "branch" | "share"` |
| Loops | Re-dispatch with tighter brief on failed verification (cap at 3 cycles) |

## Tier → worker map

| Tier | `TypeName` | `Model` | Available Tools | Best For |
|---|---|---|---|---|
| worker-cheap | `worker-cheap` | `flash_lite` | Read-only (`view_file`, `grep_search`, `list_dir`, `search_web`, `read_url_content`) | Search, file reads, log extraction |
| challenger | `challenger` | `flash` | Read-only (`view_file`, `grep_search`, `list_dir`) | Adversarial challenge, plan & design stress-testing |
| worker-standard | `worker-standard` | `flash` | Read + Write (`view_file`, `replace_file_content`, `write_to_file`, `run_command`) | Code edits, bug fixes, unit tests |
| reviewer | `reviewer` | `pro` | Read + Command runner | Diff audit, running tests/builds |
| teacher | `teacher` | `pro` | Read-only (`view_file`, `grep_search`, `list_dir`, `search_web`, `read_url_content`) | Socratic teaching, concept abstraction, verified learning references |

Definitions live in `ai/agents/antigravity/`.

