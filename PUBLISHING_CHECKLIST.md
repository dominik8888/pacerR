# Publishing Checklist for pacerR

Use this checklist to prepare your package for GitHub publication.

## Phase 1: Personal Information (30 minutes)

- [ ] Open `DESCRIPTION` file
  - [ ] Change author name from placeholder
  - [ ] Add your email address
  - [ ] Update GitHub URL (replace `yourusername` with your actual GitHub username)

- [ ] Open `README.md` file
  - [ ] Replace `[Your Name]` with your name (4 places)
  - [ ] Replace `[Your Institution/Affiliation]` with UCL
  - [ ] Replace `[Contact Email]` with your email
  - [ ] Update all GitHub URLs (replace `yourusername`)

- [ ] Open `LICENSE` file
  - [ ] Replace `[Your Name]` with your name
  - [ ] Update year to 2024 (or current year)

- [ ] Open `vignettes/getting-started.Rmd`
  - [ ] Update GitHub URLs (replace `yourusername`)

- [ ] Open `PACKAGE_STRUCTURE.md`
  - [ ] Review but no changes needed

## Phase 2: Documentation (1 hour)

- [ ] Install required packages:
  ```r
  install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown"))
  ```

- [ ] Generate documentation:
  ```r
  devtools::document()
  ```
  - [ ] Check that `man/` directory now has .Rd files
  - [ ] Fix any warnings or errors

- [ ] Preview documentation:
  ```r
  ?pacer_authenticate
  ?pacer_retrieve_cases
  ?pacer_discover_network
  ?pacer_extract_associations
  ```

## Phase 3: Testing (1-2 hours)

- [ ] Set up credentials:
  ```r
  usethis::edit_r_environ()
  ```
  Add:
  ```
  PACER_USERNAME=your_actual_username
  PACER_PASSWORD=your_actual_password
  ```
  Restart R

- [ ] Install package locally:
  ```r
  devtools::install()
  ```

- [ ] Test authentication:
  ```r
  library(pacerR)
  token <- pacer_authenticate()
  ```

- [ ] Test with ONE real case (will cost ~$0.10):
  ```r
  test <- pacer_retrieve_cases(
    cases = c("20-5000"),  # Use a real case from your data
    circuit = "cadc",
    auth_token = token
  )
  ```
  - [ ] Verify XML file was created
  - [ ] Check file is valid XML
  - [ ] Test extraction:
    ```r
    assoc <- pacer_extract_associations(test$xmlPath[1])
    ```

## Phase 4: Package Check (1 hour)

- [ ] Run R CMD check:
  ```r
  devtools::check()
  ```

- [ ] Review results:
  - [ ] 0 errors (REQUIRED - fix any errors)
  - [ ] 0 warnings (RECOMMENDED - fix if possible)
  - [ ] Minimize notes (some are OK)

- [ ] Common issues to fix:
  - [ ] Missing package imports in DESCRIPTION
  - [ ] Documentation formatting errors
  - [ ] File permissions issues

- [ ] Re-run check until clean:
  ```r
  devtools::check()
  ```

## Phase 5: Git Setup (30 minutes)

- [ ] Create `.gitignore` (already done)
  - [ ] Verify it includes `.Renviron`
  - [ ] Verify it includes credential-related patterns

- [ ] CRITICAL: Check no credentials in files:
  ```bash
  # Search all files
  grep -r "your_actual_username" .
  grep -r "your_actual_password" .
  ```
  - [ ] If found, remove them!

- [ ] Initialize git repository:
  ```bash
  cd /path/to/pacerR
  git init
  git add .
  git commit -m "Initial commit: pacerR package for PACER retrieval"
  ```

- [ ] Double-check what you're committing:
  ```bash
  git status
  git log -p  # Review the commit
  ```

## Phase 6: GitHub Publication (30 minutes)

- [ ] Create GitHub repository:
  1. Go to https://github.com/new
  2. Repository name: `pacerR`
  3. Description: "Automated retrieval and network analysis of PACER court documents"
  4. Public repository
  5. Do NOT add README/license/gitignore (you have them)
  6. Click "Create repository"

- [ ] Push to GitHub:
  ```bash
  git remote add origin https://github.com/YOUR_USERNAME/pacerR.git
  git branch -M main
  git push -u origin main
  ```

- [ ] Verify on GitHub:
  - [ ] Files are there
  - [ ] README displays correctly
  - [ ] NO credentials visible anywhere

- [ ] Test installation from GitHub:
  ```r
  # In fresh R session
  devtools::install_github("YOUR_USERNAME/pacerR")
  library(pacerR)
  ```

## Phase 7: Polish GitHub Repo (1 hour)

- [ ] Add repository description on GitHub

- [ ] Add topics/tags:
  - r
  - r-package
  - pacer
  - legal-data
  - court-records
  - litigation-analysis

- [ ] Create first release:
  1. Go to "Releases" tab
  2. Click "Create a new release"
  3. Tag: v0.1.0
  4. Title: "Initial Release"
  5. Description:
     ```markdown
     ## Features
     - Authenticated access to PACER system
     - Retrieval of case dockets in XML format
     - Network discovery of associated cases
     - Responsible rate limiting
     
     ## Installation
     ```r
     devtools::install_github("YOUR_USERNAME/pacerR")
     ```
     
     ## Documentation
     See README for usage examples
     ```

- [ ] Optional but recommended:
  - [ ] Add `CONTRIBUTING.md` (see DEVELOPMENT_GUIDE.md)
  - [ ] Add `CODE_OF_CONDUCT.md`
  - [ ] Add screenshot to README
  - [ ] Star your own repo (why not!)

## Phase 8: Update CV/Portfolio (30 minutes)

- [ ] Add to CV under "Software Development":
  ```
  pacerR - R package for automated PACER court document retrieval
  GitHub: github.com/YOUR_USERNAME/pacerR
  Enables network analysis of federal court litigation patterns
  ```

- [ ] Prepare talking points:
  - "Developed open-source R package solving real research problem"
  - "Implemented secure authentication and responsible rate limiting"
  - "Created comprehensive documentation and testing infrastructure"
  - "Demonstrates software engineering best practices"

- [ ] Consider blog post:
  - Technical challenge (PACER's interface)
  - How you solved it
  - What you learned
  - Link to GitHub

## Phase 9: Announcement (Optional)

- [ ] Tweet/LinkedIn post:
  ```
  Excited to share pacerR, an R package for automated PACER court 
  document retrieval! Developed for my climate litigation research 
  at UCL. Check it out: [GitHub URL]
  #rstats #openscience #legaltech
  ```

- [ ] Share in relevant communities:
  - [ ] RStudio Community
  - [ ] R-bloggers (if you write a blog post)
  - [ ] Your department/research group

## Ongoing Maintenance

After publishing:

- [ ] Watch for GitHub issues
- [ ] Respond to questions within ~1 week
- [ ] Consider feature requests
- [ ] Update if PACER changes their system
- [ ] Keep documentation current

## Troubleshooting

**Error during check()?**
- Read the error message completely
- Google the specific error
- Check [r-pkgs.org](https://r-pkgs.org) book

**Git won't push?**
- Check remote URL: `git remote -v`
- Check authentication with GitHub
- Try: `git push -u origin main --force` (ONLY if new repo)

**Package won't install from GitHub?**
- Check repo is public
- Verify README shows correctly
- Try in fresh R session

**Found credentials in git?**
- DO NOT push to GitHub yet
- Use `git-filter-repo` or BFG Repo Cleaner
- See: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

## Final Checks Before Publishing

Run through this one more time:

- [ ] No credentials in any files
- [ ] All personal info updated
- [ ] `devtools::check()` passes
- [ ] Git history is clean
- [ ] README is complete
- [ ] GitHub repo is ready

## Time Estimate

- Phase 1: 30 mins
- Phase 2: 1 hour  
- Phase 3: 1-2 hours
- Phase 4: 1 hour
- Phase 5: 30 mins
- Phase 6: 30 mins
- Phase 7: 1 hour
- Phase 8: 30 mins

**Total: 6-7 hours**

Spread over 2-3 days for best results.

## Done!

Once all checkboxes are complete, you have a published R package! 🎉

This is a significant achievement for your CV and MSc applications.

---

**Need help?** See DEVELOPMENT_GUIDE.md for more details on each step.
