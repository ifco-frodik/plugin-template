#!/bin/bash
# Test harness for validate-bash.sh PreToolUse guard script.
# Each test pipes JSON to the guard script and checks exit code + stdout.

set -euo pipefail

GUARD="plugin-template/hooks/validate-bash.sh"
PASS=0
FAIL=0

test_case() {
  local desc="$1" input="$2" expect="$3"
  OUTPUT=$(echo "$input" | bash "$GUARD" 2>/dev/null) || true
  EXIT=$?

  case "$expect" in
    allow)
      if [ "$EXIT" -eq 0 ] && [ -z "$OUTPUT" ]; then
        PASS=$((PASS + 1))
        echo "  PASS: $desc"
      else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $desc (expected allow: exit=0,empty output; got exit=$EXIT, output='$OUTPUT')"
      fi
      ;;
    deny)
      if [ "$EXIT" -eq 0 ] && echo "$OUTPUT" | grep -q '"deny"'; then
        PASS=$((PASS + 1))
        echo "  PASS: $desc"
      else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $desc (expected deny JSON; got exit=$EXIT, output='$OUTPUT')"
      fi
      ;;
  esac
}

echo "=== PreToolUse Guard Tests ==="
echo ""

# --- Basic passthrough tests ---
echo "-- Passthrough / Allow --"

test_case "Empty command input" \
  '{"tool_input":{"command":""}}' \
  allow

test_case "Non-org command (ls -la)" \
  '{"tool_input":{"command":"ls -la"}}' \
  allow

test_case "Clean org command" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --db prod"}}' \
  allow

test_case "Non-org command with pipe (ls | grep foo)" \
  '{"tool_input":{"command":"ls | grep foo"}}' \
  allow

test_case "No tool_input.command field" \
  '{"tool_input":{}}' \
  allow

test_case "Org command piped to jq" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo | jq .status"}}' \
  allow

# --- Deny tests: chaining operators ---
echo ""
echo "-- Chaining Operator Denials --"

test_case "Org command with semicolon" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo; rm -rf /"}}' \
  deny

test_case "Org command with ampersand" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo && echo done"}}' \
  deny

test_case "Org command with pipe (not jq)" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo | cat"}}' \
  deny

# --- Deny tests: destructive SQL ---
echo ""
echo "-- Destructive SQL Denials --"

test_case "Org command with DROP TABLE" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --query \"DROP TABLE users\""}}' \
  deny

test_case "Org command with DELETE FROM" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --query \"DELETE FROM users\""}}' \
  deny

test_case "Org command with TRUNCATE TABLE" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --query \"TRUNCATE TABLE users\""}}' \
  deny

# --- Edge cases ---
echo ""
echo "-- Edge Cases --"

# Multi-line command: newline-separated chaining should be caught after normalization
test_case "Multi-line org command with chaining" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo\n; rm -rf /"}}' \
  deny

# Double jq pipe: should be blocked (single pipe to jq only)
test_case "Double jq pipe blocked" \
  '{"tool_input":{"command":"python -m org_ops_tools.foo | jq . | jq .bar"}}' \
  deny

# Lowercase SQL: case-insensitive detection
test_case "Lowercase drop table blocked" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --query \"drop table users\""}}' \
  deny

# Safe SQL: SELECT is not destructive
test_case "Safe SELECT query allowed" \
  '{"tool_input":{"command":"python -m org_ops_tools.sqlmi.query --query \"SELECT * FROM users\""}}' \
  allow

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
