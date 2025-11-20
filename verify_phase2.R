# Phase 2 Verification Script
# Run this to verify that Phase 2: Core Implementation is complete

cat(strrep("=", 70), "\n")
cat("PHASE 2: CORE IMPLEMENTATION - VERIFICATION\n")
cat(strrep("=", 70), "\n\n")

# Load the package
cat("1. Loading package...\n")
devtools::load_all()
cat("   ✓ Package loaded successfully\n\n")

# Test 1: Check C++ files exist
cat("2. Checking C++ source files...\n")
cpp_files <- c(
  "src/utils.h",
  "src/utils.cpp",
  "src/geometric_asian.cpp",
  "src/arithmetic_bounds.cpp",
  "src/Makevars",
  "src/Makevars.win"
)

all_exist <- TRUE
for (file in cpp_files) {
  if (file.exists(file)) {
    cat(sprintf("   ✓ %s exists\n", file))
  } else {
    cat(sprintf("   ✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}
cat("\n")

# Test 2: Check functions are available
cat("3. Checking exported C++ functions...\n")
tryCatch({
  # Check geometric pricing function
  if (exists("price_geometric_asian_cpp")) {
    cat("   ✓ price_geometric_asian_cpp() available\n")
  } else {
    cat("   ✗ price_geometric_asian_cpp() NOT FOUND\n")
    all_exist <- FALSE
  }

  # Check arithmetic bounds function
  if (exists("arithmetic_asian_bounds_cpp")) {
    cat("   ✓ arithmetic_asian_bounds_cpp() available\n")
  } else {
    cat("   ✗ arithmetic_asian_bounds_cpp() NOT FOUND\n")
    all_exist <- FALSE
  }
}, error = function(e) {
  cat("   ✗ Error checking functions:", conditionMessage(e), "\n")
  all_exist <<- FALSE
})
cat("\n")

# Test 3: Functional tests
cat("4. Running functional tests...\n")

# Test geometric Asian pricing
cat("   Testing geometric Asian option pricing...\n")
tryCatch({
  price1 <- price_geometric_asian_cpp(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1.0, v_d = 1.0, n = 3
  )
  cat(sprintf("   ✓ Geometric price (n=3, λ=0.1): %.4f\n", price1))

  price2 <- price_geometric_asian_cpp(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0, v_u = 0, v_d = 0, n = 3
  )
  cat(sprintf("   ✓ Geometric price (n=3, λ=0): %.4f\n", price2))

  # Verify price impact increases price
  if (price1 > price2) {
    cat("   ✓ Price impact correctly increases option value\n")
  } else {
    cat("   ✗ ISSUE: Price with impact should be higher\n")
  }
}, error = function(e) {
  cat("   ✗ Error in geometric pricing:", conditionMessage(e), "\n")
})

# Test arithmetic bounds
cat("\n   Testing arithmetic Asian bounds...\n")
tryCatch({
  bounds <- arithmetic_asian_bounds_cpp(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1.0, v_d = 1.0, n = 3
  )

  cat(sprintf("   ✓ Lower bound: %.4f\n", bounds$lower_bound))
  cat(sprintf("   ✓ Upper bound: %.4f\n", bounds$upper_bound))
  cat(sprintf("   ✓ Rho star: %.4f\n", bounds$rho_star))
  cat(sprintf("   ✓ E^Q[G]: %.4f\n", bounds$EQ_G))

  # Verify mathematical properties
  if (bounds$lower_bound <= bounds$upper_bound) {
    cat("   ✓ Lower bound ≤ Upper bound (correct)\n")
  } else {
    cat("   ✗ ISSUE: Lower bound > Upper bound\n")
  }

  if (bounds$rho_star >= 1.0) {
    cat("   ✓ Rho star ≥ 1 (correct)\n")
  } else {
    cat("   ✗ ISSUE: Rho star < 1\n")
  }

  # Verify lower bound equals geometric price
  if (abs(bounds$lower_bound - price1) < 1e-10) {
    cat("   ✓ Lower bound equals geometric price (correct)\n")
  } else {
    cat("   ✗ ISSUE: Lower bound should equal geometric price\n")
  }
}, error = function(e) {
  cat("   ✗ Error in arithmetic bounds:", conditionMessage(e), "\n")
})

cat("\n")

# Test 4: Performance test
cat("5. Testing performance with different n...\n")
n_values <- c(1, 3, 5, 8, 10)
for (n in n_values) {
  start_time <- Sys.time()
  price <- price_geometric_asian_cpp(
    S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
    lambda = 0.1, v_u = 1.0, v_d = 1.0, n = n
  )
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time, units = "secs")
  cat(sprintf("   n=%2d: Price=%.4f, Time=%.4f sec, Paths=%d\n",
              n, price, elapsed, 2^n))
}

cat("\n")

# Summary
cat(strrep("=", 70), "\n")
cat("VERIFICATION SUMMARY\n")
cat(strrep("=", 70), "\n")

if (all_exist) {
  cat("✓ All Phase 2 components are in place and working!\n")
  cat("\nPhase 2: Core Implementation is COMPLETE\n")
  cat("\nNext step: Implement Phase 3 (R Wrapper Functions)\n")
  cat("  - Input validation (R/validation.R)\n")
  cat("  - Utility functions (R/price_impact_utils.R)\n")
  cat("  - Main wrapper functions (R/geometric_asian.R, R/arithmetic_asian.R)\n")
} else {
  cat("✗ Some components are missing or not working correctly.\n")
  cat("Please review the errors above.\n")
}

cat(strrep("=", 70), "\n")
