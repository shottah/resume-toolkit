# Resume Toolkit — Claude Conventions

This repo is a Claude-driven resume and cover letter pipeline. The Makefile
runs `claude -p` as a subprocess to write tailored LaTeX from a single source
of truth, then compiles it to PDF with tectonic.

## Project structure

- `source/` — your own YAML files: the **single source of truth** for all
  professional data. Git-ignored, so it is never published. On the first run
  it is created as a copy of `example/source/`.
  - `profile.yaml`     — name, contact details, summary, optional `relocation`
    places (each with `place`, optional `when` and `work_authorization`)
  - `experience.yaml`  — work history with highlights and tags
  - `education.yaml`   — degrees and courses
  - `skills.yaml`      — skill groupings
  - `projects.yaml`    — notable projects
  - any other file (for example `certifications.yaml`) — more facts
  - `preferences.yaml` — your own rules for how to present your experience;
    read as rules, never as facts
- `.claude/commands/` — the `/fit` and `/apply` commands for Claude Code. They
  only run `scripts/command.sh`; they never read job postings, logs or
  generated `.tex` files themselves.
- `example/` — a made-up example person (`example/source/`) and a sample job
  description, so the tool works on a fresh clone.
- `templates/` — structural LaTeX templates (preamble and layout). Claude reads
  them to mirror the styling; they are never modified when tailoring.
  - `resume.tex`
  - `cover-letter.tex`
- `applications/YYYY-MM-company-role/` — one folder per application.
  Git-ignored.
  - `job-description.md` — the job description (written by `scripts/scaffold.sh` or by hand)
  - `notes.md`           — YAML frontmatter and free-form notes
  - `resume.tex`         — written by Claude, tailored to this job
  - `cover-letter.tex`   — written by Claude, tailored to this job
  - `out/`               — compiled PDFs
- `scripts/` — the workflow scripts.
  - `scaffold.sh`  — creates the application folder from a job description and scores the fit
  - `tailor.sh`    — runs `claude -p` to write a tailored resume or cover letter
  - `recheck.sh`   — re-scores an existing application; updates only the four `fit_*` lines
  - `check.sh`     — after each PDF build, warns about extra pages, stock phrases
    (`stock-phrases.txt`) and numbers not found in `source/`; never fails the build
  - `command.sh`   — runs `fit` or `apply` for the Claude Code commands and prints only a summary
  - `lib.sh`       — shared helpers (prompt rendering, first-run setup)
  - `prompts/`     — the instructions sent to Claude; edit these to change its behavior
    (`rules-resume.md` and `rules-cover-letter.md` hold the rules for one document only)
    (`fit-rules.md` holds the scoring rules shared by the first check and re-checks)
- `docs/images/` — README images, made from a real run on the example profile.
- `tests/` — script tests (`make test`); they use a fake `claude`, so they
  need neither Claude nor tectonic.

## Commands

```
make application JD=<path-or-url>                      # full flow
make resume       DIR=<app-dir> [JD=<path-or-url>]     # re-tailor the resume only
make cover-letter DIR=<app-dir> [JD=<path-or-url>]     # re-tailor the cover letter only
make fit          DIR=<app-dir>                        # re-check the fit against the current source/
make pdf          TEX=<file.tex>                       # compile one .tex file
make test                                              # run the script tests
```

`make help` prints the same. `JD=` accepts either a local markdown file or an
`http(s)://` URL; URLs are fetched with `WebFetch` and cached to
`<DIR>/job-description.md`.

## How tailoring works

1. The user runs, for example, `make application JD=<jd>`.
2. The Makefile calls `scripts/scaffold.sh` (for `application`) and
   `scripts/tailor.sh` (for `resume` and `cover-letter`).
3. Each script renders its prompt from `scripts/prompts/` and runs `claude -p`
   with a restricted toolset: `Read, Write, Edit, WebFetch, Glob, Grep`.
   There is **no Bash**, so prompt injection from a hostile job description
   cannot run shell commands.
4. Inside that session, Claude reads `CLAUDE.md`, every file in `source/`, the
   relevant `templates/*.tex` and the job description, then writes the
   tailored `.tex` file in the application folder.
5. The Makefile then runs `make pdf TEX=...` to compile it with tectonic into
   `<DIR>/out/`.

## Tailoring rules

- **Never modify `source/` when tailoring.** Only write files inside the
  application folder.
- **Never modify `templates/`.** They are structural references only.
- Read every file in `source/` before tailoring.
- Facts come only from `source/` — never invent them, and never promise
  availability, relocation, work arrangements, salary or visa status that
  `source/` doesn't state. `source/preferences.*`
  files are rules to follow, not facts to quote.
- Bullet points lead with a strong past-tense verb and include metrics where
  possible.
- Prioritize relevance to the job description over recency.
- The resume and the cover letter each fit on **one page**.
- ATS-friendly: single column, no graphics, no color, standard fonts.

## Conventions

### YAML
- Dates use `YYYY-MM` for roles and `YYYY` for education and projects.
- `end: present` for current roles.
- Tags are free-form strings for filtering (for example `backend`,
  `leadership`, `ml`).

### LaTeX
- All templates compile with `tectonic`, with no extra dependencies.
- No `.cls` files — all styling lives in the `.tex` preamble.
- Stay within the packages each template already loads.

### Application notes.md format
```yaml
---
stage: saved | fit_checked | tailoring | ready | applied | interviewing | offer
outcome: open | accepted | declined | rejected | withdrawn | ghosted
applied_date: YYYY-MM-DD or ""
company: ""
role: ""
url: ""
contacts: []
fit_score: 1-10        # written by scaffold.sh, updated by recheck.sh
fit_gaps: []           # blocking requirements not evidenced in source/
fit_minor_gaps: []     # nice-to-have requirements not evidenced in source/
fit_confidence: high | medium | low   # how clear the job description is
---
```
Free-form notes go below the frontmatter.

## Fit gate

`scaffold.sh` scores each job description against `source/` and warns when
`fit_score` is below 7. `make fit DIR=<app-dir>` (or `/fit <app-dir>`) re-scores
an existing application with the same rules after `source/` changes. Only go ahead with a low-fit application when you can
name what bridges the gap (a related domain, a referral, a transferable
project) and say so in the cover letter. Otherwise, strengthen `source/` with
real experience you left out, or skip the role.
