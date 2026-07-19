---
inclusion: always
---
# Global Conventions

## File Reading
- When asked to read or check a file, ALWAYS re-read it fresh from disk — never rely on a cached/prior version. External scripts may have modified it since last read.
- ALWAYS re-read `.cr-review-report.md` every time it is referenced, discussed, or analyzed. Never use a previously cached version of this file.
- The report has two numbered sections: "AutoSDE Findings" (numbered 1–N) and "Senior Dev Review" (numbered independently starting at 1). When the user references a finding by number (e.g. "fix #3"), match it to the correct section based on context. AutoSDE findings include a category tag like `[ERROR_HANDLING]` or `[GENERAL]`; Senior Dev findings have a category header like `## Design` or `## Correctness`.

**MANDATORY**: When the user says "review", "fix", "address", "look at the report", or references ANY finding number — you MUST read `.cr-review-report.md` from disk FIRST before responding. Do NOT attempt to fix or discuss findings from memory. Do NOT guess what the report contains. READ THE FILE.

## Subagent Delegation
- Spawn subagents on a cheaper/faster model for parallelizable grunt work: file reading, search, classification, extraction, formatting, and bulk repetitive edits
- Reserve the primary model for reasoning, architecture decisions, complex debugging, and final synthesis
- When a task has 2+ independent research steps, delegate them in parallel rather than doing them sequentially
- Never spawn a subagent for something faster to do inline (single file read, one grep)
- See `delegation/core.md` for delegation policy and tiers; runtime mechanics and the tier→model maps live in `delegation/adapters/`

## File Extensions: .ts vs .tsx
- `.tsx` — files that render JSX (React components, pages, panels, modals, split-pane views)
- `.ts` — pure TypeScript with no React rendering: helpers, utilities, data transformers, constants, types, enums, GraphQL codegen output
- If a file has no JSX but uses React hooks (useState, useMemo, useCallback, useEffect) or makes API calls, extract it as a **custom hook** (`use*.ts`) — hooks are `.ts` not `.tsx` because they return data, not JSX
- Never put standalone utility functions (formatCurrency, parseDate, buildFilter) in `.tsx` files — keep them in dedicated `.ts` helper/util modules
- Test files follow their source: `component.test.tsx` for components, `helper.test.ts` for utilities

## TypeScript / React Style
- Use kebab-case for file names, PascalCase for components
- Define components using the `function` keyword (not arrow functions)
- Prefer functional components with TypeScript interfaces/types
- No custom CSS — use only Cloudscape/design system layout primitives (Grid, SpaceBetween, ColumnLayout, etc.) instead of inline styles on divs
- Import Cloudscape components from `@amzn/uno-awsui-components-react-themed`
- Use `useCallback` for callback functions passed as props or used in event handlers
- Use `useMemo` for expensive computations
- Avoid inline function definitions in JSX unless trivially simple
- Implement proper cleanup in useEffect hooks (isCancelled flags, abort controllers)
- Only include used dependencies in useEffect dependency arrays
- Prefer `||` over `??` when empty strings should also trigger fallback values
- Don't use try/catch or .then/.catch in UI component code — handle errors through GraphQL `onError` callbacks, Apollo error states, or notification helpers
- Don't `console.log`/`console.error` in UI code — use the app's notification/flashbar pattern to surface errors to the user
- Handle error typenames in GraphQL `onCompleted` callbacks, not just the success case
- Keep components under ~500 lines; extract sub-panes, utilities, and hooks into separate files
- Document non-obvious prop contracts with TSDoc (especially props that change data-fetching behavior)
- Use "geography" not "region" when referring to business locations (NA, EU, FE)
- Use generated GraphQL hooks only — no manual queries
- Don't commit build artifacts or paths containing `/Volumes/workplace/`
- Add explicit typing — avoid `any`. Always add explicit return types to functions and callbacks (e.g. `function foo(): string` not just `function foo()`)
- Prefer functional composition over imperative loops
- Use proper key props in lists (avoid using index as key)

## State Management
- Use Zustand store for global state
- Use createSlice to define state, reducers, and actions together
- Normalize state structure — avoid deeply nested data
- Use selectors to encapsulate state access
- Separate concerns by feature — no monolithic slices

## Form Validation
- Use Zod + react-hook-form for schema and form validation
- Implement proper error messages for validation failures

## Comments — CRITICAL, ALWAYS FOLLOW
- You MUST NOT add comments that describe what code does — variable names and structure should convey intent
- You MUST NOT add comments within methods — refactor unclear code instead
- You MUST NOT narrate implementation steps in comments (e.g. "// Fetch the data", "// Check if valid", "// Return the result")
- Inline comments are ONLY acceptable as a brief "why" (1-2 lines max) when the reason is non-obvious
- TSDoc comments should be at most 2 lines — a single sentence for purpose and one for a non-obvious constraint. If it needs more, the code needs refactoring.
- Put detailed explanations in the module-level TSDoc, not inline
- CR descriptions should include screenshots/screen recordings for UI changes

## Performance
- Watch for O(n²) algorithms that could be O(n)
- Identify missed caching opportunities
- Check for memory leaks or excessive allocations in effects

## cr-review Tool
- Located at `~/.local/bin/cr-review` — runs AutoSDE + senior dev review locally without raising a CR
- Run from inside a Brazil package directory with staged changes
- Default: reviews `git diff --staged`, outputs to `.cr-review-report.md`
- Key flags: `-H` (last commit), `-d <range>` (custom diff), `-B` (skip build), `-v` (verbose), `-n` (submit only, don't poll)
- Two-part review: (1) AutoSDE API findings, (2) kiro-cli orr-reviewer-agent senior dev review
- Report saved to `.cr-review-report.md` in the current directory — always re-read this file fresh
- Detects duplicate diffs (SHA-256 hash) and warns if unchanged since last run
- Build gate runs `brazil-build clean/build/fix/release` unless `-B` is passed
- Use `-s <id>` to reuse a session ID for CR cache priming (embed `[autosde:session=ID]` in CR description)

## Git & Workflow
- Use `cr` for code reviews, never `git push` directly
- Prefer `git diff --staged` over `git diff --cached`
- Create fresh workspaces for CR fixes rather than stash/rebase in dirty trees
- Don't stack commits on unmerged parent CRs — CRUX can't merge if base isn't ancestor of mainline
- Amend commits freely as long as they are unpushed and the changes are related to the existing commit
- Do NOT write commit descriptions (the body after the subject line) — only write a concise commit subject

## Build
- Brazil build system: `brazil-build` for builds, `brazil-build start` for dev server
- Run `brazil-build clean` after interface changes (stale generated classes)

## Testing
- Consolidate tests in the data layer package
- Use Vitest for TypeScript, JUnit Jupiter for Java
- Don't mock library internals — only mock boundaries (APIs, services)
- Dev-only utilities still need tests for edge cases (caching, concurrency, expiry)

## Java
- Use Immutables (@Value.Immutable) for data models
- Clean build required after interface changes (stale generated classes)

## Terminal
- Prefer tmux splits over in-editor terminals
- No lazygit integration
