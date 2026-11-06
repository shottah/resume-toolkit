#!/usr/bin/env bash
# Re-score an existing application against your current source/.
#
#   scripts/recheck.sh <application-folder>
#
# Updates only the fit_score and fit_gaps lines in <folder>/notes.md. The stage,
# your notes, contacts and any built documents are left alone. Claude gets
# read-only tools, so it cannot change any file itself.
#
# Stdout: the two new lines (fit_score and fit_gaps). Stderr: progress and warnings.

set -euo pipefail

source "$(dirname "$0")/lib.sh"

DIR="${1:-}"
[ -n "$DIR" ] || { echo "Usage: $(basename "$0") <application-folder>" >&2; exit 1; }
DIR="${DIR%/}"
NOTES="$DIR/notes.md"
JD="$DIR/job-description.md"

if [ ! -f "$NOTES" ] || [ ! -f "$JD" ] || [ "$(head -1 "$NOTES")" != "---" ]; then
  echo "error: $DIR is not an application folder (it needs job-description.md and a notes.md with frontmatter)" >&2
  exit 1
fi

ensure_source

PROMPT=$(render_prompt "$(dirname "$0")/prompts/recheck.md" \
  "JD_FILE=${JD}" \
  "FIT_RULES=$(cat "$(dirname "$0")/prompts/fit-rules.md")")

echo "==> claude -p: re-checking fit for ${DIR}..." >&2
REPLY=$("${CLAUDE:-claude}" -p "$PROMPT" \
  --tools Read,Glob,Grep \
  --permission-mode bypassPermissions)

SCORE_LINE=$(printf '%s\n' "$REPLY" | tr -d '\r' | grep -E '^fit_score: *([1-9]|10) *$' | head -1 || true)
GAPS_LINE=$(printf '%s\n' "$REPLY" | tr -d '\r' | grep -E '^fit_gaps: *\[.*\] *$' | head -1 || true)
if [ -z "$SCORE_LINE" ] || [ -z "$GAPS_LINE" ]; then
  echo "error: unexpected reply from claude; ${NOTES} was not changed" >&2
  exit 1
fi

# Replace the two lines inside the frontmatter only (adding them if missing),
# then swap the file in so a failure never leaves it half-written.
tmp="${NOTES}.tmp.$$"
S="$SCORE_LINE" G="$GAPS_LINE" awk '
  NR == 1 && $0 == "---" { fm = 1; print; next }
  fm && $0 == "---"      { if (!s) print ENVIRON["S"]; if (!g) print ENVIRON["G"]; fm = 0; print; next }
  fm && /^fit_score:/    { print ENVIRON["S"]; s = 1; next }
  fm && /^fit_gaps:/     { print ENVIRON["G"]; g = 1; next }
                         { print }
' "$NOTES" > "$tmp" && mv "$tmp" "$NOTES"

printf '%s\n%s\n' "$SCORE_LINE" "$GAPS_LINE"
fit_gate_warning "$NOTES"
