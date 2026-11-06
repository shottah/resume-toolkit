You are tailoring a {{KIND_NOUN}} for a specific job application.

REQUIRED READING (in this order):
  1. CLAUDE.md — project conventions, especially the "Tailoring rules" section.
  2. Read every file in source/ (use Glob with the pattern source/*). The
     profile, experience, education, skills and projects files are the single
     source of truth for facts. Any other file there holds facts too, except
     files named preferences.* (such as preferences.yaml), which hold the
     candidate's own rules for how to present those facts.
  3. {{TEMPLATE}} — the structural LaTeX template. Follow its preamble and layout.
  4. {{JD_INSTRUCTION}}

TASK:
Write a tailored, one-page LaTeX {{KIND_NOUN}} to:
  {{OUTPUT}}

RULES:
  - Output MUST be valid LaTeX that compiles with tectonic (no extra packages
    beyond what {{TEMPLATE}} already loads).
  - Result MUST fit on ONE page.
  - ATS-friendly: single column, no graphics, no color, standard fonts.
  - Facts come only from source/. Do not invent facts.
  - source/preferences.* files are rules, not facts: follow them, but never
    quote them or present them as experience.
  - Select the most relevant highlights and reorder/emphasize skills to match the JD.
  - Do NOT modify any file under source/ or templates/. Only write {{OUTPUT}}
    (and {{JD_CACHE}} if the JD source was a URL).
  - When the output file is written, exit. Do not attempt to compile or run make.
