#!/usr/bin/env bash
# Re-score an existing application against your current source/.
#
#   scripts/recheck.sh <application-folder>
#
# Updates only the fit lines in <folder>/notes.md: fit_score, fit_gaps,
# fit_minor_gaps and fit_confidence (the last two are added after fit_gaps when
# an older notes.md lacks them). The stage, your notes, contacts and any built
# documents are left alone. Claude gets read-only tools, so it cannot change
# any file itself.
#
# Stdout: the four new lines. Stderr: progress and warnings.

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

CLEAN=$(printf '%s\n' "$REPLY" | tr -d '\r')
SCORE_LINE=$(printf '%s\n' "$CLEAN" | grep -E '^fit_score: *([1-9]|10) *$' | head -1 || true)
GAPS_LINE=$(printf '%s\n' "$CLEAN" | grep -E '^fit_gaps: *\[.*\] *$' | head -1 || true)
MINOR_LINE=$(printf '%s\n' "$CLEAN" | grep -E '^fit_minor_gaps: *\[.*\] *$' | head -1 || true)
CONFIDENCE=$(printf '%s\n' "$CLEAN" | grep -iE '^fit_confidence: *(high|medium|low) *$' | head -1 |
  sed 's/^[^:]*: *//; s/ *$//' | tr '[:upper:]' '[:lower:]' || true)
if [ -z "$SCORE_LINE" ] || [ -z "$GAPS_LINE" ] || [ -z "$MINOR_LINE" ] || [ -z "$CONFIDENCE" ]; then
  echo "error: unexpected reply from claude; ${NOTES} was not changed" >&2
  exit 1
fi
CONF_LINE="fit_confidence: $CONFIDENCE"

# Replace the fit lines inside the frontmatter only. Missing minor-gaps and
# confidence lines go right after fit_gaps; anything else missing goes before
# the closing ---. The file is swapped in so a failure never leaves it half-written.
tmp="${NOTES}.tmp.$$"
S="$SCORE_LINE" G="$GAPS_LINE" M="$MINOR_LINE" C="$CONF_LINE" awk '
  NR == 1 && $0 == "---"     { fm = 1; print; next }
  fm && $0 == "---"          {
                               if (!s) print ENVIRON["S"]; if (!g) print ENVIRON["G"]
                               if (!m) print ENVIRON["M"]; if (!c) print ENVIRON["C"]
                               fm = 0; print; next
                             }
  fm && /^fit_score:/        { print ENVIRON["S"]; s = 1; next }
  fm && /^fit_gaps:/         {
                               print ENVIRON["G"]; g = 1
                               if (!m) { print ENVIRON["M"]; m = 1 }
                               if (!c) { print ENVIRON["C"]; c = 1 }
                               next
                             }
  fm && /^fit_minor_gaps:/   { if (!m) print ENVIRON["M"]; m = 1; next }
  fm && /^fit_confidence:/   { if (!c) print ENVIRON["C"]; c = 1; next }
                             { print }
' "$NOTES" > "$tmp" && mv "$tmp" "$NOTES"

printf '%s\n%s\n%s\n%s\n' "$SCORE_LINE" "$GAPS_LINE" "$MINOR_LINE" "$CONF_LINE"
fit_gate_warning "$NOTES"
