#' Extract Associated Cases from PACER XML
#'
#' Parses PACER XML docket files to extract information about associated cases
#' (consolidated, related, lead cases, etc.).
#'
#' @param xml_content Character string containing XML content, or path to XML file.
#'
#' @return Data frame with columns: mainCase, associatedCase, associationType, dateStart.
#'   Returns empty data frame if no associations found.
#'
#' @examples
#' \dontrun{
#' # From XML content
#' xml <- readLines("docket_20_1234.xml")
#' associations <- pacer_extract_associations(xml)
#'
#' # From file path
#' associations <- pacer_extract_associations("docket_20_1234.xml")
#' }
#'
#' @export
pacer_extract_associations <- function(xml_content) {
  
  # Handle file path input
  if (length(xml_content) == 1 && file.exists(xml_content)) {
    xml_content <- paste(readLines(xml_content, warn = FALSE), collapse = "\n")
  } else if (length(xml_content) > 1) {
    xml_content <- paste(xml_content, collapse = "\n")
  }
  
  if (is.null(xml_content) || xml_content == "") {
    return(data.frame(
      mainCase = character(),
      associatedCase = character(),
      associationType = character(),
      dateStart = character(),
      stringsAsFactors = FALSE
    ))
  }
  
  tryCatch({
    xml_doc <- xml2::read_xml(xml_content)
    
    # Get main case number
    stub <- xml2::xml_find_first(xml_doc, ".//stub")
    main_case <- xml2::xml_attr(stub, "caseNumber")
    
    if (is.na(main_case)) {
      warning("Could not find main case number in XML")
      return(data.frame(
        mainCase = character(),
        associatedCase = character(),
        associationType = character(),
        dateStart = character(),
        stringsAsFactors = FALSE
      ))
    }
    
    # Find associated cases
    assoc_cases <- xml2::xml_find_all(xml_doc, ".//associatedCase")
    
    if (length(assoc_cases) == 0) {
      return(data.frame(
        mainCase = main_case,
        associatedCase = NA,
        associationType = NA,
        dateStart = NA,
        stringsAsFactors = FALSE
      ))
    }
    
    # Extract associations
    result <- data.frame(
      mainCase = character(),
      associatedCase = character(),
      associationType = character(),
      dateStart = character(),
      stringsAsFactors = FALSE
    )
    
    for (case in assoc_cases) {
      member <- xml2::xml_attr(case, "memberCaseNumber")
      type <- xml2::xml_attr(case, "associatedType")
      date_start <- xml2::xml_attr(case, "dateStart")
      
      result <- rbind(result, data.frame(
        mainCase = main_case,
        associatedCase = member,
        associationType = type,
        dateStart = date_start,
        stringsAsFactors = FALSE
      ))
    }
    
    return(result)
    
  }, error = function(e) {
    warning("Error parsing XML: ", e$message)
    return(data.frame(
      mainCase = character(),
      associatedCase = character(),
      associationType = character(),
      dateStart = character(),
      stringsAsFactors = FALSE
    ))
  })
}


#' Discover Complete Case Network
#'
#' Retrieves XML dockets for an initial set of cases and discovers all associated
#' cases, creating a complete network of related litigation. Can optionally perform
#' recursive discovery to find second-degree connections.
#'
#' @param cases Character vector of initial case numbers, or path to CSV file.
#' @param circuit Court circuit code (default: "cadc").
#' @param case_column If \code{cases} is a CSV file, column name with case numbers.
#' @param output_dir Directory for output files (default: "pacer_network_output").
#' @param auth_token Authentication token. If NULL, will authenticate.
#' @param recursive Perform recursive discovery (default: FALSE). If TRUE, will
#'   retrieve XML for newly discovered cases to find second-degree connections.
#' @param max_iterations Maximum recursion depth if recursive = TRUE (default: 2).
#' @param rate_limit_seconds Wait time between requests (default: c(5, 10)).
#' @param save_progress Save progress every N cases (default: 50).
#' @param verbose Print detailed progress (default: TRUE).
#'
#' @return A list with components:
#'   \itemize{
#'     \item associations: Data frame of all case associations found
#'     \item retrieval_log: Log of all retrieval attempts
#'     \item original_cases: Cases from initial input
#'     \item discovered_cases: New cases found through associations
#'     \item all_unique_cases: All unique cases in network
#'   }
#'
#' @details
#' This function performs network discovery by:
#' 1. Retrieving XML for initial case list
#' 2. Parsing XML to find associated cases
#' 3. Optionally retrieving XML for newly discovered cases (recursive mode)
#' 4. Creating complete network map of related litigation
#'
#' Results are saved to multiple CSV files in output_dir for further analysis.
#'
#' @examples
#' \dontrun{
#' # Simple discovery (no recursion)
#' network <- pacer_discover_network(
#'   cases = c("20-1234", "20-1235"),
#'   circuit = "cadc"
#' )
#'
#' # Recursive discovery from CSV
#' network <- pacer_discover_network(
#'   cases = "my_cases.csv",
#'   case_column = "case_number",
#'   circuit = "cadc",
#'   recursive = TRUE,
#'   max_iterations = 2
#' )
#'
#' # Access results
#' View(network$associations)
#' length(network$discovered_cases)  # How many new cases found?
#' }
#'
#' @export
pacer_discover_network <- function(cases,
                                    circuit = "cadc",
                                    case_column = NULL,
                                    output_dir = "pacer_network_output",
                                    auth_token = NULL,
                                    recursive = FALSE,
                                    max_iterations = 2,
                                    rate_limit_seconds = c(5, 10),
                                    save_progress = 50,
                                    verbose = TRUE) {
  
  if (verbose) {
    message("\n========================================")
    message("PACER CASE NETWORK DISCOVERY")
    message("========================================")
    message("Recursive mode: ", recursive)
    if (recursive) message("Max iterations: ", max_iterations)
    message("========================================\n")
  }
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  xml_dir <- file.path(output_dir, "xml_files")
  if (!dir.exists(xml_dir)) {
    dir.create(xml_dir)
  }
  
  # Authenticate if needed
  if (is.null(auth_token)) {
    auth_token <- pacer_authenticate()
  }
  
  # Track all associations across iterations
  all_associations <- data.frame(
    mainCase = character(),
    associatedCase = character(),
    associationType = character(),
    dateStart = character(),
    stringsAsFactors = FALSE
  )
  
  # Initialize with original cases
  cases_to_process <- cases
  original_input_cases <- NULL
  processed_cases <- character()
  iteration <- 1
  
  repeat {
    if (verbose) {
      message("\n========================================")
      message("ITERATION ", iteration, "/", max_iterations)
      message("========================================\n")
    }
    
    # Retrieve XML for current batch
    retrieval_results <- pacer_retrieve_cases(
      cases = cases_to_process,
      circuit = circuit,
      case_column = case_column,
      output_dir = xml_dir,
      auth_token = auth_token,
      rate_limit_seconds = rate_limit_seconds,
      save_progress = save_progress,
      resume_if_exists = TRUE,
      verbose = verbose
    )
    
    # Store original input cases from first iteration
    if (is.null(original_input_cases)) {
      original_input_cases <- retrieval_results$caseNumber
    }
    
    # Parse XML files for associations
    successful_retrievals <- retrieval_results[retrieval_results$status == "SUCCESS", ]
    
    if (nrow(successful_retrievals) > 0) {
      for (i in seq_len(nrow(successful_retrievals))) {
        xml_path <- successful_retrievals$xmlPath[i]
        if (!is.na(xml_path) && file.exists(xml_path)) {
          associations <- pacer_extract_associations(xml_path)
          if (nrow(associations) > 0 && !is.na(associations$associatedCase[1])) {
            all_associations <- rbind(all_associations, associations)
          }
        }
      }
    }
    
    # Mark these cases as processed
    processed_cases <- c(processed_cases, retrieval_results$caseNumber)
    
    # Check if we should continue
    if (!recursive || iteration >= max_iterations) {
      break
    }
    
    # Find new cases to process
    all_discovered <- unique(all_associations$associatedCase)
    all_discovered <- all_discovered[!is.na(all_discovered)]
    new_cases <- setdiff(all_discovered, processed_cases)
    
    if (length(new_cases) == 0) {
      if (verbose) message("\n[OK] No new cases discovered. Network complete.")
      break
    }
    
    if (verbose) {
      message("\n-> Found ", length(new_cases), " new cases for next iteration")
    }
    
    cases_to_process <- new_cases
    case_column <- NULL  # No longer reading from CSV
    iteration <- iteration + 1
  }
  
  # Analyze results
  if (verbose) {
    message("\n========================================")
    message("NETWORK ANALYSIS")
    message("========================================")
  }
  
  cases_in_original <- unique(original_input_cases)
  cases_found_as_associated <- unique(all_associations$associatedCase)
  cases_found_as_associated <- cases_found_as_associated[!is.na(cases_found_as_associated)]
  cases_found_as_main <- unique(all_associations$mainCase)
  
  all_unique_cases <- unique(c(cases_in_original, cases_found_as_associated, cases_found_as_main))
  new_cases_discovered <- setdiff(cases_found_as_associated, cases_in_original)
  
  if (verbose) {
    message("Original cases: ", length(cases_in_original))
    message("Total unique cases in network: ", length(all_unique_cases))
    message("New cases discovered: ", length(new_cases_discovered))
    message("Total associations: ", nrow(all_associations[!is.na(all_associations$associatedCase), ]))
  }
  
  # Save results
  readr::write_csv(
    all_associations,
    file.path(output_dir, "case_associations.csv")
  )
  readr::write_csv(
    data.frame(caseNumber = sort(all_unique_cases)),
    file.path(output_dir, "all_unique_cases.csv")
  )
  readr::write_csv(
    data.frame(caseNumber = sort(new_cases_discovered)),
    file.path(output_dir, "newly_discovered_cases.csv")
  )
  
  if (verbose) {
    message("\n[OK] Results saved to: ", output_dir)
    message("  - case_associations.csv")
    message("  - all_unique_cases.csv")
    message("  - newly_discovered_cases.csv")
    message("  - xml_files/")
    message("========================================\n")
  }
  
  # Return comprehensive results
  return(invisible(list(
    associations = all_associations,
    retrieval_log = retrieval_results,
    original_cases = cases_in_original,
    discovered_cases = new_cases_discovered,
    all_unique_cases = all_unique_cases
  )))
}
