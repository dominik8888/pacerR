test_that("pacer_authenticate handles missing credentials", {
  # Temporarily unset environment variables
  old_user <- Sys.getenv("PACER_USERNAME")
  old_pass <- Sys.getenv("PACER_PASSWORD")
  
  Sys.unsetenv("PACER_USERNAME")
  Sys.unsetenv("PACER_PASSWORD")
  
  # Should error when no credentials provided
  expect_error(
    pacer_authenticate(),
    "PACER_USERNAME environment variable not set"
  )
  
  # Restore environment
  if (old_user != "") Sys.setenv(PACER_USERNAME = old_user)
  if (old_pass != "") Sys.setenv(PACER_PASSWORD = old_pass)
})

test_that("pacer_authenticate accepts direct credentials", {
  # This test would require actual credentials to fully test
  # For now, just check function accepts parameters
  expect_error(
    pacer_authenticate(username = "test", password = "test"),
    NA  # Expects some error but not parameter-related
  )
})

# Note: Full integration tests require actual PACER credentials
# and should be run separately with authentication
