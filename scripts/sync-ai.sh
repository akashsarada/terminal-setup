#!/usr/bin/env bash

# AI steering, rules, skills, and agents sync helper

sync_kiro() {
  local script_dir="$1"
  mkdir -p "$HOME/.kiro/steering"
  cp "$script_dir/ai/global-conventions.md" "$HOME/.kiro/steering/"
  cp "$script_dir/ai/code-conventions.md" "$HOME/.kiro/steering/"
  cp "$script_dir/ai/delegation/core.md" "$HOME/.kiro/steering/delegation-core.md"
  cp "$script_dir/ai/delegation/adapters/kiro-binding.md" "$HOME/.kiro/steering/delegation-kiro-binding.md"
  cp "$script_dir/ai/digital-team/workflow.md" "$HOME/.kiro/steering/digital-team.md"
  echo "✅ Copied AI steering files to ~/.kiro/steering/"
}

sync_claude() {
  local script_dir="$1"
  mkdir -p "$HOME/.claude/rules"
  cp "$script_dir/ai/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  cp "$script_dir/ai/global-conventions.md" "$HOME/.claude/rules/"
  cp "$script_dir/ai/code-conventions.md" "$HOME/.claude/rules/"
  cp "$script_dir/ai/delegation/core.md" "$HOME/.claude/rules/delegation-core.md"
  cp "$script_dir/ai/digital-team/workflow.md" "$HOME/.claude/rules/digital-team.md"
  echo "✅ Copied AI steering files to ~/.claude/rules/ and ~/.claude/CLAUDE.md"
}

sync_antigravity() {
  local script_dir="$1"
  mkdir -p "$HOME/.gemini/skills/delegation-core"
  mkdir -p "$HOME/.gemini/skills/digital-team"
  mkdir -p "$HOME/.gemini/config/agents"
  cp "$script_dir/ai/AGENTS.md" "$HOME/.gemini/GEMINI.md"
  cp "$script_dir/ai/global-conventions.md" "$HOME/.gemini/"
  cp "$script_dir/ai/code-conventions.md" "$HOME/.gemini/"
  cp "$script_dir/ai/delegation/core.md" "$HOME/.gemini/delegation-core.md"
  cp "$script_dir/ai/digital-team/workflow.md" "$HOME/.gemini/digital-team.md"
  cp "$script_dir/ai/delegation/SKILL.md" "$HOME/.gemini/skills/delegation-core/SKILL.md"
  cp "$script_dir/ai/digital-team/SKILL.md" "$HOME/.gemini/skills/digital-team/SKILL.md"
  for agent_file in "$script_dir/ai/agents/antigravity/"*.md; do
    if [ -f "$agent_file" ]; then
      local agent_name
      agent_name=$(basename "$agent_file" .md)
      mkdir -p "$HOME/.gemini/config/agents/$agent_name"
      cp "$agent_file" "$HOME/.gemini/config/agents/$agent_name/agent.md"
    fi
  done
  echo "✅ Copied AI steering, skill, and agent files to ~/.gemini/"
}

sync_ai_configs() {
  local script_dir="$1"
  local force_kiro="${2:-false}"
  local force_claude="${3:-false}"
  local force_antigravity="${4:-false}"

  if [[ "$force_kiro" == true ]] || command -v kiro &>/dev/null || [ -d "$HOME/.kiro" ]; then
    sync_kiro "$script_dir"
  else
    echo "⏩ Skipped ~/.kiro/steering/ (kiro not selected/installed)"
  fi

  if [[ "$force_claude" == true ]] || command -v claude &>/dev/null || [ -d "$HOME/.claude" ]; then
    sync_claude "$script_dir"
  else
    echo "⏩ Skipped ~/.claude/rules/ (claude not selected/installed)"
  fi

  if [[ "$force_antigravity" == true ]] || command -v agy &>/dev/null || [ -d "$HOME/.gemini" ]; then
    sync_antigravity "$script_dir"
  else
    echo "⏩ Skipped ~/.gemini/ (antigravity not selected/installed)"
  fi
}
