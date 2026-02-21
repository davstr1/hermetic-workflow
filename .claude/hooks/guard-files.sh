#!/usr/bin/env bash
# guard-files.sh — PreToolUse hook for hermetic agent isolation.
#
# Reads HERMETIC_AGENT env var (set by orchestrator.sh).
# If agent is "coder", blocks access to forbidden paths.
# Non-coder agents pass through immediately (zero overhead).
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (tool is denied, stderr shown to agent)

set -euo pipefail

# Only restrict the coder agent
if [[ "${HERMETIC_AGENT:-}" != "coder" ]]; then
  exit 0
fi

# Read the tool input from stdin (JSON)
INPUT=$(cat)

TOOL_NAME="${TOOL_NAME:-}"

# Extract file paths / patterns / commands from the tool input depending on tool type
check_path() {
  local path_to_check="$1"

  # Normalize: strip leading ./ if present
  path_to_check="${path_to_check#./}"

  # Forbidden patterns for the coder agent
  local forbidden_patterns=(
    # Test files
    '*.test.*'
    '*.spec.*'
    '__tests__/*'
    '__tests__'
    'tests/*'
    'tests'
    '*.test.ts'
    '*.test.tsx'
    '*.test.js'
    '*.test.jsx'
    '*.spec.ts'
    '*.spec.tsx'
    '*.spec.js'
    '*.spec.jsx'

    # Lint rules and config
    'example-ui-rules/eslint-rules/*'
    'example-ui-rules/eslint-rules'
    'example-ui-rules/stylelint-rules/*'
    'example-ui-rules/stylelint-rules'
    'example-ui-rules/bin/*'
    'example-ui-rules/bin'
    'example-ui-rules/.eslintrc*'
    'eslint-config.*'
    '.eslintrc*'
    'stylelint.config.*'

    # Agent prompts
    'prompts/*'
    'prompts'

    # Project principles — READABLE by coder (gives direction without revealing enforcement)
    # 'principles.md'  ← intentionally NOT blocked

    # Review state (defense in depth — orchestrator injects feedback into prompt)
    'workflow/state/review-feedback.md'
    'workflow/state/review-status.txt'
    'workflow/state/escalation-context.md'
  )

  for pattern in "${forbidden_patterns[@]}"; do
    case "$pattern" in
      # Patterns ending with /* match anything under that directory
      */\*)
        local dir_prefix="${pattern%/*}"
        if [[ "$path_to_check" == "$dir_prefix"/* || "$path_to_check" == "$dir_prefix" ]]; then
          return 1
        fi
        ;;
      # Glob patterns with * in the filename part
      \**.*)
        # e.g. *.test.* — check if basename matches
        local basename
        basename=$(basename "$path_to_check")
        # Use bash pattern matching
        case "$basename" in
          *.test.*|*.spec.*) return 1 ;;
        esac
        ;;
      # Exact matches or simple globs
      *)
        if [[ "$path_to_check" == $pattern ]]; then
          return 1
        fi
        ;;
    esac
  done

  return 0
}

# Extract relevant paths from the tool input JSON based on tool name
extract_and_check() {
  local blocked=0

  case "$TOOL_NAME" in
    Read)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        # Make relative to project dir
        file_path="${file_path#"${CLAUDE_PROJECT_DIR}"/}"
        if ! check_path "$file_path"; then
          echo "BLOCKED: Coder agent cannot read '$file_path'. This path is outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Write|Edit)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        file_path="${file_path#"${CLAUDE_PROJECT_DIR}"/}"
        if ! check_path "$file_path"; then
          echo "BLOCKED: Coder agent cannot write to '$file_path'. This path is outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Glob)
      local pattern
      pattern=$(echo "$INPUT" | jq -r '.pattern // empty' 2>/dev/null)
      if [[ -n "$pattern" ]]; then
        # Check if the glob pattern targets forbidden directories
        for forbidden_dir in "prompts" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "__tests__" "tests" "workflow/state"; do
          if [[ "$pattern" == *"$forbidden_dir"* ]]; then
            echo "BLOCKED: Coder agent cannot glob '$pattern'. This path is outside your scope." >&2
            blocked=1
            break
          fi
        done
        # Check for test file patterns
        if [[ "$pattern" == *".test."* || "$pattern" == *".spec."* ]]; then
          echo "BLOCKED: Coder agent cannot glob for test files." >&2
          blocked=1
        fi
      fi
      ;;

    Grep)
      local path
      path=$(echo "$INPUT" | jq -r '.path // empty' 2>/dev/null)
      if [[ -n "$path" ]]; then
        path="${path#"${CLAUDE_PROJECT_DIR}"/}"
        if ! check_path "$path"; then
          echo "BLOCKED: Coder agent cannot search in '$path'. This path is outside your scope." >&2
          blocked=1
        fi
      fi
      local glob
      glob=$(echo "$INPUT" | jq -r '.glob // empty' 2>/dev/null)
      if [[ -n "$glob" ]]; then
        if [[ "$glob" == *".test."* || "$glob" == *".spec."* ]]; then
          echo "BLOCKED: Coder agent cannot search test files." >&2
          blocked=1
        fi
      fi
      ;;

    Bash)
      local command
      command=$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)
      if [[ -n "$command" ]]; then
        # Check if command references forbidden paths
        for forbidden in "prompts/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "review-feedback.md" "review-status.txt" "escalation-context.md"; do
          if [[ "$command" == *"$forbidden"* ]]; then
            echo "BLOCKED: Coder agent cannot access '$forbidden' via shell commands." >&2
            blocked=1
            break
          fi
        done
        # Block reading test files via shell
        if [[ "$command" == *".test."* || "$command" == *".spec."* || "$command" == *"__tests__"* ]]; then
          # Allow running tests (npx jest, npm test, etc.) but block reading test file contents
          if [[ "$command" != *"jest"* && "$command" != *"vitest"* && "$command" != *"npm test"* && "$command" != *"npm run test"* && "$command" != *"npx test"* ]]; then
            echo "BLOCKED: Coder agent cannot access test files via shell." >&2
            blocked=1
          fi
        fi
      fi
      ;;
  esac

  return $blocked
}

if ! extract_and_check; then
  exit 2
fi

exit 0
