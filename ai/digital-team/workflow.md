---
inclusion: always
---
# Digital Team Workflow

Runtime-agnostic orchestrator policy for autonomous, phased feature delivery with test-driven development (TDD) and independent review.

## Role Detection (Deterministic)

- If your first message begins with `[PLANNER-BRIEF v1]`, `[WORKER-BRIEF v1]`, `[TEST-WORKER-BRIEF v1]`, `[IMPL-WORKER-BRIEF v1]`, or `[REVIEWER-BRIEF v1]`, you are a **WORKER**. Follow only your assigned worker rules below.
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
3. Decoupled TDD Implementation (worker-standard)
   ├── 3a. Test Worker(s) ────────────────► Author tests first → Verify failure/baseline (no app code)
   └── 3b. Impl Worker(s) ────────────────► Implement minimal code → Verify green test suite
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

### Step 3: Decoupled Test-Driven Implementation (TDD)
- The orchestrator separates test authoring from application implementation into distinct subagent invocations, and may spawn multiple subagents concurrently when components/modules are partitionable.
- **Phase 3a: Test Authoring Worker(s)**
  - Spawn one or more `worker-standard` subagents with `[WORKER-BRIEF v1] role=test tier=standard` (or `[TEST-WORKER-BRIEF v1] tier=standard`). When working across independent modules or layers, dispatch multiple test workers in parallel.
  - Test workers MUST:
    1. Author unit and integration tests covering acceptance criteria from the approved plan.
    2. Run test execution commands to confirm baseline failure or discovery.
    3. Verify tests fail for intended reasons (missing implementation, not malformed test setups).
    4. Author tests ONLY; strictly prohibited from writing or editing application/production code.
  - Test workers return a compact summary citing created/modified test files, test command outputs, and baseline failure evidence.
- **Phase 3b: Implementation Worker(s)**
  - Once baseline tests are verified, spawn one or more `worker-standard` subagents with `[WORKER-BRIEF v1] role=implementation tier=standard` (or `[IMPL-WORKER-BRIEF v1] tier=standard`). When modules or services are disjoint, dispatch multiple implementation workers in parallel.
  - Implementation workers MUST:
    1. Inspect authored test failures from Phase 3a.
    2. Implement minimal production code to satisfy the tests.
    3. Run test suites and linters until all pass green cleanly.
    4. Prohibited from editing, weakening, or deleting test files to force passes without explicit orchestrator approval.
  - Implementation workers return a compact summary citing modified source files, test execution outputs, and clean linter status.

### Step 4: Independent Code Review
- Spawn `reviewer` with `[REVIEWER-BRIEF v1] tier=reviewer`.
- Pass the git diff / modified files and the feature plan path.
- The reviewer audits the code against the acceptance criteria, executes test commands, and reports findings.
- **Reviewer Invariant:** The reviewer is strictly read-only and NEVER edits or creates files.
- The reviewer must output either `APPROVE` or `NEEDS-CHANGES` with numbered findings (severity, file:line, issue, fix).

### Step 5: Code Review Feedback Loop & Convergence
- If `APPROVE`: Complete task, state accomplishments, and list modified files.
- If `NEEDS-CHANGES`: Inspect reviewer findings to target the appropriate worker:
  - If implementation defect: Re-dispatch `worker-standard` (`role=implementation`) with reviewer findings.
  - If missing/flawed test: Re-dispatch `worker-standard` (`role=test`) to correct tests, followed by implementation if needed.
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

### 3a. Test Authoring Worker Brief
```
[WORKER-BRIEF v1] role=test tier=standard
Goal: Author tests for <feature/component name> following approved plan
Plan: <absolute path to .agents/plans/<feature-slug>.md>
Inputs: <affected source files, existing test directories, test frameworks>
Test Authoring Instructions:
  1. Author unit and integration tests covering acceptance criteria in the plan.
  2. Run test command to confirm baseline failure or test discovery.
  3. Verify test assertions fail for the right reasons (unimplemented feature, not test syntax errors).
Expected output: <=30 lines summary (test files created/modified, test command executed with failure output)
Constraints: Author test files ONLY. Do NOT implement application/production code.
```

### 3b. Implementation Worker Brief
```
[WORKER-BRIEF v1] role=implementation tier=standard
Goal: Implement application code for <feature/component name> to pass authored tests
Plan: <absolute path to .agents/plans/<feature-slug>.md>
Authored Tests: <paths to test files created in Phase 3a>
Inputs: <affected source files, relevant modules>
Implementation Instructions:
  1. Inspect authored test failures from Phase 3a.
  2. Implement minimal production code to satisfy tests.
  3. Run test suites and linters until all pass green.
Expected output: <=30 lines summary (source files modified, test commands executed with exit status)
Constraints: Modify application code only. Do NOT modify or weaken test files without orchestrator approval.
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
