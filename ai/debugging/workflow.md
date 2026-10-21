# Debugging Workflow & Subagent Briefs

Policy for standalone debugging and defect resolution tasks.

## Delegation Protocol

When triaging bugs that span multiple files or require independent reproduction:

1. **Reproduction Phase (`role=test tier=standard`):**
   Dispatch `worker-standard` with `[WORKER-BRIEF v1]`:
   - Goal: Write minimal reproduction test and capture failure output.
   - Constraint: Must NOT modify production code.
2. **Fix & Verify Phase (`role=implementation tier=standard`):**
   Dispatch `worker-standard` with `[WORKER-BRIEF v1]`:
   - Goal: Isolate root cause, apply minimal fix, verify reproduction test passes, verify full test suite passes.
   - Constraint: Ponytail Simplicity — smallest fix that resolves the issue.
3. **Audit Phase (`tier=reviewer`):**
   Dispatch `reviewer` with `[WORKER-BRIEF v1]`:
   - Goal: Verify reproduction test validity, audit fix diff for side effects, run regression test suite.
