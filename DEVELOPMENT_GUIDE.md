# Development Guide for pacerR

## Current Status

You now have a well-structured R package with:
- ✅ Core functionality (authentication, retrieval, network discovery)
- ✅ Proper documentation structure (roxygen2)
- ✅ User-friendly interface with flexible inputs
- ✅ Secure credential management
- ✅ Comprehensive README and vignette
- ✅ Basic test infrastructure
- ✅ License and proper .gitignore

## Next Steps Before Publishing

### 1. Update Personal Information

Replace placeholder text in these files:
- `DESCRIPTION`: Add your real name, email, GitHub username
- `README.md`: Add your name, institution, contact info
- `LICENSE`: Add your name and year
- `vignettes/getting-started.Rmd`: Update GitHub URLs

Search for these placeholders:
- `[Your Name]`
- `[Your Institution/Affiliation]`
- `[Contact Email]`
- `yourusername` (GitHub username)
- `your.email@example.com`

### 2. Generate Documentation

```r
# Install required packages
install.packages(c("devtools", "roxygen2", "testthat"))

# Generate documentation from roxygen comments
devtools::document()

# This creates .Rd files in man/ directory
```

### 3. Check Package

```r
# Run R CMD check
devtools::check()

# Fix any errors, warnings, or notes that appear
```

Common issues to fix:
- Missing imports in DESCRIPTION
- Documentation formatting
- Example code that doesn't run

### 4. Test Locally

```r
# Install package locally
devtools::install()

# Test it works
library(pacerR)

# Try with your credentials
token <- pacer_authenticate()

# Test with a single case (will incur small PACER fee)
test_result <- pacer_retrieve_cases(
  cases = c("20-5000"),  # Use a real case number
  circuit = "cadc",
  auth_token = token
)
```

### 5. Add More Tests (Optional but Recommended)

Create additional test files:

```r
# tests/testthat/test-parse.R
test_that("pacer_extract_associations handles empty XML", {
  result <- pacer_extract_associations("")
  expect_equal(nrow(result), 0)
})

# tests/testthat/test-retrieve.R
# Add unit tests for input validation
```

### 6. Build Vignettes

```r
# Build vignettes
devtools::build_vignettes()

# Preview
devtools::build_vignettes()
browseVignettes("pacerR")
```

### 7. CRITICAL: Clean Git History

**BEFORE pushing to GitHub**, ensure no credentials in git history:

```bash
# Check git history for sensitive data
git log --all --full-history --source -- "*password*"
git log --all --full-history --source -- "*credential*"

# If you find commits with credentials, you MUST clean them
# Use git-filter-repo or BFG Repo Cleaner
# See: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
```

### 8. Initialize Git Repository

```bash
cd pacerR
git init
git add .
git commit -m "Initial commit: pacerR package for PACER data retrieval"
```

### 9. Create GitHub Repository

1. Go to https://github.com/new
2. Create repository named `pacerR`
3. Do NOT initialize with README (you already have one)
4. Add remote and push:

```bash
git remote add origin https://github.com/YOURUSERNAME/pacerR.git
git branch -M main
git push -u origin main
```

### 10. Set Up GitHub Repository

Add these files via GitHub web interface:

**CONTRIBUTING.md**:
```markdown
# Contributing to pacerR

## Reporting Issues

Please report bugs via GitHub Issues with:
- Reproducible example (without sharing credentials)
- Expected vs actual behavior
- R version and package versions

## Contributing Code

1. Fork the repository
2. Create feature branch (`git checkout -b feature-name`)
3. Make changes with clear commit messages
4. Add tests for new functionality
5. Run `devtools::check()` to ensure no issues
6. Submit pull request

## Code Style

- Use tidyverse style guide
- Document all functions with roxygen2
- Include examples (use `\dontrun{}` for PACER-requiring code)
```

**CODE_OF_CONDUCT.md**:
```markdown
# Code of Conduct

## Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

## Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

## Enforcement

Instances of unacceptable behavior may be reported to [your email].
```

### 11. Update Package Version

When you make changes, update version in `DESCRIPTION`:
- Development: `0.1.0.9000`
- Bug fixes: `0.1.1`
- New features: `0.2.0`
- Breaking changes: `1.0.0`

### 12. Create Release

Once stable:

```r
# Check everything passes
devtools::check()

# Build source package
devtools::build()

# Tag release on GitHub
git tag -a v0.1.0 -m "Initial release"
git push origin v0.1.0
```

Create release notes on GitHub describing:
- Main features
- Installation instructions
- Known limitations
- Example usage

## Optional Enhancements

### Add a Logo

```r
# Use hexSticker package
library(hexSticker)
sticker(
  "path/to/icon.png",
  package = "pacerR",
  filename = "man/figures/logo.png"
)

# Add to README: ![](man/figures/logo.png)
```

### Add GitHub Actions

Create `.github/workflows/R-CMD-check.yaml` for automatic testing.

### Add pkgdown Website

```r
install.packages("pkgdown")
usethis::use_pkgdown()
pkgdown::build_site()

# Creates website at docs/ - can host on GitHub Pages
```

### Add News File

Create `NEWS.md` to track changes:

```markdown
# pacerR 0.1.0

* Initial release
* Functions for PACER authentication and retrieval
* Network discovery functionality
* Comprehensive documentation
```

## For Your CV and Applications

### How to Present This

**In CV:**
```
Software Development
- pacerR: R package for automated PACER court document retrieval
  https://github.com/yourusername/pacerR
  Enables network analysis of federal court litigation patterns
  Includes comprehensive documentation, testing, and responsible rate-limiting
```

**In Cover Letters:**
"Developed pacerR, an open-source R package for computational legal research that
automates retrieval and network analysis of federal court documents. The package
demonstrates software engineering practices including proper documentation, testing,
and secure credential management."

**In Portfolio:**
Include this with:
- Link to GitHub repo
- Brief description of technical challenge (PACER's web interface complexity)
- How it supports your research (climate litigation networks)
- Screenshots of documentation or usage examples

### Research Output

After using the package for your dissertation:
1. Cite the package in methods section
2. Consider writing technical blog post about development
3. Present at useR! conference or similar
4. Mention in academic publications

## Getting Help

If you run into issues:
1. Check `devtools::check()` output carefully
2. Read error messages completely
3. Google specific error messages
4. Ask on RStudio Community forums
5. Check r-pkgs.org book by Hadley Wickham

## Maintenance

Once published:
- Respond to GitHub issues within ~1 week
- Update if PACER changes their API
- Consider adding features users request
- Keep documentation current

If you can't maintain:
- Add note to README: "This package is no longer actively maintained"
- Consider finding collaborator to take over

## Timeline Estimate

- Documentation review: 2-3 hours
- Local testing: 1-2 hours  
- Git cleanup: 30 mins
- GitHub setup: 30 mins
- Final checks: 1 hour

**Total: ~6-8 hours of work to publish**

## Questions to Consider

Before publishing, think about:
1. Do you want to maintain this long-term?
2. Are you comfortable being contacted about it?
3. Is your code clean and well-commented?
4. Have you tested it thoroughly?
5. Is the documentation clear for others?

If yes to all → you're ready to publish!
