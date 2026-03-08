# {Plugin Name}

{Brief description of what this plugin provides to Claude Code users}

## Skills

| Skill | Description | Tools Used |
|-------|-------------|------------|
| example-skill | Check system health status using org ops tools | `org_ops_tools.example_tool.check`, `org_ops_tools.example_tool.status` |
| {skill-name} | {What this skill does} | {Tools it invokes} |

## Prerequisites

- **Python** >= 3.11
- **org-ops-tools** >= 1.0.0
  ```bash
  uv pip install git+https://github.com/ifco-frodik/claude-shared-tools.git@v1.0.0
  ```

## Installation

Add the plugin to your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": [
    "https://github.com/ifco-frodik/{plugin-name}"
  ]
}
```

Claude Code will install the plugin on next startup.

## Usage

Invoke skills via slash commands:

```
/{plugin-name}:example-skill
```

Claude will execute the skill's tool commands and return a synthesized result.

## Security

This plugin includes a **PreToolUse guard hook** (`hooks/validate-bash.sh`) that:

- Blocks command chaining operators (`;`, `&`, `|`) in org tool invocations
- Blocks destructive SQL keywords (`DROP TABLE`, `DELETE FROM`, etc.)
- Validates that org tool commands use the `python -m org_ops_tools.` prefix
- Passes non-org commands through to Claude's normal permission system

All skills set `disable-model-invocation: true` by default, requiring explicit user invocation. Authors should remove this only for non-sensitive read-only skills.

## Development

Run local validation checks:

```bash
make validate      # Check plugin structure, plugin.json, skills, hooks
make test-local    # Instructions for testing with Claude Code
```

See the [Makefile](Makefile) for all available targets.
