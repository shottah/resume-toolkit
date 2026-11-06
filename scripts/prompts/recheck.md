Re-score how well the candidate fits an existing job application.

The job description is in this file:
  {{JD_FILE}}

Use Read to load it. Do not write, edit or create any file.

Score the fit with these rules:
{{FIT_RULES}}

As your FINAL response, output exactly these two lines and nothing else (no
prose, no code fences):
  fit_score: <integer 1-10>
  fit_gaps: [<each unmet must-have as a double-quoted string, comma-separated, or nothing for an empty list>]

Example final response (literal):
fit_score: 6
fit_gaps: ["Kubernetes", "5+ years of Go"]
