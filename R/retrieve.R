#' Retrieve PACER Case Dockets
#'
#' Retrieves full docket information in XML format for one or more PACER cases.
#' Can accept case numbers directly as a vector or read from a CSV file.
#'
#' @section WARNING - PACER Fees:
#' **PACER charges $0.10 per page unless you have an active fee exemption.**
#' 
#' You are SOLELY responsible for:
#' \itemize{
#'   \item Verifying fee exemption status BEFORE using this function
#'   \item All charges incurred to your PACER account
#'   \item Monitoring your account for unexpected fees
#' }
#' 
#' Apply for research fee exemption at:
#' https://pacer.uscourts.gov/my-account-billing/billing/fee-exemption-request-researchers
#' 
#' This function has been tested on US Courts of Appeals with a research fee 
#' exemption. Behavior on District Courts or other court types may vary.
#' 
#' **The author is NOT responsible for any fees or charges.**
#'
#' @param cases Character vector of case numbers, or path to CSV file containing case numbers.
#' @param circuit Court circuit code (default: "cadc" for DC Circuit). See Details for options.
#' @param case_column If \code{cases} is a CSV file path, name of column containing case numbers.
#' @param output_dir Directory to save XML files (default: "pacer_xml_output").
#' @param auth_token Authentication token from \code{pacer_authenticate()}. If NULL, will attempt to authenticate.
#' @param rate_limit_seconds Wait time between requests in seconds. Default 5-10 random.
#'   Can be a single number or a range c(min, max).
#' @param save_progress Save progress every N cases (default: 50). Set to NULL to disable.
#' @param resume_if_exists Skip cases where XML already exists (default: TRUE).
#' @param verbose Print detailed progress messages (default: TRUE).
#'
#' @return A data frame with columns: caseNumber, status, timestamp, xmlPath.
#'
#' @details
#' Common circuit codes include:
#' \itemize{
#'   \item "cadc" - DC Circuit Court of Appeals (TESTED with fee exemption)
#'   \item "ca1" through "ca11" - Circuit Courts of Appeals 1-11
#'   \item "cafc" - Federal Circuit
#'   \item "dcd" - DC District Court (NOT extensively tested)
#'   \item Check PACER documentation for complete list
#' }
#'
#' Case number format varies by court but typically looks like "20-1234" or "1:20-cv-01234".
#'
#' This function implements responsible rate limiting to avoid overloading court servers.
#' Each XML download may incur a fee (typically $0.10 per page) unless you have an
#' active, applicable fee exemption. You are solely responsible for all charges.
#' 
#' **Testing Status**: This tool has been tested on US Courts of Appeals with a research
#' fee exemption. It has NOT been extensively tested on District Courts, Bankruptcy Courts,
#' or other court types. Verify your fee exemption applies before using on untested courts.
#'
#' @examples
#' \dontrun{
#' # Authenticate once
#' token <- pacer_authenticate()
#'
#' # Retrieve a few specific cases
#' results <- pacer_retrieve_cases(
#'   cases = c("20-1234", "20-1235", "20-1236"),
#'   circuit = "cadc",
#'   auth_token = token
#' )
#'
#' # Retrieve from CSV file
#' results <- pacer_retrieve_cases(
#'   cases = "my_cases.csv",
#'   case_column = "case_number",
#'   circuit = "cadc",
#'   auth_token = token
#' )
#'
#' # Custom rate limiting and output
#' results <- pacer_retrieve_cases(
#'   cases = c("20-1234", "20-1235"),
#'   circuit = "cadc",
#'   auth_token = token,
#'   rate_limit_seconds = c(8, 12),  # Wait 8-12 seconds between requests
#'   output_dir = "my_xml_files",
#'   save_progress = 25  # Save every 25 cases
#' )
#' }
#'
#' @export
pacer_retrieve_cases <- function(cases,
                                  circuit = "cadc",
                                  case_column = NULL,
                                  output_dir = "pacer_xml_output",
                                  auth_token = NULL,
                                  rate_limit_seconds = c(5, 10),
                                  save_progress = 50,
                                  resume_if_exists = TRUE,
                                  verbose = TRUE) {
  
  # Parse case input
  if (length(cases) == 1 && file.exists(cases)) {
    if (verbose) message("Reading cases from CSV file: ", cases)
    
    if (is.null(case_column)) {
      stop("When providing a CSV file, you must specify the case_column parameter.")
    }
    
    cases_df <- readr::read_csv(cases, show_col_types = FALSE)
    
    if (!case_column %in% names(cases_df)) {
      stop("Column '", case_column, "' not found in CSV file.\n",
           "Available columns: ", paste(names(cases_df), collapse = ", "))
    }
    
    case_numbers <- cases_df[[case_column]]
    
  } else {
    case_numbers <- cases
  }
  
  # Clean and validate
  case_numbers <- unique(case_numbers)
  case_numbers <- case_numbers[!is.na(case_numbers) & case_numbers != ""]
  
  if (length(case_numbers) == 0) {
    stop("No valid case numbers provided.")
  }
  
  if (verbose) {
    message("\n========================================")
    message("PACER CASE RETRIEVAL")
    message("========================================")
    message("Circuit: ", circuit)
    message("Total cases: ", length(case_numbers))
    message("Output directory: ", output_dir)
    message("========================================\n")
  }
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    if (verbose) message("[OK] Created output directory: ", output_dir)
  }
  
  # Authenticate if needed
  if (is.null(auth_token)) {
    if (verbose) message("\nNo auth token provided, authenticating...")
    auth_token <- pacer_authenticate()
  }
  
  # Initialize results log
  results_log <- data.frame(
    caseNumber = character(),
    status = character(),
    timestamp = character(),
    xmlPath = character(),
    stringsAsFactors = FALSE
  )
  
  # Process each case
  for (i in seq_along(case_numbers)) {
    case_num <- case_numbers[i]
    
    if (verbose) {
      message(sprintf("\n[%d/%d] Processing: %s", i, length(case_numbers), case_num))
    }
    
    xml_filename <- paste0("docket_", gsub("[^A-Za-z0-9]", "_", case_num), ".xml")
    xml_path <- file.path(output_dir, xml_filename)
    
    # Check if already exists
    if (resume_if_exists && file.exists(xml_path)) {
      if (verbose) message("  [SKIP] XML already exists, skipping...")
      
      results_log <- rbind(results_log, data.frame(
        caseNumber = case_num,
        status = "SKIPPED_EXISTS",
        timestamp = as.character(Sys.time()),
        xmlPath = xml_path,
        stringsAsFactors = FALSE
      ))
      
      next
    }
    
    # Retrieve case XML
    result <- retrieve_case_xml_internal(case_num, circuit, auth_token, verbose)
    
    # Save XML if successful
    if (result$status == "SUCCESS" && !is.null(result$xml)) {
      writeLines(result$xml, xml_path)
      if (verbose) message("  [OK] Saved to: ", xml_filename)
    }
    
    # Log result
    results_log <- rbind(results_log, data.frame(
      caseNumber = case_num,
      status = result$status,
      timestamp = as.character(Sys.time()),
      xmlPath = ifelse(result$status == "SUCCESS", xml_path, NA),
      stringsAsFactors = FALSE
    ))
    
    # Save progress
    if (!is.null(save_progress) && i %% save_progress == 0) {
      progress_file <- file.path(output_dir, paste0("progress_log_", i, ".csv"))
      readr::write_csv(results_log, progress_file)
      if (verbose) message("\n  *** Progress saved: ", progress_file, " ***\n")
    }
    
    # Rate limiting
    if (i < length(case_numbers)) {
      if (length(rate_limit_seconds) == 2) {
        wait_time <- sample(rate_limit_seconds[1]:rate_limit_seconds[2], 1)
      } else {
        wait_time <- rate_limit_seconds[1]
      }
      
      if (verbose) message("  [WAIT] Waiting ", wait_time, " seconds...")
      Sys.sleep(wait_time)
    }
  }
  
  # Save final log
  final_log_path <- file.path(output_dir, "retrieval_log_final.csv")
  readr::write_csv(results_log, final_log_path)
  
  if (verbose) {
    message("\n========================================")
    message("RETRIEVAL COMPLETE")
    message("========================================")
    message("Total processed: ", nrow(results_log))
    message("Successful: ", sum(results_log$status == "SUCCESS"))
    message("Failed: ", sum(results_log$status != "SUCCESS" & results_log$status != "SKIPPED_EXISTS"))
    message("Skipped: ", sum(results_log$status == "SKIPPED_EXISTS"))
    message("\nFinal log: ", final_log_path)
    message("========================================\n")
  }
  
  return(results_log)
}
