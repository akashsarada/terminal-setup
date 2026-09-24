---
inclusion: always
trigger: always_on
---
# Global Conventions

Workflow and session rules for the main (orchestrator-level) agent. Language and code-quality
rules live in `code-conventions.md` — always loaded alongside this file, and also attached to
delegation workers via their agent-spec `resources`. Employer/project-specific rules
(tooling, review workflow, domain) live in a machine-local conventions file outside this repo
(e.g. `uca-conventions.md`).

## Communication & Output Style
- **No preamble or filler:** Start directly with the answer, command, code, or action. Skip conversational pleasantries ("Sure, I can help with that", "Let's think about this").
- **Lead with the action:** Put actionable commands, file links, and key conclusions first; background explanations come after, if at all.
- **Suppress tangents:** Focus strictly on the user's objective. Do not append unsolicited advice, style commentary, or unrelated findings; if a secondary issue is critical, surface it in one concise note at the end.
- **Numbered, bounded steps:** Use concise, numbered lists for multi-step workflows (one action per step).
- **Crisp completion state:** State clearly what was done, which files changed, and the single immediate next action if anything remains open.

## Git Commits
- Always use **Conventional Commits** format (`type(scope): description`). You must use the following:
  - `feat`: new feature or capability
  - `fix`: bug fix
  - `refactor`: code restructuring with no behavior change
  - `chore`: maintenance, build, config, or dependency update
  - `docs`: documentation changes only
  - `test`: adding or fixing tests
- Keep commit descriptions concise, imperative (e.g. `feat: add X`, not `feat: added X`), and lowercase without trailing punctuation.

## Task Execution & Subagent Routing

The orchestrator chooses between three execution modes based on task scope and requirements:

Mode | Trigger | Strategy
:--- | :--- | :---
Inline Execution | < 2 files, minor bug fixes, questions, localized refactors. | Work inline in the main chat session. Lowest latency.
Ad-Hoc Delegation | Bulk log parsing, broad repo search, 1-shot parallel subtasks across modules. | Apply `delegation-core` (`ai/delegation/core.md`). Spawn `worker-cheap` or `worker-standard` with `[WORKER-BRIEF v1]`.
Digital Team Pipeline | New feature requests, complex multi-component changes, strict TDD requirements. | Apply `digital-team` (`ai/digital-team/workflow.md`). 5-step pipeline: Feature Plan → Plan Challenge → Decoupled TDD (Test & Impl Workers) → Code Reviewer → Dual Loops.

- Shared tier worker definitions live in `ai/agents/`.
- Runtime mechanics and tier→model mappings live in `delegation/adapters/`.

## Asynchronous Tasks & Background Execution
- **Reactive Wakeup (Never Poll):** Background processes, subagents (`invoke_subagent`), and async commands automatically send notifications to the orchestrator upon completion.
- You MUST NOT poll or loop on task status (e.g. repeated `status` checks or `sleep` loops). Once an asynchronous command or subagent is dispatched, simply stop calling tools — the system automatically resumes execution when results are ready.

## Markdown
- Do NOT wrap table cell content in bold (`**...**`), italics (`*...*` / `_..._`), or other emphasis markup. Terminal markdown renderers (render-markdown.nvim) count the emphasis characters when computing column width but conceal them on display, so emphasized cells push borders out of alignment. Keep table cells plain text.
- Inline code (`` `...` ``) in table cells is fine — it renders without breaking alignment.
- Emphasis and links are fine everywhere EXCEPT inside table cells.

## Working With Files
- **Use Dedicated Read & Edit Tools:** Agents have first-class tools for file inspection and modification (`view_file`, `replace_file_content`, `write_to_file` / `read`, `edit`, `write`). Do NOT rely on shell commands like `cat`, `head`, `grep`, `sed`, `awk`, or heredocs (`cat << 'EOF' > file`) to read or edit files when dedicated tools exist. Reserve terminal/shell commands strictly for running builds, test suites, git commands, and process management.
- Re-read files fresh from disk before acting on them — never rely on a cached/prior version. External processes may have modified them since the last read.
- Don't commit build artifacts or machine-local absolute paths (e.g. `/Volumes/workplace/...`, `/home/<user>/...`).
