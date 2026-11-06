#!/usr/bin/env bash
# Run the workflow for the Claude Code commands in .claude/commands/.
#
#   scripts/command.sh fit   <job link | job description file>
#   scripts/command.sh apply <job link | job description file | applications/ folder>
#
# Prints only a short summary. Everything else, including whatever the inner
# Claude says, goes to a log file, so text from a job description never reaches
# the interactive session that runs this script.

set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  echo "Usage: scripts/command.sh <fit|apply> <job link, job description file, or applications/ folder>"
  exit 2
}

ACTION="${1:-}"
TARGET="${2:-}"
case "$ACTION" in fit|apply) ;; *) usage ;; esac
[ -n "$TARGET" ] || usage

mkdir -p applications
LOG="applications/.last-run.log"
: > "$LOG"

fail() {
  echo "error: $1 failed — see $LOG"
  exit 1
}

if [ -d "$TARGET" ] && [ -f "$TARGET/notes.md" ]; then
  DIR="${TARGET%/}"
else
  DIR="$(scripts/scaffold.sh "$TARGET" 2>>"$LOG")" || fail "the fit check"
fi

# From here on, keep the log with the application.
cat "$LOG" >> "$DIR/run.log"
rm -f "$LOG"
LOG="$DIR/run.log"

if [ "$ACTION" = apply ]; then
  make --no-print-directory resume DIR="$DIR" >>"$LOG" 2>&1 || fail "writing the resume"
  make --no-print-directory cover-letter DIR="$DIR" >>"$LOG" 2>&1 || fail "writing the cover letter"
fi

field() { # first value of a notes.md frontmatter key, kept short
  sed -n "s/^$1: *//p" "$DIR/notes.md" | head -1 | sed -e 's/^"\(.*\)"$/\1/' | cut -c1-300
}

echo "folder: $DIR"
echo "company: $(field company)"
echo "role: $(field role)"
echo "fit_score: $(field fit_score)"
echo "fit_gaps: $(field fit_gaps)"
FIT="$(field fit_score)"
if [[ "$FIT" =~ ^[0-9]+$ ]] && [ "$FIT" -lt 7 ]; then
  echo "note: fit is below 7 — see 'Fit gate' in CLAUDE.md before investing time"
fi
if [ "$ACTION" = apply ]; then
  echo "resume: $DIR/out/resume.pdf"
  echo "cover_letter: $DIR/out/cover-letter.pdf"
fi
echo "log: $LOG"
