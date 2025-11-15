#' Internal function to retrieve single case XML
#'
#' @keywords internal
#' @noRd
retrieve_case_xml_internal <- function(case_number, circuit, auth_token, verbose = TRUE) {
  
  base_url <- paste0("https://ecf.", circuit, ".uscourts.gov")
  h <- httr::handle(base_url)
  
  tryCatch({
    # Navigate to search page
    search_page_url <- paste0(base_url, "/n/beam/servlet/TransportRoom?servlet=CaseSearch.jsp")
    search_response <- httr::GET(
      url = search_page_url,
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token)
    )
    
    search_page <- rvest::read_html(httr::content(search_response, "text"))
    form <- rvest::html_nodes(search_page, "form")[[1]]
    inputs <- rvest::html_nodes(form, "input")
    csrf_token <- rvest::html_attr(
      inputs[rvest::html_attr(inputs, "name") == "CSRF"],
      "value"
    )
    
    # Submit search
    search_data <- list(
      servlet = "CaseSelectionTable.jsp",
      CSRF = csrf_token,
      csnum1 = case_number,
      csnum2 = "",
      aName = "",
      searchPty = "pty"
    )
    
    result_response <- httr::POST(
      url = paste0(base_url, "/n/beam/servlet/TransportRoom"),
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token),
      httr::add_headers(
        Referer = search_page_url,
        `User-Agent` = "Mozilla/5.0"
      ),
      body = search_data,
      encode = "form"
    )
    
    result_page <- rvest::read_html(httr::content(result_response, "text"))
    links <- rvest::html_nodes(result_page, "a")
    case_summary_link <- links[grepl("CaseSummary", rvest::html_attr(links, "href"))][1]
    
    if (length(case_summary_link) == 0) {
      if (verbose) message("  [X] Case not found")
      return(list(xml = NULL, status = "NOT_FOUND"))
    }
    
    # Navigate to case summary
    summary_url <- paste0(
      base_url,
      "/n/beam/servlet/",
      rvest::html_attr(case_summary_link, "href")
    )
    summary_response <- httr::GET(
      url = summary_url,
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token)
    )
    summary_page <- rvest::read_html(httr::content(summary_response, "text"))
    
    # Find full docket form
    forms <- rvest::html_nodes(summary_page, "form")
    full_docket_form <- NULL
    
    for (f in forms) {
      inputs <- rvest::html_nodes(f, "input")
      if (any(rvest::html_attr(inputs, "name") == "fullDocket")) {
        full_docket_form <- f
        break
      }
    }
    
    if (is.null(full_docket_form)) {
      if (verbose) message("  [X] No full docket available")
      return(list(xml = NULL, status = "NO_DOCKET"))
    }
    
    # Submit full docket request
    form_action <- rvest::html_attr(full_docket_form, "action")
    form_inputs <- rvest::html_nodes(full_docket_form, "input")
    form_data <- list()
    
    for (inp in form_inputs) {
      name <- rvest::html_attr(inp, "name")
      value <- rvest::html_attr(inp, "value")
      type <- rvest::html_attr(inp, "type")
      
      if (!is.na(name) && !is.na(type) &&
          (type == "hidden" || (type == "submit" && name == "fullDocket"))) {
        form_data[[name]] <- ifelse(is.na(value), "", value)
      }
    }
    
    filter_response <- httr::POST(
      url = paste0(base_url, "/n/beam/servlet/", form_action),
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token),
      body = form_data,
      encode = "form"
    )
    
    # Request XML format
    filter_page <- rvest::read_html(httr::content(filter_response, "text"))
    filter_form <- rvest::html_nodes(filter_page, "form")[[1]]
    filter_inputs <- rvest::html_nodes(filter_form, "input")
    
    filter_data <- list()
    for (inp in filter_inputs) {
      name <- rvest::html_attr(inp, "name")
      value <- rvest::html_attr(inp, "value")
      type <- rvest::html_attr(inp, "type")
      
      if (!is.na(name) && type != "submit") {
        filter_data[[name]] <- ifelse(is.na(value), "", value)
      }
    }
    filter_data[["outputXML_TXT"]] <- "XML"
    
    xml_response <- httr::POST(
      url = paste0(base_url, "/n/beam/servlet/TransportRoom"),
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token),
      body = filter_data,
      encode = "form",
      httr::timeout(120)
    )
    
    # Confirm download charge
    confirm_page <- rvest::read_html(httr::content(xml_response, "text"))
    confirm_form <- rvest::html_nodes(confirm_page, "form")[[1]]
    confirm_inputs <- rvest::html_nodes(confirm_form, "input")
    
    confirm_data <- list()
    for (inp in confirm_inputs) {
      name <- rvest::html_attr(inp, "name")
      value <- rvest::html_attr(inp, "value")
      type <- rvest::html_attr(inp, "type")
      
      if (!is.na(name) && type != "submit") {
        confirm_data[[name]] <- ifelse(is.na(value), "", value)
      }
    }
    confirm_data[["outputXML_TXT"]] <- "XML"
    confirm_data[["confirmCharge"]] <- "Y"
    
    final_xml_response <- httr::POST(
      url = paste0(base_url, "/n/beam/servlet/TransportRoom"),
      handle = h,
      httr::set_cookies(NextGenCSO = auth_token),
      body = confirm_data,
      encode = "form",
      httr::timeout(120)
    )
    
    if (verbose) message("  [OK] Retrieved XML")
    
    return(list(
      xml = httr::content(final_xml_response, "text"),
      status = "SUCCESS"
    ))
    
  }, error = function(e) {
    if (verbose) message("  [X] Error: ", e$message)
    return(list(
      xml = NULL,
      status = paste0("ERROR: ", e$message)
    ))
  })
}
