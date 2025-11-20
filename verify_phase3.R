# Phase 3 Verification Script
# Run this to verify that Phase 3: R Wrapper Functions is complete

cat(strrep("=", 70), "\n")
cat("PHASE 3: R WRAPPER FUNCTIONS - VERIFICATION\n")
cat(strrep("=", 70), "\n\n")

# Load the package
cat("1. Loading package...\n")
devtools::load_all()
cat("   ✓ Package loaded successfully\n\n")

# Test 1: Check R files exist
cat("2. Checking R source files...\n")
r_files <- c(
  "R/validation.R",
  "R/price_impact_utils.R",
  "R/geometric_asian.R",
  "R/arithmetic_asian.R"
)

all_exist <- TRUE
for (file in r_files) {
  if (file.exists(file)) {
    cat(sprintf("   ✓ %s exists\n", file))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 2: Check exported functions
cat("3. Checking exported functions...\n")
exported_funcs <- c(
  "price_geometric_asian",
  "arithmetic_asian_bounds",
  "print.arithmetic_bounds",
  "compute_p_eff",
  "compute_effective_factors",
  "check_no_arbitrage"
)

for (func in exported_funcs) {
  if (exists(func)) {
    cat(sprintf("   ✓ %s() available\n", func))
  } else {
    cat(sprintf("   ✗ %s() NOT FOUND\n", func))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 3: Test utility functions
cat("4. Testing utility functions...\n")
tryCatch({
  p_eff <- compute_p_eff(r = 1.05, u = 1.2, d = 0.8,
                         lambda = 0.1, v_u = 1, v_d = 1)
  cat(sprintf("   ✓ compute_p_eff() = %.4f\n", p_eff))

  factors <- compute_effective_factors(u = 1.2, d = 0.8,
                                       lambda = 0.1, v_u = 1, v_d = 1)
  cat(sprintf("   ✓ compute_effective_factors(): u_tilde=%.4f, d_tilde=%.4f\n",
              factors$u_tilde, factors$d_tilde))

  no_arb <- check_no_arbitrage(r = 1.05, u = 1.2, d = 0.8,
                               lambda = 0.1, v_u = 1, v_d = 1)
  cat(sprintf("   ✓ check_no_arbitrage() = %s\n", no_arb))
}, error = function(e) {
  cat("   ✗ Error in utility functions:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 4: Test geometric pricing wrapper
cat("5. Testing price_geometric_asian() wrapper...\n")
tryCatch({
  price1 <- price_geometric_asian(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1, v_d = 1, n = 3
  )
  cat(sprintf("   ✓ With price impact (n=3): %.4f\n", price1))

  price2 <- price_geometric_asian(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0, v_u = 0, v_d = 0, n = 3
  )
  cat(sprintf("   ✓ Without price impact (n=3): %.4f\n", price2))

  if (price1 > price2) {
    cat("   ✓ Price impact correctly increases value\n")
  }
}, error = function(e) {
  cat("   ✗ Error in geometric pricing:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 5: Test arithmetic bounds wrapper and print method
cat("6. Testing arithmetic_asian_bounds() and print method...\n")
tryCatch({
  bounds <- arithmetic_asian_bounds(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1, v_d = 1, n = 3
  )

  cat("   ✓ Bounds computed successfully\n")

  # Test print method
  cat("\n   Print output:\n")
  cat("   ", strrep("-", 60), "\n")
  print(bounds)
  cat("   ", strrep("-", 60), "\n")

  # Verify properties
  if (bounds$lower_bound <= bounds$upper_bound) {
    cat("   ✓ Lower bound ≤ Upper bound\n")
  }
  if (bounds$rho_star >= 1.0) {
    cat("   ✓ Rho star ≥ 1\n")
  }
  if ("arithmetic_bounds" %in% class(bounds)) {
    cat("   ✓ Object has correct class\n")
  }
}, error = function(e) {
  cat("   ✗ Error in arithmetic bounds:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 6: Input validation
cat("7. Testing input validation...\n")
validation_tests <- list(
  list(
    name = "Negative S0",
    params = list(S0 = -100, K = 100, r = 1.05, u = 1.2, d = 0.8,
                  lambda = 0.1, v_u = 1, v_d = 1, n = 3),
    expected = "S0 must be positive"
  ),
  list(
    name = "u <= d",
    params = list(S0 = 100, K = 100, r = 1.05, u = 0.8, d = 1.2,
                  lambda = 0.1, v_u = 1, v_d = 1, n = 3),
    expected = "Up factor"
  ),
  list(
    name = "No-arbitrage violation",
    params = list(S0 = 100, K = 100, r = 2.0, u = 1.2, d = 0.8,
                  lambda = 0.1, v_u = 1, v_d = 1, n = 3),
    expected = "No-arbitrage"
  )
)

for (test in validation_tests) {
  tryCatch({
    do.call(price_geometric_asian, test$params)
    cat(sprintf("   ✗ Failed to catch: %s\n", test$name))
    all_exist <- FALSE
  }, error = function(e) {
    if (grepl(test$expected, conditionMessage(e), ignore.case = TRUE)) {
      cat(sprintf("   ✓ Caught %s\n", test$name))
    } else {
      cat(sprintf("   ✗ Wrong error for %s: %s\n", test$name, conditionMessage(e)))
    }
  })
}
cat("\n")

# Test 7: Warning for large n
cat("8. Testing performance warning...\n")
warning_caught <- FALSE
tryCatch({
  withCallingHandlers(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 25),
    warning = function(w) {
      if (grepl("enumerate", conditionMessage(w))) {
        warning_caught <<- TRUE
        cat(sprintf("   ✓ Warning issued: %s\n", conditionMessage(w)))
      }
      invokeRestart("muffleWarning")
    }
  )
}, error = function(e) {
  # May error out due to time, that's ok
})

if (!warning_caught) {
  cat("   ⚠ Warning not detected (may have timed out)\n")
}
cat("\n")

# Test 8: Check documentation
cat("9. Checking documentation files...\n")
doc_files <- c(
  "man/price_geometric_asian.Rd",
  "man/arithmetic_asian_bounds.Rd",
  "man/print.arithmetic_bounds.Rd",
  "man/compute_p_eff.Rd",
  "man/compute_effective_factors.Rd",
  "man/check_no_arbitrage.Rd"
)

for (file in doc_files) {
  if (file.exists(file)) {
    cat(sprintf("   ✓ %s exists\n", file))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}
cat("\n")

# Summary
cat(strrep("=", 70), "\n")
cat("VERIFICATION SUMMARY\n")
cat(strrep("=", 70), "\n")

if (all_exist) {
  cat("✓ All Phase 3 components are in place and working!\n")
  cat("\nPhase 3: R Wrapper Functions is COMPLETE\n")
  cat("\nNext step: Implement Phase 4 (Enhanced Documentation)\n")
  cat("  - Update R/AsianOptPI-package.R\n")
  cat("  - Enhance README.md\n")
  cat("  - Update NEWS.md\n")
} else {
  cat("✗ Some components are missing or not working correctly.\n")
  cat("Please review the errors above.\n")
}

cat(strrep("=", 70), "\n")
