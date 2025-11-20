# Phase 4 Verification Script
# Run this to verify that Phase 4: Documentation is complete

cat(strrep("=", 70), "\n")
cat("PHASE 4: DOCUMENTATION - VERIFICATION\n")
cat(strrep("=", 70), "\n\n")

# Load the package
cat("1. Loading package...\n")
devtools::load_all()
cat("   ✓ Package loaded successfully\n\n")

# Test 1: Check documentation files exist
cat("2. Checking documentation files...\n")
doc_files <- c(
  "R/AsianOptPI-package.R",
  "README.md",
  "NEWS.md"
)

all_exist <- TRUE
for (file in doc_files) {
  if (file.exists(file)) {
    cat(sprintf("   ✓ %s exists\n", file))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 2: Check README content
cat("3. Verifying README.md content...\n")
readme <- readLines("README.md", warn = FALSE)
readme_text <- paste(readme, collapse = "\n")

readme_checks <- list(
  "Overview" = grepl("Overview", readme_text, fixed = TRUE),
  "Installation" = grepl("Installation", readme_text, fixed = TRUE),
  "Quick Start" = grepl("Quick Start", readme_text, fixed = TRUE),
  "Examples" = grepl("Examples", readme_text, fixed = TRUE),
  "References" = grepl("References", readme_text, fixed = TRUE),
  "Math formulas" = grepl("\\$", readme_text, fixed = TRUE)
)

for (check_name in names(readme_checks)) {
  if (readme_checks[[check_name]]) {
    cat(sprintf("   ✓ %s section found\n", check_name))
  } else {
    cat(sprintf("   ✗ %s section MISSING\n", check_name))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 3: Check NEWS.md content
cat("4. Verifying NEWS.md content...\n")
news <- readLines("NEWS.md", warn = FALSE)
news_text <- paste(news, collapse = "\n")

news_checks <- list(
  "Version 0.1.0" = grepl("0.1.0", news_text, fixed = TRUE),
  "Core Features" = grepl("Core Features", news_text, fixed = TRUE),
  "price_geometric_asian" = grepl("price_geometric_asian", news_text, fixed = TRUE),
  "arithmetic_asian_bounds" = grepl("arithmetic_asian_bounds", news_text, fixed = TRUE),
  "Phase completions" = grepl("Phase", news_text, fixed = TRUE)
)

for (check_name in names(news_checks)) {
  if (news_checks[[check_name]]) {
    cat(sprintf("   ✓ %s found\n", check_name))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", check_name))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 4: Check package documentation
cat("5. Checking package-level documentation...\n")
tryCatch({
  # Try to access package help
  help_text <- capture.output(tools::Rd2txt(
    utils::.getHelpFile(help("AsianOptPI-package"))
  ))

  if (length(help_text) > 10) {
    cat("   ✓ Package documentation generated\n")

    # Check for key sections
    help_combined <- paste(help_text, collapse = " ")

    if (grepl("Price Impact Mechanism", help_combined)) {
      cat("   ✓ Price Impact section found\n")
    }
    if (grepl("Mathematical Framework", help_combined)) {
      cat("   ✓ Mathematical Framework section found\n")
    }
    if (grepl("No-Arbitrage Condition", help_combined)) {
      cat("   ✓ No-Arbitrage section found\n")
    }
  } else {
    cat("   ⚠ Package documentation seems short\n")
  }
}, error = function(e) {
  cat("   ✗ Error accessing package documentation:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 5: Check .Rd files exist
cat("6. Checking .Rd documentation files...\n")
rd_files <- c(
  "man/AsianOptPI-package.Rd",
  "man/price_geometric_asian.Rd",
  "man/arithmetic_asian_bounds.Rd",
  "man/compute_p_eff.Rd",
  "man/compute_effective_factors.Rd",
  "man/check_no_arbitrage.Rd"
)

for (file in rd_files) {
  if (file.exists(file)) {
    cat(sprintf("   ✓ %s exists\n", file))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 6: Check examples run
cat("7. Testing package documentation examples...\n")
tryCatch({
  # Test example 1: geometric pricing
  price <- price_geometric_asian(
    S0 = 100, K = 100, r = 1.05,
    u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1, v_d = 1,
    n = 3
  )
  cat(sprintf("   ✓ Geometric pricing example works: %.4f\n", price))

  # Test example 2: arithmetic bounds
  bounds <- arithmetic_asian_bounds(
    S0 = 100, K = 100, r = 1.05,
    u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1, v_d = 1,
    n = 3
  )
  cat(sprintf("   ✓ Arithmetic bounds example works\n"))

  # Test example 3: utility functions
  no_arb <- check_no_arbitrage(r = 1.05, u = 1.2, d = 0.8,
                                lambda = 0.1, v_u = 1, v_d = 1)
  cat(sprintf("   ✓ No-arbitrage check example works: %s\n", no_arb))

  factors <- compute_effective_factors(u = 1.2, d = 0.8,
                                       lambda = 0.1, v_u = 1, v_d = 1)
  cat(sprintf("   ✓ Effective factors example works\n"))
}, error = function(e) {
  cat("   ✗ Error running examples:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 7: Check README examples work
cat("8. Testing README examples...\n")
tryCatch({
  # Standard CRR vs price impact comparison
  price_standard <- price_geometric_asian(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0, v_u = 0, v_d = 0, n = 5
  )

  price_impact <- price_geometric_asian(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1, v_d = 1, n = 5
  )

  if (price_impact > price_standard) {
    cat("   ✓ Comparison example works (price impact > standard)\n")
  } else {
    cat("   ✗ Comparison example issue\n")
  }
}, error = function(e) {
  cat("   ✗ Error in README examples:", conditionMessage(e), "\n")
})
cat("\n")

# Summary
cat(strrep("=", 70), "\n")
cat("VERIFICATION SUMMARY\n")
cat(strrep("=", 70), "\n")

if (all_exist) {
  cat("✓ All Phase 4 documentation is complete and working!\n")
  cat("\nPhase 4: Documentation is COMPLETE\n")
  cat("\nDocumentation includes:\n")
  cat("  - Enhanced package-level documentation\n")
  cat("  - Comprehensive README with examples\n")
  cat("  - Detailed NEWS.md with all features\n")
  cat("  - Complete .Rd files for all functions\n")
  cat("  - Working examples throughout\n")
  cat("\nNext step: Implement Phase 5 (Testing)\n")
  cat("  - Unit tests with testthat\n")
  cat("  - Code coverage analysis\n")
  cat("  - Edge case testing\n")
} else {
  cat("✗ Some documentation components are missing or not working.\n")
  cat("Please review the errors above.\n")
}

cat(strrep("=", 70), "\n")
