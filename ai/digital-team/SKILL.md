---
name: digital-team
description: Apply when orchestrating end-to-end feature development with planning, test-driven implementation (TDD), code review, and automated review-fix loops using dedicated worker and reviewer agents.
---

# Digital Team Skill

When the user asks to implement one or more features using the digital team workflow:

1. **Role:** Act as the **ORCHESTRATOR**. Follow the policy and brief templates in `ai/digital-team/workflow.md`.
2. **Step 1 — Feature Planning:**
   - Dispatch `worker-standard` with `[PLANNER-BRIEF v1]` to explore the codebase and write `.agents/plans/<feature-slug>.md` using `ai/digital-team/context/plan-template.md`.
3. **Step 2 — Plan Review & Adversarial Challenge:**
   - Dispatch `challenger` with `[PLAN-REVIEW-BRIEF v1]` to stress-test the plan against `ai/digital-team/context/plan-review-checklist.md`.
   - If `NEEDS-CHANGES`: Re-dispatch Step 1 (`worker-standard`) with objections to revise the plan (capped at 3 cycles).
   - If `PLAN-APPROVED`: Proceed to Step 3.
4. **Step 3 — Test-Driven Implementation:**
   - Dispatch `worker-standard` with `[WORKER-BRIEF v1] tier=standard`.
   - The worker must follow strict TDD:
     1. Write unit/integration tests first.
     2. Run tests to observe failure/baseline.
     3. Implement minimal code to satisfy tests.
     4. Re-run tests and linters until passing.
5. **Step 4 — Independent Code Review:**
   - Dispatch `reviewer` with `[REVIEWER-BRIEF v1] tier=reviewer`.
   - The reviewer audits diffs against acceptance criteria and executes test commands.
   - The reviewer is **strictly read-only** and never edits files.
   - Verdict must be `APPROVE` or `NEEDS-CHANGES` with numbered findings.
6. **Step 5 — Code Review Feedback Loop:**
   - If `NEEDS-CHANGES`: Re-dispatch `worker-standard` with reviewer findings (capped at 3 cycles).
   - If `APPROVE`: Complete the task and summarize accomplishments.
