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
