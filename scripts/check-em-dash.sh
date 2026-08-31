#!/usr/bin/env bash
# Mechanical enforcement of the "Never use em dashes" rule from
# plugins/soul/instructions/general.instructions.md, for contexts the PreToolUse hook
# (plugins/soul/hooks/guard-em-dash.sh) can't reach: pre-commit and CI, where changes may not
# have gone through Claude Code at all (Copilot CLI has no working PreToolUse dispatch as of
# 2026-08-05, see CLAUDE.md), or through neither agent.
#
# Usage: check-em-dash.sh [file...]
#   Defaults to all git-tracked .md/.mdx/.txt files if no paths are given.

set -euo pipefail

# Files that intentionally show the em dash character itself as a documentation example
# (the style guide's "don't do this" samples, and the rule's own self-reference) rather than
# using it as punctuation. Keep this list short and each entry justified; anything else with
# an em dash is a real violation.
exclude_paths=(
  "plugins/documentation/skills/write-technical-docs/references/style-guide.md"
  "plugins/soul/instructions/general.instructions.md"
)

is_excluded() {
  local candidate="$1"
  for excluded in "${exclude_paths[@]}"; do
    [[ "$candidate" == "$excluded" ]] && return 0
  done
  return 1
}

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  mapfile -t files < <(git ls-files -- '*.md' '*.mdx' '*.txt')
fi

em_dash=$'\xe2\x80\x94' # U+2014, UTF-8 bytes

violations_file=$(mktemp)
trap 'rm -f "$violations_file"' EXIT

for file in "${files[@]}"; do
  [[ -z "$file" ]] && continue
  normalized="${file//\\//}"
  is_excluded "$normalized" && continue
  [[ -f "$file" ]] || continue
  grep -qF "$em_dash" "$file" 2>/dev/null || continue

  line_no=0
  while IFS= read -r line; do
    line_no=$((line_no + 1))
    rest="$line"
    offset=0
    while [[ "$rest" == *"$em_dash"* ]]; do
      prefix="${rest%%"$em_dash"*}"
      col=$((offset + ${#prefix} + 1))
      echo "$normalized:$line_no:$col" >> "$violations_file"
      rest="${rest#"$prefix""$em_dash"}"
      offset=$((col))
    done
  done < "$file"
done

count=$(wc -l < "$violations_file" | tr -d ' ')
if [[ "$count" -eq 0 ]]; then
  echo "No em dashes found in checked files."
  exit 0
fi

file_count=$(cut -d: -f1 "$violations_file" | sort -u | wc -l | tr -d ' ')
noun="em dashes"; [[ "$count" -eq 1 ]] && noun="em dash"
file_noun="files"; [[ "$file_count" -eq 1 ]] && file_noun="file"

echo "Found $count $noun in $file_count $file_noun."
echo "---"

in_ci=false
[[ "${GITHUB_ACTIONS:-}" == "true" ]] && in_ci=true

while IFS=: read -r file line col; do
  reason="Em dash (U+2014): rewrite using a colon, semicolon, or comma instead."
  if $in_ci; then
    echo "::error file=$file,line=$line,col=$col::$reason"
  fi
  echo "$file:$line:$col"
done < "$violations_file"

exit 1
