# pacerR

<!-- badges: start -->
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

Automated retrieval and network analysis of PACER (Public Access to Court Electronic Records) court documents. Developed for academic research on litigation in US federal courts.

---

## ⚠️ CRITICAL: READ THIS BEFORE USING ⚠️

**PACER CHARGES FEES.** You are **SOLELY RESPONSIBLE** for all costs incurred.

### Fee Information

- **Standard rate**: $0.10 per page
- **Quarterly cap**: $30 per user per quarter
- **Your responsibility**: Verify your fee exemption status BEFORE using this tool
- **No guarantees**: The author is NOT responsible for any charges to your account

### Fee Exemptions for Researchers

Researchers can apply for fee exemptions:
- **Application**: https://pacer.uscourts.gov/my-account-billing/billing/fee-exemption-request-researchers
- **Verify status**: Check your PACER account to confirm exemption is ACTIVE
- **Check scope**: Confirm exemption applies to the courts you're accessing
- **Monitor charges**: Regularly check your account for unexpected fees

**This tool worked with my fee exemption for US Courts of Appeals.** It has NOT been tested extensively on District Courts or other court types. Results may vary.

### What This Tool Does

This software automates retrieval of XML docket files from PACER. **Each retrieval may incur charges if you do not have an active, applicable fee exemption.**

### Your Responsibilities

You MUST:
- ✅ Understand PACER's fee structure completely
- ✅ Obtain appropriate fee exemption (if eligible)
- ✅ Verify exemption is active and applies to your use case
- ✅ Monitor your PACER account for charges
- ✅ Use ONLY for legitimate academic research
- ✅ Comply with PACER Terms of Service and Acceptable Use Policy

You MUST NOT:
- ❌ Use for bulk commercial downloading
- ❌ Use for resale of data
- ❌ Use without understanding fee implications
- ❌ Assume fee exemption applies without verification

**THE AUTHOR PROVIDES THIS CODE AS-IS FOR RESEARCH PURPOSES AND TAKES NO RESPONSIBILITY FOR FEES, CHARGES, OR MISUSE.**

---

## Overview

`pacerR` provides tools to:

- **Authenticate** with PACER system securely
- **Retrieve** full docket information in XML format
- **Extract** associated case information (consolidated, related, lead cases)
- **Discover** complete litigation networks through recursive case associations
- **Analyze** patterns in federal court case relationships

Built for researchers studying judicial behavior, legal networks, and litigation patterns.

## Installation

```r
# Install development version from GitHub
# install.packages("devtools")
devtools::install_github("sachabechara/pacerR")
```

## Prerequisites

### 1. PACER Account
Register at https://pacer.uscourts.gov/

### 2. Fee Exemption (STRONGLY RECOMMENDED)
Apply for research fee exemption: https://pacer.uscourts.gov/my-account-billing/billing/fee-exemption-request-researchers

**Verify exemption is active before using this tool.**

### 3. Understand the Costs
- Without exemption: $0.10 per page (capped at $30/quarter)
- With exemption: Free, but verify it applies to your account and court type
- **You are responsible for all charges**

### 4. Credentials
You'll need to securely store your PACER username and password (see Setup below)

## Setup

### Secure Credential Management

**Never hardcode credentials in your scripts.** Use environment variables:

```r
# Edit your .Renviron file
usethis::edit_r_environ()

# Add these lines:
PACER_USERNAME=your_username
PACER_PASSWORD=your_password

# Restart R for changes to take effect
```

Alternatively, set them in your current session:

```r
Sys.setenv(PACER_USERNAME = "your_username")
Sys.setenv(PACER_PASSWORD = "your_password")
```

## Quick Start

### Basic Retrieval

```r
library(pacerR)

# Authenticate (reads from environment variables)
token <- pacer_authenticate()

# Retrieve a few specific cases
results <- pacer_retrieve_cases(
  cases = c("20-1234", "20-1235", "20-1236"),
  circuit = "cadc",  # DC Circuit Court of Appeals
  auth_token = token
)

# View results
View(results)
```

### Retrieve from CSV File

```r
# CSV file with column containing case numbers
results <- pacer_retrieve_cases(
  cases = "my_cases.csv",
  case_column = "case_number",  # Specify which column has case numbers
  circuit = "cadc",
  auth_token = token
)
```

### Network Discovery

Discover all related cases in a litigation network:

```r
# Simple discovery (finds immediate associations)
network <- pacer_discover_network(
  cases = c("20-1234", "20-1235"),
  circuit = "cadc",
  auth_token = token
)

# Recursive discovery (finds 2nd-degree connections)
network <- pacer_discover_network(
  cases = "my_cases.csv",
  case_column = "case_number",
  circuit = "cadc",
  recursive = TRUE,
  max_iterations = 2,
  auth_token = token
)

# Analyze discovered network
cat("Original cases:", length(network$original_cases), "\n")
cat("New cases found:", length(network$discovered_cases), "\n")
cat("Total network size:", length(network$all_unique_cases), "\n")

# View associations
View(network$associations)
```

## Circuit Codes

Common circuit codes for the `circuit` parameter:

| Code | Court |
|------|-------|
| `cadc` | DC Circuit Court of Appeals |
| `ca1` through `ca11` | Circuit Courts of Appeals 1-11 |
| `cafc` | Federal Circuit |
| `dcd` | DC District Court |

See [PACER documentation](https://pacer.uscourts.gov/) for complete list.

## Advanced Usage

### Custom Rate Limiting

```r
# Wait 8-12 seconds between each request
results <- pacer_retrieve_cases(
  cases = my_cases,
  circuit = "cadc",
  rate_limit_seconds = c(8, 12),
  auth_token = token
)

# Fixed 10-second wait
results <- pacer_retrieve_cases(
  cases = my_cases,
  circuit = "cadc",
  rate_limit_seconds = 10,
  auth_token = token
)
```

### Resume Interrupted Downloads

```r
# Automatically skips cases where XML already exists
results <- pacer_retrieve_cases(
  cases = my_cases,
  circuit = "cadc",
  output_dir = "my_xml_files",
  resume_if_exists = TRUE,  # Default
  auth_token = token
)
```

### Extract Associations from Existing XML

```r
# From XML file
associations <- pacer_extract_associations("docket_20_1234.xml")

# From XML content
xml_content <- readLines("docket_20_1234.xml")
associations <- pacer_extract_associations(xml_content)

# Process multiple files
xml_files <- list.files("xml_files", pattern = "\\.xml$", full.names = TRUE)
all_assoc <- purrr::map_dfr(xml_files, pacer_extract_associations)
```

## Output Files

### pacer_retrieve_cases()

Creates:
- `pacer_xml_output/` (or custom directory)
  - `docket_*.xml` - Full XML dockets for each case
  - `retrieval_log_final.csv` - Status of all retrieval attempts
  - `progress_log_*.csv` - Periodic progress saves

### pacer_discover_network()

Creates:
- `pacer_network_output/` (or custom directory)
  - `xml_files/` - All retrieved XML files
  - `case_associations.csv` - All discovered associations
  - `all_unique_cases.csv` - Complete list of cases in network
  - `newly_discovered_cases.csv` - Cases not in original input

## Tested Courts

**This tool has been tested and works with:**
- ✅ US Courts of Appeals (Circuit Courts) - tested with DC Circuit ("cadc")

**NOT extensively tested:**
- ⚠️ US District Courts
- ⚠️ Bankruptcy Courts  
- ⚠️ Other specialized courts

**If you use this with untested court types, verify fee exemption applies and monitor your account closely.**

## Understanding PACER Fees

### Fee Structure (Without Exemption)
- **Per-page cost**: $0.10 per page
- **Quarterly cap**: $30 maximum per user per quarter
- **XML downloads**: Typically charged
- **When charges apply**: Each docket retrieval

### Fee Exemptions
Research exemptions are available but:
- Must be applied for and approved
- May not apply to all court types
- Must be verified active before each use
- Can expire or be revoked
- Your responsibility to understand scope

**This tool CANNOT determine if your exemption is active or applicable.**

### Monitor Your Account
Check your PACER account regularly at https://pacer.uscourts.gov/

**The author has a research fee exemption that worked for Courts of Appeals. Your exemption may differ.**

## Responsible Use

### Rate Limiting

This package implements responsible rate limiting to avoid overloading court servers:
- Default: 5-10 second random wait between requests
- Configurable via `rate_limit_seconds` parameter
- Progress saved periodically to resume after interruptions

**Be respectful of court system resources.**

### Acceptable Use

**Permitted:**
- ✅ Academic research
- ✅ Legitimate legal research  
- ✅ Educational purposes with proper fee exemption

**Prohibited:**
- ❌ Bulk downloading for commercial resale
- ❌ Automated monitoring without exemption
- ❌ Any use violating PACER Terms of Service
- ❌ Use without understanding fee implications

**This tool is for research purposes only. PACER prohibits bulk commercial use. The author does not support or condone use for commercial, non-research, or bulk downloading purposes that violate PACER policies.**

### Terms of Service

Users MUST comply with:
- PACER Terms of Service: https://pacer.uscourts.gov/help/tos
- PACER Acceptable Use Policy
- All applicable court rules and regulations

**By using this software, you acknowledge:**
- You understand PACER's fee structure
- You are responsible for all charges
- You will verify fee exemption status
- You will monitor your account
- You accept all risks and responsibilities
- The author is NOT liable for any fees or misuse

## Citation

If you use this package in research, please cite:

```
Sacha Bechara (2024). pacerR: Automated Retrieval and Network Analysis of PACER Court Documents. 
R package version 0.1.0. https://github.com/sachabechara/pacerR
```

## Development

### Building the Package

```r
# Generate documentation
devtools::document()

# Check package
devtools::check()

# Install locally
devtools::install()

# Build vignettes
devtools::build_vignettes()
```

### Testing

```r
# Run tests
devtools::test()

# Test specific file
testthat::test_file("tests/testthat/test-authenticate.R")
```

## Related Work

- [CourtListener](https://www.courtlistener.com/) - Free legal opinion and docket data
- [RECAP](https://www.courtlistener.com/recap/) - PACER archive project

## Issues and Contributions

Please report bugs or request features via [GitHub Issues](https://github.com/sachabechara/pacerR/issues).

Contributions welcome via pull request. See `CONTRIBUTING.md` for guidelines.

## License

MIT License - see LICENSE file for details.

## Disclaimer

**READ THE LICENSE FILE COMPLETELY BEFORE USING THIS SOFTWARE.**

This software is provided AS-IS for academic research purposes with NO WARRANTIES.

**You are SOLELY responsible for:**
- All PACER fees and charges incurred
- Verifying fee exemption status and applicability  
- Monitoring your PACER account
- Complying with PACER Terms of Service
- Ensuring appropriate use of court data
- All risks associated with use of this software

**The author is NOT responsible for:**
- Any fees or charges to your PACER account
- Verification of fee exemptions
- Changes to PACER policies or fee structures
- Misuse or violations of PACER policies
- Use without proper understanding of fee implications

**This tool was developed for research on litigation in US federal courts. It has been tested on US Courts of Appeals and may behave differently on other court types.**

## Author

**Sacha Bechara**  
Email: sacha.bechara.23@ucl.ac.uk (until end of 2026)  
Alternative: sacha_bechara@aol.com

Developed as part of research on litigation networks in US federal courts.

## Acknowledgments

This tool was developed independently for academic research on federal court litigation patterns. It is not affiliated with or endorsed by PACER or the US Courts.
