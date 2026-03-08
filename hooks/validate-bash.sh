#!/bin/bash
# PreToolUse guard for Bash commands in org plugins.
# Receives JSON on stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# Exit 0 with no output = allow
# Exit 0 with deny JSON  = block with reason

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# No command or empty -> allow
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Normalize multi-line commands to single line for regex checks
COMMAND=$(echo "$COMMAND" | tr '\n' ' ')

# Non-org command -> passthrough (let Claude's normal permissions handle it)
if ! echo "$COMMAND" | grep -qE '^\s*python -m org_ops_tools\.'; then
  exit 0
fi

# --- Org command validation ---

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# Block command chaining operators (;, &, |)
if echo "$COMMAND" | grep -qE '[;&|]'; then
  # Allow single pipe to jq (common safe pattern)
  if echo "$COMMAND" | grep -qE '^\s*python -m org_ops_tools\.[a-zA-Z_.]+(\s+[^;&|]*)?\s*\|\s*jq\s[^|;&]*$'; then
    : # jq pipe exception -- fall through to remaining checks
  else
    deny "Command chaining (;, &, |) is not allowed in org tool invocations. Use separate commands."
  fi
fi

# Block destructive SQL keywords (case-insensitive)
if echo "$COMMAND" | grep -iE '(DROP|DELETE|TRUNCATE|ALTER|INSERT|UPDATE|CREATE)\s+(TABLE|DATABASE|INDEX|VIEW|SCHEMA|PROCEDURE|FROM)' >/dev/null 2>&1; then
  deny "Destructive SQL operations are blocked. Use read-only queries."
fi

# Org command passed all checks -> allow
exit 0
