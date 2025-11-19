#!/usr/bin/env Rscript
# Verification script for Phase 1 setup

cat("=================================================\n")
cat("Verifying Phase 1: Package Structure\n")
cat("=================================================\n\n")

# Check if we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Not in package root directory!")
}

cat("✓ Package root directory confirmed\n\n")

# Check required files
required_files <- c(
  "DESCRIPTION",
  "NAMESPACE",
  "LICENSE",
  "README.md",
  "NEWS.md",
  ".gitignore",
  ".Rbuildignore",
  "R/AsianOptPI-package.R",
  "src/Makevars",
  "src/Makevars.win",
  "tests/testthat.R"
)

cat("Checking required files:\n")
all_present <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat(sprintf("  ✓ %s\n", file))
  } else {
    cat(sprintf("  ✗ %s [MISSING]\n", file))
    all_present <- FALSE
  }
}

cat("\n")

if (!all_present) {
  stop("Some required files are missing!")
}

# Read and validate DESCRIPTION
cat("Validating DESCRIPTION file:\n")
desc <- read.dcf("DESCRIPTION")

# Check key fields
key_fields <- c("Package", "Title", "Version", "Authors@R", "Description",
                "License", "Imports", "LinkingTo")

for (field in key_fields) {
  if (field %in% colnames(desc)) {
    cat(sprintf("  ✓ %s: %s\n", field,
                substr(desc[1, field], 1, 50)))
  } else {
    cat(sprintf("  ✗ %s [MISSING]\n", field))
  }
}

cat("\n")

# Check that Rcpp is in both Imports and LinkingTo
if ("Rcpp" %in% strsplit(desc[1, "Imports"], ",\\s*")[[1]] &&
    "Rcpp" %in% strsplit(desc[1, "LinkingTo"], ",\\s*")[[1]]) {
  cat("✓ Rcpp properly configured in Imports and LinkingTo\n")
} else {
  cat("✗ Rcpp configuration issue\n")
}

# Check Git
cat("\nChecking Git repository:\n")
if (dir.exists(".git")) {
  cat("  ✓ Git repository initialized\n")

  # Check if there are commits
  exit_code <- system("git log -1 --oneline > /dev/null 2>&1")
  if (exit_code == 0) {
    cat("  ✓ Initial commit present\n")
  } else {
    cat("  ✗ No commits yet\n")
  }
} else {
  cat("  ✗ Git not initialized\n")
}

cat("\n=================================================\n")
cat("Phase 1 Verification Complete!\n")
cat("=================================================\n\n")

cat("Package structure is ready for Phase 2:\n")
cat("  - Core C++ implementation\n")
cat("  - R wrapper functions\n")
cat("  - Input validation\n\n")
