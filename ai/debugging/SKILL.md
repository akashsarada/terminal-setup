---
name: debugging
description: Apply when investigating, diagnosing, reproducing, or fixing defects, test failures, or runtime errors. Enforces systematic 4-step root-cause reproduction, isolation, minimal fixes, and regression verification.
---

# Systematic Debugging Skill

Apply this skill when investigating a bug, defect report, broken test, or unexpected runtime behavior.

## Core Principle
Never patch code based on assumptions or unverified hypotheses. Always isolate the root cause with a reproduction test before touching production code.

## 4-Step Protocol

### Step 1: Reproduce & Characterize
- Do NOT edit production application code yet.
- Author a minimal, deterministic reproduction test or script that exercises the failure path.
- Execute the test and capture the exact failure output, stack trace, and exit code.
- Confirm the failure reproduces consistently and is not an artifact of bad test setup.

### Step 2: Isolate Root Cause
- Trace backwards from the reproduction failure to the earliest invalid state or violated invariant.
- Verify assumptions against actual files on disk and execution logs — never guess.
- Isolate the single root cause (e.g., edge case, race condition, bad type coercion, off-by-one).

### Step 3: Minimal Fix (Ponytail Simplicity)
- Formulate the smallest, least invasive fix that addresses the root cause directly.
- Climb the Simplicity Ladder: avoid premature abstractions, new dependencies, or speculative refactoring of adjacent code.
- Apply the fix only to the necessary lines in production code.

### Step 4: Verify & Defend Against Regression
- Run the reproduction test and confirm it now passes green.
- Run the full test suite and linters to verify zero regressions were introduced.
- Provide deterministic evidence: exact test command, exit code, and passing summary.
