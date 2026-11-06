#!/usr/bin/env bash
# Spawn `claude -p` to generate a tailored resume or cover letter.
# Writes the result to <DIR>/resume.tex or <DIR>/cover-letter.tex.
# Does NOT compile — the caller (Makefile) chains `make pdf`.
#
# The job description source can be:
#   - omitted: defaults to <DIR>/job-description.md
#   - a file path: any readable .md file
#   - an http(s):// URL: claude fetches via WebFetch and caches it to
#     <DIR>/job-description.md for future runs.

set -euo pipefail

source "$(dirname "$0")/lib.sh"

usage() {
  echo "Usage: $(basename "$0") <resume|cover-letter> <application-dir> [jd-path-or-url]" >&2
  exit 1
}

KIND="${1:-}"
DIR="${2:-}"
JD_INPUT="${3:-}"

[ -n "$KIND" ] && [ -n "$DIR" ] || usage

case "$KIND" in
  resume)
    OUTPUT="$DIR/resume.tex"
    TEMPLATE="templates/resume.tex"
    KIND_NOUN="resume"
    KIND_RULES_FILE="rules-resume.md"
    ;;
  cover-letter)
    OUTPUT="$DIR/cover-letter.tex"
    TEMPLATE="templates/cover-letter.tex"
    KIND_NOUN="cover letter"
    KIND_RULES_FILE="rules-cover-letter.md"
    ;;
  *)
    echo "error: unknown kind '$KIND' (expected: resume | cover-letter)" >&2
    usage
    ;;
esac

[ -d "$DIR" ]      || { echo "error: directory not found: $DIR" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "error: missing $TEMPLATE" >&2; exit 1; }

ensure_source

# Resolve job description source: explicit arg > existing JD file in DIR.
if [ -z "$JD_INPUT" ]; then
  JD_INPUT="$DIR/job-description.md"
fi

JD_CACHE="$DIR/job-description.md"

if [[ "$JD_INPUT" =~ ^https?:// ]]; then
  JD_KIND="url"
  JD_INSTRUCTION="The job description is at this URL:
  ${JD_INPUT}

Use WebFetch to retrieve it. After fetching, write the markdown content to:
  ${JD_CACHE}
(overwrite if it exists). Prefix the file with an HTML comment recording the
source URL, e.g.:
  <!-- source: ${JD_INPUT} -->
This caches the JD so future runs can re-tailor without re-fetching."
elif [ -f "$JD_INPUT" ]; then
  JD_KIND="file"
  JD_INSTRUCTION="The job description is in this file:
  ${JD_INPUT}

Use Read to load it."
else
  echo "error: job description not found: $JD_INPUT" >&2
  echo "       provide a readable file path or an http(s):// URL," >&2
  echo "       or create $DIR/job-description.md" >&2
  exit 1
fi

if [ "$KIND" = resume ] && [ "$(resume_pages)" = 2 ]; then
  PAGE_RULE="  - The resume runs to two full pages: aim for 1.5 to 2 pages, and never
    leave page 2 nearly empty. Page 1 must stand on its own: the summary and
    the roles most relevant to this job. Older or less relevant roles,
    education and skills can go on page 2. Use the extra space for more of
    the candidate's real highlights, especially in current roles, never for
    padding, longer bullets or repeated claims."
else
  PAGE_RULE="  - Result MUST fit on ONE page."
fi

PROMPT=$(render_prompt "$(dirname "$0")/prompts/tailor.md" \
  "PAGE_RULE=${PAGE_RULE}" \
  "JD_CACHE=${JD_CACHE}" \
  "JD_INSTRUCTION=${JD_INSTRUCTION}" \
  "KIND_NOUN=${KIND_NOUN}" \
  "KIND_RULES=$(cat "$(dirname "$0")/prompts/${KIND_RULES_FILE}")" \
  "OUTPUT=${OUTPUT}" \
  "TEMPLATE=${TEMPLATE}")

echo "==> claude -p: tailoring ${KIND_NOUN} (JD source: ${JD_KIND}) -> ${OUTPUT}"
"${CLAUDE:-claude}" -p "$PROMPT" \
  --tools Read,Write,Edit,WebFetch,Glob,Grep \
  --permission-mode bypassPermissions

[ -f "$OUTPUT" ] || { echo "error: claude did not produce ${OUTPUT}" >&2; exit 1; }
echo "==> wrote ${OUTPUT}"
