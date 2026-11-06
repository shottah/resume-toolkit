---
description: Check how well a job fits your experience (or re-check an applications/ folder), without writing any documents
argument-hint: <job link | job description file | applications/ folder>
allowed-tools: Bash(scripts/command.sh fit:*)
---

Run this command with the Bash tool, keeping the argument in double quotes:

```
scripts/command.sh fit "$ARGUMENTS"
```

A restricted Claude with no shell reads the job description and scores it
against `source/` from 1 to 10. For a job link or file it creates the
application folder; for an existing `applications/` folder it re-checks the
fit and updates only the fit lines.

When it finishes, tell the user in a few short lines: the company and role,
the fit score and its confidence, the blocking gaps, and the nice-to-have
gaps if there are any. If the score is 7 or higher, suggest
`/apply <folder>` with the folder it printed. If the summary includes a note
about low fit, pass it on and suggest they only go ahead if they can name
what bridges the gap.

Do not read the job description or the log, and do not fetch the job link
yourself. The script keeps job-posting text out of this session on purpose,
because this session can run commands. If the script fails, give the user
the log path it printed and stop.
