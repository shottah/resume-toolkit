Scaffold a new job application directory from this job description.

JD source:
  {{JD_FETCH}}

STEPS (use tool calls, in order):

1. Load the JD content using the tool above.

2. From the JD, identify:
   - COMPANY: the hiring company (e.g. "Acme Corp", "Globex", "Initech").
   - ROLE:    a short kebab-case role title (e.g. "backend-engineer",
              "product-designer", "senior-data-analyst").

3. Compute the directory path:
     applications/{{DATE_MONTH}}-<company-kebab>-<role-kebab>

   Use lowercase kebab-case. Examples:
     ("Acme Corp", "Backend Engineer") -> applications/{{DATE_MONTH}}-acme-corp-backend-engineer
     ("Globex", "Product Designer")    -> applications/{{DATE_MONTH}}-globex-product-designer

4. Write the JD content to <DIR>/job-description.md.
   - If JD came from a URL, prefix the file with:
       <!-- source: {{JD_INPUT}} -->
     followed by a blank line, then the JD markdown body.
   - If JD came from a file, just write the JD body.

5. Score candidate fit BEFORE writing notes.md:
{{FIT_RULES}}

6. Write <DIR>/notes.md with this exact frontmatter (only the placeholder
   values inside <...> change):
     ---
     stage: fit_checked
     outcome: open
     applied_date: ""
     company: "<company name>"
     role: "<role title>"
     url: "{{URL_FIELD}}"
     contacts: []
     fit_score: <integer 1-10>
     fit_gaps: [<unmet must-haves, or empty list>]
     ---

     ## Notes

7. As your FINAL assistant response (after all tool calls), output ONLY the
   directory path. No quotes. No prose. No code fences. No trailing
   punctuation. Example final response (literal):
     applications/{{DATE_MONTH}}-acme-corp-backend-engineer

CONSTRAINTS:
- Do NOT modify source/ or templates/.
- Do NOT generate any .tex files.
- Your final text response must be EXACTLY the directory path.
