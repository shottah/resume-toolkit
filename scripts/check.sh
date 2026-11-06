#!/usr/bin/env bash
# Warn about common problems in a generated .tex file after it is compiled.
#
#   scripts/check.sh <file.tex>
#
# Checks: the PDF runs past one page (read from tectonic's log in <dir>/out/),
# stock phrases from scripts/stock-phrases.txt that your source/ doesn't use,
# and numbers (percentages, money, multipliers, counts) that don't appear in
# source/. Each problem is one line on stderr starting with "warning: ".
# These are warnings only: the exit code is 0 unless the usage is wrong.

set -uo pipefail

TEX="${1:-}"
[ -n "$TEX" ] && [ -f "$TEX" ] || { echo "Usage: $(basename "$0") <file.tex>" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"

warn() { echo "warning: $TEX: $*" >&2; }

# ---- pages ------------------------------------------------------------------
LOG="$(dirname "$TEX")/out/$(basename "$TEX" .tex).log"
if [ -f "$LOG" ]; then
  pages="$(sed -n 's/.*Output written on .* (\([0-9][0-9]*\) pages\{0,1\}.*/\1/p' "$LOG" | head -1)"
  if [ -n "$pages" ] && [ "$pages" -gt 1 ]; then
    warn "runs to $pages pages (keep it to one)"
  fi
fi

[ -d source ] || exit 0

tmp="$(mktemp -d "${TMPDIR:-/tmp}/check.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# Your own words: every fact file in source/, lower case. preferences.* files
# are rules (they may list phrases to avoid), so they don't count.
find source -type f ! -name 'preferences.*' -exec cat {} + 2>/dev/null | tr '[:upper:]' '[:lower:]' > "$tmp/source"

# The document's text: LaTeX comments removed (an unescaped % starts one),
# escaped \% and \$ turned back into % and $, links dropped, lower case.
sed -e 's/^%.*//' -e 's/\([^\\]\)%.*/\1/' "$TEX" |
  sed -e 's/\\%/%/g' -e 's/\\\$/$/g' -e 's/\\href{[^}]*}//g' -e 's#https\{0,1\}://[^ }]*##g' |
  tr '[:upper:]' '[:lower:]' > "$tmp/text"

# ---- stock phrases ----------------------------------------------------------
while IFS= read -r phrase; do
  case "$phrase" in ''|'#'*) continue ;; esac
  if grep -qF -- "$phrase" "$tmp/text" && ! grep -qF -- "$phrase" "$tmp/source"; then
    warn "stock phrase \"$phrase\""
  fi
done < "$HERE/stock-phrases.txt"

# ---- numbers ----------------------------------------------------------------
# Candidates: money ($), percentages, multipliers (3x), k/m/b amounts, "10+",
# and plain counts of 2 or more followed by a word ("12 engineers"). Years
# (1900-2099) on their own, and years of experience ("7+ years"), which come
# from role dates rather than source/ text, are ignored.
grep -oE '\$?[0-9][0-9.,]*[%+xkmb]*( [a-z]+)?' "$tmp/text" | awk '
  {
    tok = $0; word = 0
    if (tok ~ / [a-z]+$/) {
      word = 1
      if (tok ~ / years?$/) next
      sub(/ [a-z]+$/, "", tok)
    }
    money = (substr(tok, 1, 1) == "$"); if (money) tok = substr(tok, 2)
    sub(/[.,]+$/, "", tok)
    num = tok; sub(/[%+xkmb]+$/, "", num); sub(/[.,]+$/, "", num)
    suffix = substr(tok, length(num) + 1)
    if (num == "") next
    if (!money && suffix == "") {
      if (!word || num + 0 < 2) next
      if (num ~ /^(19|20)[0-9][0-9]$/) next
    }
    if (!seen[tok]++) print tok
  }' | while IFS= read -r tok; do
  # Look for the same number in source/, not as part of a longer number.
  pattern="$(printf '%s' "$tok" | sed 's/[.]/\\./g; s/[+]/\\+/g')"
  if ! grep -qE "(^|[^0-9.])${pattern}([^0-9]|$)" "$tmp/source"; then
    warn "number \"$tok\" not found in source/"
  fi
done

exit 0
