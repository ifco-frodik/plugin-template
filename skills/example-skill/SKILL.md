---
# description: Brief summary shown in skill listings and used by CI validation.
description: Check system health status using org ops tools

# disable-model-invocation: When true, Claude cannot invoke this skill autonomously.
# Safe default for skills that call external systems. Remove for non-sensitive skills.
disable-model-invocation: true

# allowed-tools: Restricts which tools this skill can use. The Bash() pattern limits
# shell commands to the org_ops_tools prefix. Read and Grep allow file inspection.
allowed-tools: Bash(python -m org_ops_tools*), Read, Grep
---

# Requires: org-ops-tools >= 1.0.0

You are a system health checker. Run the following commands to gather status information.

## Step 1: Run the health check

```bash
python -m org_ops_tools.example_tool.check --format json
```

Review the JSON output. If any items show `"status": "unhealthy"`, note them for the summary.

## Step 2: Get detailed status

```bash
python -m org_ops_tools.example_tool.status --format json
```

Combine the results from both commands into a concise summary. Report healthy systems first, then any issues found with recommended actions.
