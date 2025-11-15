#' Authenticate with PACER System
#'
#' Authenticates with the PACER login system and returns an authentication token
#' for subsequent requests. Credentials can be provided directly or via environment
#' variables for security.
#'
#' @param username PACER username. If NULL, reads from PACER_USERNAME environment variable.
#' @param password PACER password. If NULL, reads from PACER_PASSWORD environment variable.
#'
#' @return Authentication token (character string) to be used in subsequent API calls.
#'
#' @details
#' For security, it is strongly recommended to store credentials in environment variables
#' rather than hardcoding them in scripts. Add the following to your .Renviron file:
#'
#' \code{PACER_USERNAME=your_username}
#'
#' \code{PACER_PASSWORD=your_password}
#'
#' You can edit .Renviron with \code{usethis::edit_r_environ()}.
#'
#' @examples
#' \dontrun{
#' # Using environment variables (recommended)
#' token <- pacer_authenticate()
#'
#' # Or provide credentials directly (not recommended for scripts)
#' token <- pacer_authenticate(username = "myusername", password = "mypassword")
#' }
#'
#' @export
pacer_authenticate <- function(username = NULL, password = NULL) {
  
  # Get credentials from environment if not provided
  if (is.null(username)) {
    username <- Sys.getenv("PACER_USERNAME")
    if (username == "") {
      stop("Username not provided and PACER_USERNAME environment variable not set.\n",
           "Either provide username argument or set PACER_USERNAME environment variable.")
    }
  }
  
  if (is.null(password)) {
    password <- Sys.getenv("PACER_PASSWORD")
    if (password == "") {
      stop("Password not provided and PACER_PASSWORD environment variable not set.\n",
           "Either provide password argument or set PACER_PASSWORD environment variable.")
    }
  }
  
  auth_url <- "https://pacer.login.uscourts.gov/services/cso-auth"
  
  message("Authenticating with PACER...")
  
  auth_response <- httr::POST(
    url = auth_url,
    httr::add_headers(
      "Content-Type" = "application/json",
      "Accept" = "application/json"
    ),
    body = jsonlite::toJSON(
      list(loginId = username, password = password),
      auto_unbox = TRUE
    ),
    encode = "json"
  )
  
  if (httr::status_code(auth_response) != 200) {
    stop("Authentication failed. Please check your credentials.\n",
         "Status code: ", httr::status_code(auth_response))
  }
  
  auth_data <- httr::content(auth_response, "parsed")
  
  message("[OK] Authentication successful")
  
  return(auth_data$nextGenCSO)
}
