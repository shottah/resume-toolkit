#!/usr/bin/env bash
# Compile a tailored .tex file and, if it doesn't fit its page limit, have
# Claude adjust its length and compile again (at most two tries).
#
#   scripts/fit-length.sh <application-dir>/<resume|cover-letter>.tex
#
# The limit is one page, or two for a resume when source/preferences.yaml has
# "resume_pages: 2". A two-page resume whose second page has less than half as
# much text as the first also counts as not fitting (only measurable when
# pdftotext is installed). Claude gets Read, Edit, Glob and Grep: no shell, no
# web, and it can only change the .tex file. Whatever still doesn't fit is left
# for scripts/check.sh to warn about.

set -euo pipefail

source "$(dirname "$0")/lib.sh"

TEX="${1:-}"
[ -n "$TEX" ] && [ -f "$TEX" ] || { echo "Usage: $(basename "$0") <file.tex>" >&2; exit 2; }
OUT="$(dirname "$TEX")/out"
case "$(basename "$TEX")" in
  resume.tex) KIND_NOUN="resume" ;;
  cover-letter.tex) KIND_NOUN="cover letter" ;;
  *) KIND_NOUN="document" ;;
esac
LIMIT="$(page_limit "$TEX")"
if [ "$LIMIT" = 1 ]; then LIMIT_TEXT="1 page"; else LIMIT_TEXT="$LIMIT pages"; fi

SHORTEN="To shorten it, work through these in order and stop as soon as it should fit:
  1. Tighten the summary to at most three lines.
  2. Merge roles at the same company into one entry (for example \"Senior
     Engineer, promoted from Engineer\").
  3. Put each education entry and each skills group on one line, and drop
     skills this job doesn't ask for.
  4. Only then remove the least relevant bullets, starting with the oldest
     roles. Keep at least 3 bullets for every current role (end: present in
     source/experience.yaml), and never drop a role entirely."
FILL="To fix it, either add more of the candidate's real highlights from source/
that this job would value and the file leaves out, starting with current
roles, until page 2 is at least half full; or, if source/ has nothing more
worth saying, cut it to one page using this order: tighten the summary, merge
roles at the same company, put education and skills on single lines, then
remove the least relevant bullets. Never pad: no longer bullets, repeated
claims or filler."

compile() {
  mkdir -p "$OUT"
  "${TECTONIC:-tectonic}" --keep-logs -o "$OUT" "$TEX"
}

compile
for try in 1 2; do
  pages="$(pdf_pages "$TEX")"
  [ -n "$pages" ] || exit 0  # no page count in the log: nothing to measure
  DETAIL=""
  if [ "$pages" -gt "$LIMIT" ]; then
    last="$(page_lines "$TEX" "$pages")"
    DETAIL="It compiled to $pages pages; the limit is $LIMIT_TEXT."
    if [ -n "$last" ]; then
      DETAIL="$DETAIL Page $pages has $last lines of text, so cut at least that much, plus a line or two to spare."
    else
      DETAIL="$DETAIL Cut enough to remove page $pages entirely."
    fi
    GOAL_RULES="$SHORTEN"
  elif [ "$LIMIT" = 2 ] && [ "$pages" = 2 ]; then
    p1="$(page_lines "$TEX" 1)"; p2="$(page_lines "$TEX" 2)"
    if [ -n "$p1" ] && [ -n "$p2" ] && [ "$p1" -gt 0 ] && [ $((p2 * 2)) -lt "$p1" ]; then
      DETAIL="It compiled to 2 pages. Page 2 has only $p2 lines of text against $p1 on page 1, so it looks like overflow."
      GOAL_RULES="$FILL"
    fi
  fi
  [ -n "$DETAIL" ] || exit 0

  PROMPT=$(render_prompt "$(dirname "$0")/prompts/fit-length.md" \
    "KIND_NOUN=${KIND_NOUN}" "FILE=${TEX}" "DETAIL=${DETAIL}" "GOAL_RULES=${GOAL_RULES}")
  echo "==> claude -p: fitting the ${KIND_NOUN} to ${LIMIT_TEXT} (try ${try} of 2)"
  "${CLAUDE:-claude}" -p "$PROMPT" \
    --tools Read,Edit,Glob,Grep \
    --permission-mode bypassPermissions
  compile
done
