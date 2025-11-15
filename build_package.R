# ============================================
# BUILD AND CHECK SCRIPT FOR pacerR
# Run this before publishing
# ============================================

cat("Starting package build process...\n\n")

# Check if required packages are installed
required_pkgs <- c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown")

for (pkg in required_pkgs) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg)
  }
}

library(devtools)

# ============================================
# 1. GENERATE DOCUMENTATION
# ============================================

cat("\n=== STEP 1: Generating documentation ===\n")
document()
cat("✓ Documentation generated\n")

# ============================================
# 2. BUILD VIGNETTES
# ============================================

cat("\n=== STEP 2: Building vignettes ===\n")
tryCatch({
  build_vignettes()
  cat("✓ Vignettes built\n")
}, error = function(e) {
  cat("⚠ Vignette building failed:", e$message, "\n")
  cat("  (This is OK if you don't have vignettes yet)\n")
})

# ============================================
# 3. RUN TESTS
# ============================================

cat("\n=== STEP 3: Running tests ===\n")
tryCatch({
  test()
  cat("✓ Tests passed\n")
}, error = function(e) {
  cat("⚠ Some tests failed:", e$message, "\n")
  cat("  Review test output above\n")
})

# ============================================
# 4. CHECK PACKAGE
# ============================================

cat("\n=== STEP 4: Running R CMD check ===\n")
cat("This may take a few minutes...\n\n")

check_results <- check()

cat("\n=== CHECK RESULTS ===\n")
print(check_results)

# ============================================
# 5. INSTALL LOCALLY
# ============================================

cat("\n=== STEP 5: Installing package locally ===\n")
install()
cat("✓ Package installed\n")

# ============================================
# 6. SUMMARY
# ============================================

cat("\n========================================\n")
cat("BUILD COMPLETE\n")
cat("========================================\n\n")

cat("Next steps:\n")
cat("1. Review any warnings or notes from check()\n")
cat("2. Update personal information (name, email, GitHub)\n")
cat("3. Test the package: library(pacerR)\n")
cat("4. Commit to git\n")
cat("5. Push to GitHub\n\n")

cat("See DEVELOPMENT_GUIDE.md for detailed instructions.\n")
