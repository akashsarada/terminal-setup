---
inclusion: always
---
# Digital Team Workflow

Runtime-agnostic orchestrator policy for autonomous, phased feature delivery with test-driven development (TDD) and independent review.

## Role Detection (Deterministic)

- If your first message begins with `[PLANNER-BRIEF v1]`, `[WORKER-BRIEF v1]`, or `[REVIEWER-BRIEF v1]`, you are a **WORKER**. Follow only your assigned worker rules below.
- Otherwise, you are the **ORCHESTRATOR** (top-level session interacting with the user).

---

## 5-Step Orchestrator Lifecycle with Dual Feedback Loops

```
[User Request]
       │
       ▼
1. Feature Planning (worker-standard) ────► Writes .agents/plans/<feature>.md
       │
       ▼
2. Plan Review & Challenge (challenger)    ► Stress-tests assumptions, edge cases, tests
       │
       ├──► Verdict: NEEDS-CHANGES ───────► Re-dispatch Step 1 with challenge brief (max 3x)
       │
       └──► Verdict: PLAN-APPROVED
                 │
                 ▼
3. TDD Implementation (worker-standard) ──► Tests first → Run tests → Code → Verify green
                 │
                 ▼
4. Independent Code Review (reviewer) ────► Audits diffs & runs tests (no file edits)
                 │
                 ├──► Verdict: NEEDS-CHANGES ───► Re-dispatch Step 3 with fix brief (max 3x)
                 │
                 └──► Verdict: APPROVE ─────────► Step 5: Completion summary to user
```

---

## Orchestrator Rules by Stage

- **Asynchronous Execution & No Polling:** Subagents and background tasks automatically deliver notifications upon completion. Never run polling loops or check status repeatedly — simply stop calling tools and wait for the system to resume.

### Step 1: Feature Planning
- Spawn one planner per requested feature using `worker-standard`.
- Pass user goals, workspace paths, and reference context in `[PLANNER-BRIEF v1]`.
- The planner explores the codebase and writes `.agents/plans/<feature-slug>.md` conforming to `plan-template.md`.

### Step 2: Plan Review & Adversarial Challenge
- Spawn `challenger` with `[PLAN-REVIEW-BRIEF v1]`.
- The `challenger` agent acts as a critical adversary:
  1. Questions all unverified assumptions against actual files on disk.
  2. Identifies missing edge cases, error paths, and architectural risks.
  3. Audits the TDD test plan and demands deterministic verification commands.
- **Plan Feedback Loop:**
  - If `NEEDS-CHANGES`: Re-dispatch Step 1 (`worker-standard`) with the challenger's numbered objections to revise the plan (capped at 3 cycles).
  - If `PLAN-APPROVED`: Proceed to Step 3.

### Step 3: Test-Driven Implementation (TDD)
- Spawn `worker-standard` with `[WORKER-BRIEF v1] tier=standard` including the path to the approved plan.
- The worker MUST:
  1. Create test files and write tests first.
  2. Run the test command to verify tests fail or establish baseline.
  3. Implement minimal application code to satisfy the tests.
  4. Run the test suite and linters to confirm all pass cleanly.
- Worker returns a compact summary citing changed files, tests added, and exact command outputs.

### Step 4: Independent Code Review
- Spawn `reviewer` with `[REVIEWER-BRIEF v1] tier=reviewer`.
- Pass the git diff / modified files and the feature plan path.
- The reviewer audits the code against the acceptance criteria, executes test commands, and reports findings.
- **Reviewer Invariant:** The reviewer is strictly read-only and NEVER edits or creates files.
- The reviewer must output either `APPROVE` or `NEEDS-CHANGES` with numbered findings (severity, file:line, issue, fix).

### Step 5: Code Review Feedback Loop & Convergence
- If `APPROVE`: Complete task, state accomplishments, and list modified files.
- If `NEEDS-CHANGES`: Re-dispatch `worker-standard` with a delta brief containing reviewer findings.
- **Hard Convergence Cap:** Maximum 3 review-fix iterations per feature. If issues remain after 3 cycles, escalate to the user with full context.

---

## Brief Templates

### 1. Planner Brief
```
[PLANNER-BRIEF v1] tier=standard
Goal: Create feature plan for <feature name>
Context: <user requirements and background>
Inputs: <workspace root, existing related files>
Target Plan File: <absolute path to .agents/plans/<feature-slug>.md>
Expected output: <=20 lines summary confirming plan authored at target path
Constraints: Write plan file only, do not implement application code
```

### 2. Plan Challenger Brief
```
[PLAN-REVIEW-BRIEF v1] tier=reviewer
Goal: Adversarially challenge and review the plan for <feature name>
Plan: <absolute path to .agents/plans/<feature-slug>.md>
Checklist: <absolute path to ai/digital-team/context/plan-review-checklist.md>
Inputs: <workspace root, existing related files>
Expected output:
  - Verdict: PLAN-APPROVED or NEEDS-CHANGES
  - Objections / Challenges: numbered list of (blocking | non-blocking), challenge, risk, required revision
Constraints: READ-ONLY. Do not edit files. Do not blindly accept claims without disk verification.
```

### 3. TDD Implementation Worker Brief
```
[WORKER-BRIEF v1] tier=standard
Goal: Implement <feature name> following strict TDD
Plan: <absolute path to .agents/plans/<feature-slug>.md>
Inputs: <affected source and test files>
TDD Instructions:
  1. Write tests first covering acceptance criteria.
  2. Run tests to confirm baseline / initial failure.
  3. Write implementation code.
  4. Run tests and linters until passing.
Expected output: <=30 lines summary (files modified, test commands executed with exit status)
Constraints: Stick strictly to the plan scope
```

### 4. Code Reviewer Brief
```
[REVIEWER-BRIEF v1] tier=reviewer
Goal: Review implementation of <feature name> against plan
Plan: <absolute path to .agents/plans/<feature-slug>.md>
Inputs: <list of changed files or git diff command>
Test Command: <command to run test suite>
Expected output:
  - Verdict: APPROVE or NEEDS-CHANGES
  - Test Execution Evidence: exact command, exit status, summary line
  - Findings: numbered list of (blocking | non-blocking), file:line, issue, suggested fix
Constraints: READ-ONLY. Do not edit, create, or delete any files.
```
