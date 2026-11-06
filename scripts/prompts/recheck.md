Re-score how well the candidate fits an existing job application.

The job description is in this file:
  {{JD_FILE}}

Use Read to load it. Do not write, edit or create any file.

Score the fit with these rules:
{{FIT_RULES}}

As your FINAL response, output exactly these four lines and nothing else (no
prose, no code fences):
  fit_score: <integer 1-10>
  fit_gaps: [<each missing blocking requirement as a double-quoted string, comma-separated, or nothing for an empty list>]
  fit_minor_gaps: [<each missing non-blocking requirement, in the same format>]
  fit_confidence: <high | medium | low>

Example final response (literal):
fit_score: 6
fit_gaps: ["Kubernetes", "5+ years of Go"]
fit_minor_gaps: ["GraphQL"]
fit_confidence: medium
