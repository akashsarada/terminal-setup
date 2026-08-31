# Global Instructions & Conventions

## Communication & Output Style
- **No preamble or filler:** Start directly with the answer, command, code, or action. Skip conversational pleasantries ("Sure, I can help with that", "Let's think about this").
- **Lead with the action:** Put actionable commands, file links, and key conclusions first; background explanations come after, if at all.
- **Suppress tangents:** Focus strictly on the user's objective. Do not append unsolicited advice or style commentary; if a secondary issue is critical, surface it in one concise note at the end.
- **Numbered, bounded steps:** Use concise, numbered lists for multi-step workflows (one action per step).
- **Crisp completion state:** State clearly what was done, which files changed, and the single immediate next action if anything remains open.

## Tool Usage & File Operations
- **Use Dedicated Read & Edit Tools:** Always use first-class tools (`view_file`, `replace_file_content`, `write_to_file`). Do NOT rely on shell commands like `cat`, `head`, `grep`, `sed`, `awk`, or heredocs (`cat << 'EOF' > file`) to inspect or modify files. Reserve terminal commands strictly for builds, tests, git, and process management.
- **Re-read files fresh from disk:** Before acting on a file, verify its latest content—never rely on a cached or presumed version.
- **No absolute/machine paths:** Never hardcode machine-local absolute paths (e.g. `/home/<user>/...`) into project code or commits.

## Asynchronous Tasks & Background Execution
- **Reactive Wakeup (Never Poll):** Background tasks, subagents (`invoke_subagent`), and async commands automatically notify you upon completion.
- **Do NOT poll or loop on status:** Never execute repeated `status` checks or `sleep` loops. Once an async command or subagent is launched, simply stop calling tools to wait for the automatic notification.

## Git Commits
- Always use **Conventional Commits** format (`type(scope): description`):
  - `feat`: new feature or capability
  - `fix`: bug fix
  - `refactor`: code restructuring with no behavior change
  - `chore`: maintenance, build, config, or dependency update
  - `docs`: documentation changes only
  - `test`: adding or fixing tests
- Keep commit descriptions concise, imperative (`feat: add X`, not `feat: added X`), and lowercase without trailing punctuation.

## Markdown Rendering
- Do NOT wrap table cell content in bold (`**...**`), italics (`*...*` / `_..._`), or other emphasis markup (render-markdown.nvim calculates column widths based on raw characters, breaking alignment).
- Inline code (`` `...` ``) in table cells is allowed.

## Task Execution & Subagent Routing
Choose between three execution modes based on task scope:
| Mode | Trigger | Strategy |
| :--- | :--- | :--- |
| Inline Execution | < 2 files, minor bug fixes, questions, localized refactors | Work directly in the main session. |
| Ad-Hoc Delegation | Bulk log parsing, broad repo search, 1-shot parallel subtasks | Use `delegation-core` skill; delegate to `worker-cheap` or `worker-standard`. |
| Digital Team Pipeline | New feature requests, complex multi-component changes, strict TDD | Use `digital-team` skill; pipeline with `challenger`, `worker-standard`, and `reviewer`. |

---

## Universal Code Quality & Comments
- **Comments Policy (CRITICAL):**
  - Do NOT add comments describing what code does—variable names and structure must convey intent.
  - Do NOT add comments within methods or narrate implementation steps (e.g. `// Fetch data`, `// Return result`).
  - Inline comments are ONLY allowed for a brief "why" (1-2 lines max) when rationale is non-obvious.
  - TSDoc / docstrings must be concise (at most 2 lines: one for purpose, one for non-obvious constraints).
- **Performance:** Watch for O(n²) bottlenecks, verify caching opportunities, and prevent memory leaks.
- **Testing:** Only mock boundaries (APIs, services), never library internals.

---

## TypeScript & React Conventions
- **File Extensions:**
  - `.tsx`: Files rendering JSX (components, pages, modals).
  - `.ts`: Pure TypeScript (helpers, utilities, transformers, types, constants).
  - Custom hooks (`use*.ts`) must be `.ts`, not `.tsx`, unless they render JSX.
  - Standalone utility functions must stay in `.ts` modules, never inside `.tsx`.
  - Test files: `*.test.tsx` for components, `*.test.ts` for utilities.
- **Component & Function Style:**
  - File names in `kebab-case`, components in `PascalCase`.
  - Define components with the `function` keyword (not arrow functions).
  - Explicit typing: Avoid `any`. Always add explicit return types to functions.
  - Avoid inline functions in JSX props unless trivial; use `useCallback` / `useMemo` appropriately.
  - Keep components under ~500 lines; extract subcomponents, hooks, and utilities.
- **Error Handling:** Route UI errors through app notification patterns—never swallow with empty catch blocks or use `console.log`/`console.error` in UI code.
- **Forms & State:** Validate forms schema-first; normalize nested state.

## Java Conventions
- Use JUnit Jupiter for unit tests.
- Mock boundaries and external services, not internal helper logic.
