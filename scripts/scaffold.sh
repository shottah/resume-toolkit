#!/usr/bin/env bash
# Scaffold a new application directory from a job description.
# Uses Claude to identify company + role from the JD, creates
# applications/YYYY-MM-<slug>/, persists the JD to <DIR>/job-description.md,
# and creates <DIR>/notes.md.
#
# Stdout:  the resolved DIR path, and nothing else (caller-consumable).
# Stderr:  progress + error messages.

set -euo pipefail

source "$(dirname "$0")/lib.sh"

JD_INPUT="${1:-}"
[ -n "$JD_INPUT" ] || { echo "Usage: $(basename "$0") <jd-path-or-url>" >&2; exit 1; }

ensure_source

if [[ "$JD_INPUT" =~ ^https?:// ]]; then
  JD_KIND="url"
  JD_FETCH="Use WebFetch to retrieve the JD from this URL: ${JD_INPUT}"
  URL_FIELD="$JD_INPUT"
elif [ -f "$JD_INPUT" ]; then
  JD_KIND="file"
  JD_FETCH="Use Read to load the JD from this file: ${JD_INPUT}"
  URL_FIELD=""
else
  echo "error: JD not found: $JD_INPUT" >&2
  echo "       provide a readable file path or an http(s):// URL" >&2
  exit 1
fi

DATE_MONTH=$(date +%Y-%m)

PROMPT=$(render_prompt "$(dirname "$0")/prompts/scaffold.md" \
  "DATE_MONTH=${DATE_MONTH}" \
  "JD_FETCH=${JD_FETCH}" \
  "JD_INPUT=${JD_INPUT}" \
  "URL_FIELD=${URL_FIELD}")

echo "==> claude -p: scaffolding application from JD (${JD_KIND})..." >&2

DIR=$("${CLAUDE:-claude}" -p "$PROMPT" \
  --tools Read,Write,Edit,WebFetch,Glob,Grep \
  --permission-mode bypassPermissions)

# Strip newlines / CRs claude may include around the path.
DIR="${DIR//$'\n'/}"
DIR="${DIR//$'\r'/}"
DIR="${DIR## }"
DIR="${DIR%% }"

[ -n "$DIR" ]                       || { echo "error: scaffold did not return a DIR" >&2; exit 1; }
[ -d "$DIR" ]                       || { echo "error: scaffolded DIR does not exist: $DIR" >&2; exit 1; }
[ -f "$DIR/job-description.md" ]    || { echo "error: missing $DIR/job-description.md" >&2; exit 1; }
[ -f "$DIR/notes.md" ]              || { echo "error: missing $DIR/notes.md" >&2; exit 1; }

FIT=$(sed -n 's/^fit_score: *//p' "$DIR/notes.md" | head -1)
if [ -n "$FIT" ] && ! [[ "$FIT" =~ ^[0-9]+$ ]]; then
  echo "==> WARNING: fit_score is not a plain integer ('$FIT') — fit gate cannot evaluate it" >&2
elif [ -n "$FIT" ] && [ "$FIT" -lt 7 ]; then
  echo "==> WARNING: fit_score=$FIT (<7). Gaps: $(sed -n 's/^fit_gaps: *//p' "$DIR/notes.md")" >&2
  echo "==> Low-fit application — see CLAUDE.md 'Fit gate' before investing time." >&2
fi

echo "==> scaffolded: $DIR" >&2
echo "$DIR"
