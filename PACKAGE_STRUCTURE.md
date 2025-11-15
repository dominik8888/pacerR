# Package Structure Overview

## Directory Tree

```
pacerR/
├── DESCRIPTION              # Package metadata and dependencies
├── NAMESPACE               # Auto-generated, don't edit manually
├── LICENSE                 # MIT license with disclaimer
├── README.md               # Main package documentation
├── DEVELOPMENT_GUIDE.md    # Step-by-step publishing guide
├── .gitignore              # Git ignore rules (includes credentials!)
├── .Rbuildignore           # Files to exclude from package build
│
├── R/                      # All R code goes here
│   ├── authenticate.R      # pacer_authenticate()
│   ├── retrieve.R          # pacer_retrieve_cases()
│   ├── network.R           # pacer_discover_network() + pacer_extract_associations()
│   └── utils.R             # Internal helper functions
│
├── man/                    # Auto-generated documentation
│   └── *.Rd               # Created by roxygen2, don't edit directly
│
├── vignettes/             # Long-form documentation
│   └── getting-started.Rmd # Tutorial for users
│
├── tests/                 # Unit tests
│   ├── testthat.R         # Test runner
│   └── testthat/
│       └── test-authenticate.R  # Test files
│
├── examples/              # Example scripts (not part of package)
│   └── quick_start.R      # Demo script for users
│
├── data-raw/              # Raw data processing scripts (optional)
└── build_package.R        # Script to build and check package
```

## Key Files Explained

### DESCRIPTION
- Defines package metadata (name, version, author)
- Lists dependencies (httr, rvest, xml2, etc.)
- **ACTION REQUIRED**: Update your name, email, GitHub username

### R/ Files

**authenticate.R**
- `pacer_authenticate()`: User-facing authentication function
- Reads credentials from environment variables (secure)
- Returns auth token for other functions

**retrieve.R**
- `pacer_retrieve_cases()`: Main retrieval function
- Handles both vector of cases AND CSV files
- Flexible parameters for rate limiting, output, resuming
- Returns log of all retrieval attempts

**network.R**
- `pacer_extract_associations()`: Parse XML for related cases
- `pacer_discover_network()`: Complete network discovery
- Optional recursive mode to find 2nd-degree connections
- Returns comprehensive network data

**utils.R**
- `retrieve_case_xml_internal()`: Internal scraping logic
- Not exported (users don't see this)
- Handles all the web navigation complexity

### Documentation (roxygen2)

Each function has roxygen2 comments above it:

```r
#' Function Title
#'
#' Description of what it does
#'
#' @param param1 Description of parameter
#' @param param2 Description of parameter
#'
#' @return What the function returns
#'
#' @examples
#' \dontrun{
#'   example_code_here()
#' }
#'
#' @export
function_name <- function(param1, param2) {
  # function code
}
```

When you run `devtools::document()`, it converts these to .Rd files in man/.

### README.md
- First thing people see on GitHub
- Installation instructions
- Quick examples
- Links to more documentation
- **ACTION REQUIRED**: Update GitHub URLs and personal info

### Vignettes
- Long-form tutorials
- More detailed than README
- Built into package documentation
- Users access with: `browseVignettes("pacerR")`

### Tests
- Ensure functions work correctly
- Run with: `devtools::test()`
- Good practice but optional for initial release

## Workflow

### Development Cycle

1. **Edit R code** in R/ directory
2. **Update documentation** (roxygen2 comments)
3. **Generate docs**: `devtools::document()`
4. **Test**: `devtools::test()`
5. **Check**: `devtools::check()`
6. **Install locally**: `devtools::install()`
7. **Try it out**: `library(pacerR)`

### When Ready to Publish

1. **Clean up**: Remove credentials from all files and git history
2. **Update metadata**: Name, email, GitHub links
3. **Final check**: `devtools::check()` with zero errors
4. **Git**: Initialize repo, add files, commit
5. **GitHub**: Create repo, push code
6. **Release**: Tag version, write release notes

## Function Design Philosophy

### User-Facing Functions (exported with @export)

**pacer_authenticate()**
- Simple: just returns a token
- Secure: reads from environment variables
- Clear error messages if credentials missing

**pacer_retrieve_cases()**
- Flexible input: vector OR CSV file
- Sensible defaults: rate limiting, resume on error
- Verbose output: users see progress
- Returns log: users can check what happened

**pacer_discover_network()**
- High-level: does everything in one function
- Optional recursion: simple vs. comprehensive
- Returns structured data: easy to analyze
- Saves files: automatic backup

**pacer_extract_associations()**
- Utility function: useful on its own
- Handles file paths OR content
- Robust error handling

### Internal Functions (not exported)

**retrieve_case_xml_internal()**
- Does the messy web scraping
- Users never call this directly
- Can change implementation without breaking user code

## Design Patterns Used

### Error Handling
```r
tryCatch({
  # Try to do something
  result <- risky_operation()
}, error = function(e) {
  # Handle gracefully
  message("Error: ", e$message)
  return(safe_default)
})
```

### Progress Reporting
```r
if (verbose) {
  message("Doing something...")
}
```

### Rate Limiting
```r
# Respectful of servers
wait_time <- sample(5:10, 1)
Sys.sleep(wait_time)
```

### Resume Capability
```r
if (resume_if_exists && file.exists(xml_path)) {
  # Skip already-downloaded files
  next
}
```

## Common Tasks

### Adding a New Function

1. Create/edit file in R/
2. Add roxygen2 documentation
3. Include @export if user-facing
4. Run `devtools::document()`
5. Add tests in tests/testthat/
6. Update vignette with example

### Fixing a Bug

1. Write a test that reproduces bug
2. Fix the code
3. Verify test passes
4. Update version number (patch: 0.1.0 → 0.1.1)
5. Update NEWS.md
6. Commit and push

### Adding a Dependency

1. Add to Imports in DESCRIPTION
2. Use package::function() notation in code
3. Or add #' @importFrom package function
4. Run `devtools::document()`

## What Each File Does

**For the package itself:**
- R/*.R: The actual code
- man/*.Rd: Help files (auto-generated)
- DESCRIPTION: Package info
- NAMESPACE: Export declarations (auto-generated)

**For users:**
- README.md: Quick start guide
- vignettes/: Detailed tutorials
- examples/: Sample scripts

**For development:**
- tests/: Quality assurance
- .gitignore: Keep credentials safe
- build_package.R: Automated checks
- DEVELOPMENT_GUIDE.md: Publishing checklist

**For GitHub:**
- LICENSE: Legal permissions
- README.md: Project homepage
- (Future: CONTRIBUTING.md, CODE_OF_CONDUCT.md)

## Security Notes

### CRITICAL: Credentials

**NEVER commit:**
- Actual usernames/passwords
- Auth tokens
- API keys
- Any file with "credentials" or "password" in name

**Safe approach:**
- Store in .Renviron (gitignored)
- Read with Sys.getenv()
- Example scripts show process, not actual credentials

### Git History

Before pushing to GitHub:
```bash
# Search for any leaked credentials
git log --all --full-history | grep -i password
git log --all --full-history | grep -i credential

# If found, MUST use git-filter-repo or BFG to clean
```

## Package Quality Checklist

Before publishing:
- [ ] All functions documented with roxygen2
- [ ] Examples in documentation work (or wrapped in \dontrun{})
- [ ] README has installation instructions
- [ ] README has basic usage example
- [ ] Personal info updated (name, email, GitHub)
- [ ] No credentials in any files or git history
- [ ] devtools::check() passes with no errors
- [ ] Version number is appropriate
- [ ] LICENSE file is complete
- [ ] .gitignore covers all sensitive files

## For Your CV

Highlight these aspects:

**Technical Skills:**
- R package development
- Web scraping and API interaction
- Data processing pipelines
- Documentation and testing
- Version control (git/GitHub)

**Software Engineering:**
- Modular design (separation of concerns)
- User-friendly interfaces
- Error handling and logging
- Security best practices (credential management)
- Code documentation (roxygen2)

**Research Computing:**
- Reproducible research tools
- Data acquisition automation
- Network analysis preparation
- Open science practices

## Resources

- [R Packages book](https://r-pkgs.org/) by Hadley Wickham
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [devtools documentation](https://devtools.r-lib.org/)
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)
- [GitHub flow](https://guides.github.com/introduction/flow/)

## Questions?

Common issues:
- "Can't find function": Did you run `devtools::load_all()`?
- "Documentation not updating": Did you run `devtools::document()`?
- "Tests failing": Did you run `devtools::test()` to see details?
- "Check has errors": Read the check output carefully, it tells you exactly what's wrong

The package is ready for you to:
1. Update personal info
2. Test locally
3. Publish to GitHub

Good luck!
