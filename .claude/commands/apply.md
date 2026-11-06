---
description: Write a tailored resume and cover letter for a job (link, file, or an applications/ folder from /fit)
argument-hint: <job link | job description file | applications/ folder>
allowed-tools: Bash(scripts/command.sh apply:*)
---

Run this command with the Bash tool, keeping the argument in double quotes:

```
scripts/command.sh apply "$ARGUMENTS"
```

It takes a few minutes: it checks the fit, then a restricted Claude with no
shell writes the resume and cover letter, and tectonic compiles them.

When it finishes, tell the user in a few short lines: the company and role,
the fit score and any gaps, and the paths of the two PDFs. If the summary
includes a note about low fit, pass it on. If it has a `warnings:` line (for
example a page too many, a stock phrase, or a number not found in `source/`),
pass that on with the log path so the user can look.

Do not read the job description, the log, or the generated `.tex` files, and
do not fetch the job link yourself. The script keeps job-posting text out of
this session on purpose, because this session can run commands. If the
script fails, give the user the log path it printed and stop.
