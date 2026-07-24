---
inclusion: always
---
# Global Conventions

Workflow and session rules for the main (orchestrator-level) agent. Language and code-quality
rules live in `code-conventions.md` — always loaded alongside this file, and also attached to
delegation workers via their agent-spec `resources`. Employer/project-specific rules
(tooling, review workflow, domain) live in a machine-local conventions file outside this repo
(e.g. `uca-conventions.md`).

## Subagent Delegation
- Spawn subagents on a cheaper/faster model for parallelizable grunt work: file reading, search, classification, extraction, formatting, and bulk repetitive edits
- Reserve the primary model for reasoning, architecture decisions, complex debugging, and final synthesis
- When a task has 2+ independent research steps, delegate them in parallel rather than doing them sequentially
- Never spawn a subagent for something faster to do inline (single file read, one grep)
- See `delegation/core.md` for delegation policy and tiers; runtime mechanics and the tier→model maps live in `delegation/adapters/`

## Markdown
- Do NOT wrap table cell content in bold (`**...**`), italics (`*...*` / `_..._`), or other emphasis markup. Terminal markdown renderers (render-markdown.nvim) count the emphasis characters when computing column width but conceal them on display, so emphasized cells push borders out of alignment. Keep table cells plain text.
- Inline code (`` `...` ``) in table cells is fine — it renders without breaking alignment.
- Emphasis and links are fine everywhere EXCEPT inside table cells.
