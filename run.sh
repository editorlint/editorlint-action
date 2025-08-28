#!/bin/bash
set -euo pipefail

cd "$GITHUB_WORKSPACE"

# Build arguments array
if [ "${INPUT_ARGS}" != "" ]; then
  # Use custom args if provided - split on whitespace but preserve quoted strings
  read -ra ARGS <<< "${INPUT_ARGS}"
  # Always add the path at the end if not already included
  if [[ ! "${INPUT_ARGS}" =~ [[:space:]]"${INPUT_PATH}"($|[[:space:]]) && ! "${INPUT_ARGS}" =~ ^"${INPUT_PATH}"($|[[:space:]]) ]]; then
    ARGS+=("${INPUT_PATH}")
  fi
else
  # Use structured inputs to build args
  ARGS=("${INPUT_PATH}")

  if [ "${INPUT_CONFIG_FILE:-}${INPUT_CONFIG:-}" != "" ]; then
    ARGS+=("--config" "${INPUT_CONFIG_FILE:-${INPUT_CONFIG}}")
  fi

  if [ "${INPUT_RECURSE}" = "true" ]; then
    ARGS+=("--recurse")
  fi

  if [ "${INPUT_FIX}" = "true" ]; then
    ARGS+=("--fix")  
  fi

  if [ "${INPUT_OUTPUT_FORMAT:-}${INPUT_REPORTER:-}" != "default" ]; then
    ARGS+=("--output" "${INPUT_OUTPUT_FORMAT:-${INPUT_REPORTER}}")
  fi

  if [ "${INPUT_EXCLUDE}" != "" ]; then
    IFS=',' read -ra PATTERNS <<< "${INPUT_EXCLUDE}"
    for pattern in "${PATTERNS[@]}"; do
      trimmed_pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      ARGS+=("--exclude" "$trimmed_pattern")
    done
  fi
fi

# Run editorlint
set +e
OUTPUT=$("$EDITORLINT_BINARY_PATH" "${ARGS[@]}" 2>&1)
EXIT_CODE=$?
set -e

echo "$OUTPUT"

# Parse results
VIOLATIONS_FOUND="false"
FILES_PROCESSED="0"
FILES_FIXED="0"

if [ $EXIT_CODE -ne 0 ] && [ "${INPUT_FIX}" = "false" ]; then
  VIOLATIONS_FOUND="true"
fi

if echo "$OUTPUT" | grep -q "files processed"; then
  FILES_PROCESSED=$(echo "$OUTPUT" | grep "files processed" | sed -n 's/.*\([0-9]\+\) files processed.*/\1/p' || echo "0")
fi

if echo "$OUTPUT" | grep -q "files fixed"; then
  FILES_FIXED=$(echo "$OUTPUT" | grep "files fixed" | sed -n 's/.*\([0-9]\+\) files fixed.*/\1/p' || echo "0")
  if [ "$FILES_FIXED" != "0" ]; then
    VIOLATIONS_FOUND="true"
  fi
fi

# Set outputs
echo "violations-found=$VIOLATIONS_FOUND" >> $GITHUB_OUTPUT
echo "files-processed=$FILES_PROCESSED" >> $GITHUB_OUTPUT  
echo "files-fixed=$FILES_FIXED" >> $GITHUB_OUTPUT

# Handle auto-commit
if [ "${INPUT_AUTO_COMMIT}" = "true" ] && [ "${INPUT_FIX}" = "true" ] && [ "$FILES_FIXED" != "0" ]; then
  echo "Auto-committing fixes..."
  git config --local user.name "${INPUT_GIT_USER_NAME}"
  git config --local user.email "${INPUT_GIT_USER_EMAIL}"

  if git diff --exit-code > /dev/null 2>&1; then
    echo "No changes to commit after fixes"
  else
    git add .
    git commit -m "${INPUT_COMMIT_MESSAGE}"
    git push
  fi
fi

# Save outputs for PR comment step
echo "VIOLATIONS_FOUND=$VIOLATIONS_FOUND" >> $GITHUB_ENV
echo "FILES_PROCESSED=$FILES_PROCESSED" >> $GITHUB_ENV
echo "FILES_FIXED=$FILES_FIXED" >> $GITHUB_ENV

# Save the raw output for PR comments
{
  echo "EDITORLINT_OUTPUT<<EOF"
  echo "$OUTPUT"
  echo "EOF"
} >> $GITHUB_ENV

# Fail if violations found and fail-on-violations is enabled
if [ "${INPUT_FAIL_ON_VIOLATIONS}" = "true" ] && [ "$VIOLATIONS_FOUND" = "true" ] && [ "${INPUT_FIX}" = "false" ]; then
  echo "Violations found and fail-on-violations is enabled"
  exit 1
fi