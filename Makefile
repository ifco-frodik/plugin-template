PYTHON ?= python3

.PHONY: help validate test-local

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

validate: ## Validate plugin structure (all checks)
	@echo "=== Plugin Structure Validation ==="
	@echo ""
	@# Check plugin.json exists
	@if [ -f .claude-plugin/plugin.json ]; then \
		echo "PASS: .claude-plugin/plugin.json exists"; \
	else \
		echo "FAIL: .claude-plugin/plugin.json is missing"; \
		exit 1; \
	fi
	@# Check plugin.json is valid JSON
	@if $(PYTHON) -c "import json; json.load(open('.claude-plugin/plugin.json'))" 2>/dev/null; then \
		echo "PASS: plugin.json is valid JSON"; \
	else \
		echo "FAIL: plugin.json is not valid JSON"; \
		exit 1; \
	fi
	@# Check plugin.json has required fields
	@if $(PYTHON) -c "\
	import json, sys; \
	m = json.load(open('.claude-plugin/plugin.json')); \
	required = ['name', 'version', 'description', 'author', 'homepage', 'repository']; \
	missing = [f for f in required if f not in m]; \
	sys.exit(1) if missing else None; \
	" 2>/dev/null; then \
		echo "PASS: plugin.json has all required fields"; \
	else \
		echo "FAIL: plugin.json is missing required fields (name, version, description, author, homepage, repository)"; \
		exit 1; \
	fi
	@# Check at least one skill directory exists
	@if [ -d skills ] && [ "$$(ls -d skills/*/ 2>/dev/null | head -1)" != "" ]; then \
		echo "PASS: skills/ directory has at least one skill"; \
	else \
		echo "FAIL: skills/ directory must contain at least one skill"; \
		exit 1; \
	fi
	@# Check each skill has SKILL.md with description
	@SKILL_FAIL=0; \
	for skill_dir in skills/*/; do \
		skill_name=$$(basename "$$skill_dir"); \
		if [ ! -f "$$skill_dir/SKILL.md" ]; then \
			echo "FAIL: $$skill_dir is missing SKILL.md"; \
			exit 1; \
		fi; \
		if grep -q 'description:' "$$skill_dir/SKILL.md"; then \
			echo "PASS: skills/$$skill_name/SKILL.md has description"; \
		else \
			echo "FAIL: skills/$$skill_name/SKILL.md is missing description in frontmatter"; \
			exit 1; \
		fi; \
	done
	@# Check hooks/hooks.json exists
	@if [ -f hooks/hooks.json ]; then \
		echo "PASS: hooks/hooks.json exists"; \
	else \
		echo "FAIL: hooks/hooks.json is missing"; \
		exit 1; \
	fi
	@# Check hooks/validate-bash.sh exists and is executable
	@if [ -f hooks/validate-bash.sh ]; then \
		if [ -x hooks/validate-bash.sh ]; then \
			echo "PASS: hooks/validate-bash.sh exists and is executable"; \
		else \
			echo "FAIL: hooks/validate-bash.sh is not executable (run: chmod +x hooks/validate-bash.sh)"; \
			exit 1; \
		fi; \
	else \
		echo "FAIL: hooks/validate-bash.sh is missing"; \
		exit 1; \
	fi
	@# Check README.md exists
	@if [ -f README.md ]; then \
		echo "PASS: README.md exists"; \
	else \
		echo "FAIL: README.md is missing"; \
		exit 1; \
	fi
	@# Warn about README placeholders (do not fail)
	@if grep -qE '\{[A-Za-z]' README.md 2>/dev/null; then \
		echo "WARN: README.md still contains placeholder fields -- update before publishing"; \
	fi
	@echo ""
	@echo "=== All checks passed ==="

test-local: ## Print instructions for testing with Claude Code
	@echo "To test this plugin locally with Claude Code:"
	@echo "  1. Add this repo path to .claude/settings.json enabledPlugins"
	@echo "  2. Open a Claude Code session in a project"
	@echo "  3. Verify hooks appear: run /hooks"
	@echo "  4. Test guard: try a Bash command with org_ops_tools prefix"
