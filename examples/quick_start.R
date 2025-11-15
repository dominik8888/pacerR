# ============================================
# QUICK START EXAMPLE FOR pacerR
# ============================================
# This script demonstrates basic usage after package installation

library(pacerR)

# ============================================
# SETUP (DO THIS ONCE)
# ============================================

# 1. Set up your credentials (choose ONE method):

# Method A: Environment variables (RECOMMENDED)
# Add to .Renviron file:
# PACER_USERNAME=your_username
# PACER_PASSWORD=your_password
# Then restart R

# Method B: Set in current session only
# Sys.setenv(PACER_USERNAME = "your_username")
# Sys.setenv(PACER_PASSWORD = "your_password")

# ============================================
# AUTHENTICATE
# ============================================

# If credentials are in environment variables:
token <- pacer_authenticate()

# Or provide directly (not recommended for scripts):
# token <- pacer_authenticate(
#   username = "your_username",
#   password = "your_password"
# )

# ============================================
# EXAMPLE 1: Retrieve a Few Cases
# ============================================

# Retrieve specific case numbers
results <- pacer_retrieve_cases(
  cases = c("20-1234", "20-1235"),  # Replace with real case numbers
  circuit = "cadc",                  # DC Circuit
  output_dir = "test_output",
  auth_token = token,
  verbose = TRUE
)

# View results
View(results)
table(results$status)

# ============================================
# EXAMPLE 2: Retrieve from CSV
# ============================================

# Create example CSV
example_cases <- data.frame(
  case_number = c("20-1234", "20-1235", "20-1236"),
  case_name = c("Case A", "Case B", "Case C")
)
write.csv(example_cases, "example_cases.csv", row.names = FALSE)

# Retrieve from CSV
results_csv <- pacer_retrieve_cases(
  cases = "example_cases.csv",
  case_column = "case_number",
  circuit = "cadc",
  output_dir = "test_output",
  auth_token = token
)

# ============================================
# EXAMPLE 3: Extract Associations
# ============================================

# Extract from downloaded XML files
library(purrr)

xml_files <- list.files("test_output", 
                       pattern = "\\.xml$", 
                       full.names = TRUE)

if (length(xml_files) > 0) {
  # Process all XML files
  all_associations <- map_dfr(xml_files, pacer_extract_associations)
  
  # View associations
  View(all_associations)
  
  # How many associations found?
  cat("Total associations:", nrow(all_associations), "\n")
  
  # Types of associations
  table(all_associations$associationType)
}

# ============================================
# EXAMPLE 4: Network Discovery
# ============================================

# Discover complete network (no recursion)
network <- pacer_discover_network(
  cases = c("20-1234", "20-1235"),
  circuit = "cadc",
  output_dir = "network_output",
  auth_token = token,
  recursive = FALSE
)

# Summary of network
cat("\n=== NETWORK SUMMARY ===\n")
cat("Original cases:", length(network$original_cases), "\n")
cat("Discovered cases:", length(network$discovered_cases), "\n")
cat("Total unique cases:", length(network$all_unique_cases), "\n")

# View associations
View(network$associations)

# ============================================
# EXAMPLE 5: Recursive Network Discovery
# ============================================

# Find second-degree connections
network_recursive <- pacer_discover_network(
  cases = "example_cases.csv",
  case_column = "case_number",
  circuit = "cadc",
  output_dir = "network_recursive_output",
  auth_token = token,
  recursive = TRUE,
  max_iterations = 2
)

# What did we find?
cat("\n=== RECURSIVE NETWORK ===\n")
cat("Original:", length(network_recursive$original_cases), "\n")
cat("New discoveries:", length(network_recursive$discovered_cases), "\n")
cat("Total network:", length(network_recursive$all_unique_cases), "\n")

# ============================================
# EXAMPLE 6: Network Analysis
# ============================================

library(igraph)
library(dplyr)

# Prepare data for network analysis
edges <- network_recursive$associations %>%
  filter(!is.na(associatedCase)) %>%
  select(from = mainCase, to = associatedCase)

# Create network graph
g <- graph_from_data_frame(edges, directed = FALSE)

# Network statistics
cat("\n=== NETWORK METRICS ===\n")
cat("Nodes:", vcount(g), "\n")
cat("Edges:", ecount(g), "\n")
cat("Density:", edge_density(g), "\n")
cat("Components:", components(g)$no, "\n")

# Find most central cases
centrality <- data.frame(
  case = V(g)$name,
  degree = degree(g),
  betweenness = betweenness(g)
) %>%
  arrange(desc(degree))

cat("\nMost connected cases:\n")
print(head(centrality, 10))

# Visualize (basic)
plot(g, 
     vertex.size = 5,
     vertex.label.cex = 0.6,
     main = "Case Network")

# ============================================
# CLEANUP
# ============================================

# Note: This will delete test files!
# unlink("test_output", recursive = TRUE)
# unlink("network_output", recursive = TRUE)
# unlink("network_recursive_output", recursive = TRUE)
# unlink("example_cases.csv")

cat("\n✓ Examples complete!\n")
