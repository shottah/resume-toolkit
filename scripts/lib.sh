# Shared helpers for scripts/tailor.sh and scripts/scaffold.sh.
# Plain bash (works with macOS bash 3.2); source it, don't run it.

# render_prompt <template-file> NAME=VALUE...
# Print the template with every {{NAME}} replaced by VALUE, copied literally
# (characters such as & \ $ {{ and spaces in VALUE are kept as they are).
# The template is read once from left to right, so values are never re-read.
# Fails if the template uses a {{NAME}} that was not given.
render_prompt() {
  local template="$1"; shift
  local text out="" rest name value pair found
  text="$(cat "$template")" || return 1
  while [[ "$text" == *"{{"* ]]; do
    out="$out${text%%"{{"*}"
    rest="${text#*"{{"}"
    name="${rest%%"}}"*}"
    if [[ "$rest" != *"}}"* || ! "$name" =~ ^[A-Z_]+$ ]]; then
      out="$out{{"            # not a placeholder: keep the braces as text
      text="$rest"
      continue
    fi
    found=""
    for pair in "$@"; do
      if [ "${pair%%=*}" = "$name" ]; then value="${pair#*=}"; found=1; break; fi
    done
    if [ -z "$found" ]; then
      echo "error: unfilled placeholder {{$name}} in $template" >&2
      return 1
    fi
    out="$out$value"
    text="${rest#*"}}"}"
  done
  printf '%s\n' "$out$text"
}

# ensure_source
# On first run, when there is no source/ folder yet, copy the example profile
# from example/source/ so everything works straight away. An existing source/
# is never touched, even if it is empty or missing files.
ensure_source() {
  [ -e source ] && return 0
  local tmp="source.tmp.$$"
  if mkdir "$tmp" 2>/dev/null &&
     cp -R example/source/. "$tmp"/ 2>/dev/null &&
     { [ ! -e source ] || { rm -rf "$tmp"; return 0; }; } &&
     mv "$tmp" source 2>/dev/null; then
    echo "==> Using the example profile — edit source/*.yaml to make it yours." >&2
    return 0
  fi
  rm -rf "$tmp" 2>/dev/null
  echo "error: could not create source/ from example/source/ (is the folder writable?)" >&2
  exit 1
}

# resume_pages
# Print the page length set for resumes: 2 when source/preferences.yaml (or
# .yml) has the line "resume_pages: 2", otherwise 1. Cover letters are always 1.
resume_pages() {
  if grep -qsE '^resume_pages:[[:space:]]*2[[:space:]]*(#.*)?$' source/preferences.yaml source/preferences.yml; then
    echo 2
  else
    echo 1
  fi
}

# page_limit <file.tex>
# Print how many pages a document may have: resume_pages for resume.tex,
# otherwise 1.
page_limit() {
  if [ "$(basename "$1")" = resume.tex ]; then resume_pages; else echo 1; fi
}

# pdf_pages <file.tex>
# Print the page count of the last build, read from tectonic's log in
# <dir>/out/<name>.log (written with --keep-logs). Prints nothing if unknown.
pdf_pages() {
  local log
  log="$(dirname "$1")/out/$(basename "$1" .tex).log"
  [ -f "$log" ] || return 0
  sed -n 's/.*Output written on .* (\([0-9][0-9]*\) pages\{0,1\}.*/\1/p' "$log" | head -1
}

# page_lines <file.tex> <page>
# Print how many lines of text that page of the built PDF has. Needs pdftotext
# (or $PDFTOTEXT); prints nothing when it isn't installed.
page_lines() {
  local pdf tool="${PDFTOTEXT:-pdftotext}"
  pdf="$(dirname "$1")/out/$(basename "$1" .tex).pdf"
  [ -f "$pdf" ] && command -v "$tool" >/dev/null 2>&1 || return 0
  "$tool" -f "$2" -l "$2" -layout "$pdf" - 2>/dev/null | grep -c '[^[:space:]]' || true
}

# fit_gate_warning <notes.md>
# Warn on stderr when the fit score is below 7 (see "Fit gate" in CLAUDE.md).
fit_gate_warning() {
  local fit
  fit="$(sed -n 's/^fit_score: *//p' "$1" | head -1)"
  if [ -n "$fit" ] && ! [[ "$fit" =~ ^[0-9]+$ ]]; then
    echo "==> WARNING: fit_score is not a plain integer ('$fit') — fit gate cannot evaluate it" >&2
  elif [ -n "$fit" ] && [ "$fit" -lt 7 ]; then
    echo "==> WARNING: fit_score=$fit (<7). Gaps: $(sed -n 's/^fit_gaps: *//p' "$1")" >&2
    echo "==> Low-fit application — see CLAUDE.md 'Fit gate' before investing time." >&2
  fi
}
