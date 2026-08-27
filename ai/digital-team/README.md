# Digital Team (Autonomous Feature Delivery Workflow)

The `digital-team` workflow provides a structured 4-step software delivery pipeline that turns the current chat session into an orchestrator with strict Test-Driven Development (TDD) and independent code review.

```
digital-team/
├── SKILL.md                   # Open Agent Skill definition for Antigravity & CLI
├── README.md                  # Architecture and usage guide
├── workflow.md                # Runtime-agnostic orchestrator policy & brief templates
└── context/
    ├── plan-template.md       # Blueprint for feature plan .md files
    └── plan-review-checklist.md # Critical review criteria for plan challenger
```

## Design Principles

1. **Adversarial Plan Challenge:** A dedicated `challenger` agent stress-tests plans, questions assumptions, verifies files on disk, and demands concrete verification commands before implementation starts.
2. **Dual Feedback Loops:** Automated review-fix loops on both the plan (Step 1 ⇄ Step 2) and code (Step 3 ⇄ Step 4), each capped at 3 cycles.
3. **Test-First Discipline (TDD):** Workers author tests first, run tests to verify baseline/failure, implement minimal code, and verify green test runs.
4. **Read-Only Independent Review:** The reviewer executes test commands and audits diffs against the feature plan's acceptance criteria, strictly prohibited from editing code.
5. **Shared Agent Infrastructure:** Reuses shared agent specifications in `ai/agents/` (`challenger`, `worker-standard`, `reviewer`, `worker-cheap`).

## Lifecycle Overview

Step | Role / Persona | Agent Invoked | Output
:--- | :--- | :--- | :---
1. Planning | Feature Planner | worker-standard | .agents/plans/<feature>.md conforming to plan-template.md
2. Plan Challenge | Plan Challenger | challenger | PLAN-APPROVED or NEEDS-CHANGES with numbered challenges (loops back to Step 1 on changes)
3. Implementation | TDD Worker | worker-standard | Test authoring → test run → code edits → green tests
4. Code Review | Independent Reviewer | reviewer | APPROVE or NEEDS-CHANGES with test evidence (read-only)
5. Review Loop | Orchestrator | Main Chat | Fix brief dispatch (max 3x) or completion summary

## Multi-Runtime Setup

- **Antigravity:** Copied to `~/.gemini/skills/digital-team/SKILL.md`. Invoked automatically or via prompt: *"Use the digital-team skill to implement <feature>"*.
- **Claude Code:** Rule linked from `~/.claude/rules/digital-team.md` to `workflow.md`.
- **Kiro CLI:** Steering file linked from `~/.kiro/steering/digital-team.md` to `workflow.md`.
