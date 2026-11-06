   Work in two passes, and keep your working notes to yourself.

   PASS 1: the job description only (do not look at source/ yet).
   - List the job's requirements. Mark each one:
     - blocking: stated as required or must-have, or a hard bar such as a
       minimum number of years, a licence or certification, a spoken
       language, work authorisation, or where the work must be done;
     - non-blocking: preferred, a plus, nice to have, or only implied by
       the stack, the tone or the company.
   - A requirement you inferred rather than read in the text is never
     blocking.
   - A fully remote job has no location requirement.

   PASS 2: match against source/.
   - Read every file in source/ (use Glob with the pattern source/*),
     including projects. Files named preferences.* are the candidate's
     rules, not evidence.
   - Mark each requirement covered (directly evidenced), adjacent (closely
     related real experience, such as a sibling framework or the same
     problem solved with another tool) or missing.
   - Location: covered when the job's place matches the candidate's
     location in profile.yaml, or a place listed under relocation there.
   - Work authorisation: if the job requires existing permission to work
     ("no sponsorship", "must already hold a work visa or permit") and
     profile.yaml says the candidate needs sponsorship for that place, it
     is missing. If profile.yaml says nothing, do not assume either way.

   SCORE (fit_score, an integer 1-10) from the blocking requirements, with
   these bands. Do not subtract points per missing item: judge the whole
   picture against the bands.
   - 9-10: every blocking requirement covered.
   - 7-8: every blocking requirement covered or adjacent, with at most one
     missing.
   - 4-6: roughly half of the blocking requirements covered.
   - 1-3: most blocking requirements missing, or a hard bar (years,
     licence, work authorisation) clearly not met.
   Non-blocking gaps can move the score by one point at most.
   If the job is built around a main programming language or framework
   (the one most of the work is done in) and source/ shows neither it nor
   a close sibling of it, the score is at most 4, however much else is
   covered.

   - fit_gaps: the blocking requirements that are missing, each named
     briefly and specifically (for example "5+ years of Go", not "backend
     experience").
   - fit_minor_gaps: the non-blocking requirements that are missing.
   - fit_confidence: how clear the evidence is, not the chance of getting
     the job. high = the job description is clear and complete; medium =
     some requirements are vague or ambiguous; low = the posting is thin,
     unclear or contradictory.
