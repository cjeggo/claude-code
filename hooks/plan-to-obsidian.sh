#!/bin/bash
# Fires after ExitPlanMode (plan approved). Only active for projects using Obsidian.
if grep -qi "obsidian" CLAUDE.md 2>/dev/null; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"MANDATORY: A plan was just approved. Before starting any implementation, write the complete plan to the Obsidian vault under Plans/<descriptive-name>.md using mcp__obsidian-vault__write_note. Choose a note name that captures the goal of the plan. Include backlinks to related notes. The vault path is specified in CLAUDE.md. Do not begin implementation until the plan is saved."}}'
fi
