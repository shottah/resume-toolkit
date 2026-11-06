TECTONIC ?= tectonic
CLAUDE   ?= claude
export CLAUDE

.DEFAULT_GOAL := help

.PHONY: resume cover-letter application fit pdf test check-deps help

# ===== Public workflow =====

# Generate a tailored resume.tex via Claude, then compile to PDF.
#   make resume DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]
resume: check-deps
	@test -n "$(DIR)" || { echo "Usage: make resume DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]"; exit 1; }
	@./scripts/tailor.sh resume "$(DIR)" "$(JD)"
	@$(MAKE) --no-print-directory pdf TEX="$(DIR)/resume.tex"

# Generate a tailored cover-letter.tex via Claude, then compile to PDF.
#   make cover-letter DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]
cover-letter: check-deps
	@test -n "$(DIR)" || { echo "Usage: make cover-letter DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]"; exit 1; }
	@./scripts/tailor.sh cover-letter "$(DIR)" "$(JD)"
	@$(MAKE) --no-print-directory pdf TEX="$(DIR)/cover-letter.tex"

# Full application: scaffold a DIR from a JD, then tailor + compile both.
#   make application JD=<path-or-url>
# Claude derives company + role from the JD, creates applications/YYYY-MM-<slug>/,
# persists the JD into it, then this target chains resume + cover-letter.
application: check-deps
	@test -n "$(JD)" || { echo "Usage: make application JD=<path-or-url>"; exit 1; }
	@set -e; \
	 DIR=$$(./scripts/scaffold.sh "$(JD)"); \
	 $(MAKE) --no-print-directory resume       DIR="$$DIR"; \
	 $(MAKE) --no-print-directory cover-letter DIR="$$DIR"

# Re-check an existing application's fit against your current source/.
# Updates only the fit_* lines in its notes.md.
#   make fit DIR=applications/YYYY-MM-co-role
fit:
	@test -n "$(DIR)" || { echo "Usage: make fit DIR=applications/YYYY-MM-co-role"; exit 1; }
	@./scripts/recheck.sh "$(DIR)"

# Compile a single .tex file to PDF. Output lands at <dirname>/out/<basename>.pdf
#   make pdf TEX=path/to/file.tex
pdf: check-deps
	@test -n "$(TEX)" || { echo "Usage: make pdf TEX=path/to/file.tex"; exit 1; }
	@test -f "$(TEX)" || { echo "error: $(TEX) not found"; exit 1; }
	@out_dir="$$(dirname "$(TEX)")/out"; \
	 mkdir -p "$$out_dir"; \
	 $(TECTONIC) -o "$$out_dir" "$(TEX)"

# Run the script tests (no claude or tectonic needed).
#   make test
test:
	@bash tests/run.sh

# ===== Internal =====

check-deps:
	@command -v $(TECTONIC) >/dev/null 2>&1 || { \
		echo "error: '$(TECTONIC)' not on PATH."; \
		echo "  install: brew install tectonic  (or: cargo install tectonic)"; \
		exit 1; }
	@command -v $(CLAUDE) >/dev/null 2>&1 || { \
		echo "error: '$(CLAUDE)' not on PATH."; \
		echo "  install: https://docs.claude.com/claude-code"; \
		exit 1; }

help:
	@echo "Workflow:"
	@echo ""
	@echo "  make resume       DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]"
	@echo "      Claude tailors <DIR>/resume.tex from source/ + the job description,"
	@echo "      then tectonic compiles it to <DIR>/out/resume.pdf."
	@echo ""
	@echo "  make cover-letter DIR=applications/YYYY-MM-co-role [JD=<path-or-url>]"
	@echo "      Same as above for <DIR>/cover-letter.tex."
	@echo ""
	@echo "  make application  JD=<path-or-url>"
	@echo "      Claude derives company/role from the JD, scaffolds"
	@echo "      applications/YYYY-MM-<slug>/, then runs both 'resume' and"
	@echo "      'cover-letter' for it."
	@echo ""
	@echo "  make fit          DIR=applications/YYYY-MM-co-role"
	@echo "      Re-check an application's fit against your current source/;"
	@echo "      updates only the fit_* lines in its notes.md."
	@echo ""
	@echo "  make pdf          TEX=path/to/file.tex"
	@echo "      Compile any .tex file to <its-dir>/out/<basename>.pdf."
	@echo ""
	@echo "  make test"
	@echo "      Run the script tests (no claude or tectonic needed)."
	@echo ""
	@echo "Try it: make application JD=example/job-description.md"
	@echo "  The first run copies the example profile from example/source/ into"
	@echo "  source/. Edit source/*.yaml to make it yours."
	@echo ""
	@echo "JD resolution (in order):"
	@echo "  1. JD=<path>  — read a local markdown file"
	@echo "  2. JD=<url>   — fetch via WebFetch; caches to <DIR>/job-description.md"
	@echo "  3. (omitted)  — falls back to <DIR>/job-description.md"
