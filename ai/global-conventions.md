---
inclusion: always
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

## Subagent Delegation
- See `delegation/core.md` for orchestrator/worker delegation rules, triggers, and tier taxonomy.
- Runtime mechanics and tier→model mappings live in `delegation/adapters/`.

## Markdown
- Do NOT wrap table cell content in bold (`**...**`), italics (`*...*` / `_..._`), or other emphasis markup. Terminal markdown renderers (render-markdown.nvim) count the emphasis characters when computing column width but conceal them on display, so emphasized cells push borders out of alignment. Keep table cells plain text.
- Inline code (`` `...` ``) in table cells is fine — it renders without breaking alignment.
- Emphasis and links are fine everywhere EXCEPT inside table cells.

## Working With Files
- Re-read files fresh from disk before acting on them — never rely on a cached/prior version. External processes may have modified them since the last read.
- Don't commit build artifacts or machine-local absolute paths (e.g. `/Volumes/workplace/...`, `/home/<user>/...`).
