test_that("compute_p_eff returns valid probability", {
  p_eff <- compute_p_eff(1.05, 1.2, 0.8, 0.1, 1, 1)

  expect_true(is.numeric(p_eff))
  expect_length(p_eff, 1)
  expect_true(p_eff >= 0 && p_eff <= 1)
  expect_false(is.na(p_eff))
})

test_that("compute_p_eff handles zero price impact", {
  # With lambda = 0, should give standard CRR probability
  p_eff <- compute_p_eff(1.05, 1.2, 0.8, 0, 0, 0)

  # Standard p = (r - d)/(u - d)
  p_standard <- (1.05 - 0.8)/(1.2 - 0.8)

  expect_equal(p_eff, p_standard, tolerance = 1e-10)
})

test_that("compute_p_eff changes with price impact", {
  p_eff_no_impact <- compute_p_eff(1.05, 1.2, 0.8, 0, 0, 0)
  p_eff_with_impact <- compute_p_eff(1.05, 1.2, 0.8, 0.1, 1, 1)

  # Should be different
  expect_false(p_eff_no_impact == p_eff_with_impact)
})

test_that("compute_effective_factors returns correct structure", {
  factors <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)

  expect_type(factors, "list")
  expect_named(factors, c("u_tilde", "d_tilde"))
  expect_length(factors$u_tilde, 1)
  expect_length(factors$d_tilde, 1)
  expect_true(is.numeric(factors$u_tilde))
  expect_true(is.numeric(factors$d_tilde))
})

test_that("Effective factors satisfy ordering", {
  factors <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)

  # u_tilde should be > d_tilde
  expect_true(factors$u_tilde > factors$d_tilde)
})

test_that("Effective up factor increases with price impact", {
  factors_no_impact <- compute_effective_factors(1.2, 0.8, 0, 0, 0)
  factors_with_impact <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)

  # u_tilde should increase
  expect_true(factors_with_impact$u_tilde > factors_no_impact$u_tilde)
  expect_equal(factors_no_impact$u_tilde, 1.2, tolerance = 1e-10)
})

test_that("Effective down factor decreases with price impact", {
  factors_no_impact <- compute_effective_factors(1.2, 0.8, 0, 0, 0)
  factors_with_impact <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)

  # d_tilde should decrease
  expect_true(factors_with_impact$d_tilde < factors_no_impact$d_tilde)
  expect_equal(factors_no_impact$d_tilde, 0.8, tolerance = 1e-10)
})

test_that("Effective factors match formula", {
  u <- 1.2
  d <- 0.8
  lambda <- 0.1
  v_u <- 1
  v_d <- 1

  factors <- compute_effective_factors(u, d, lambda, v_u, v_d)

  # Manual calculation
  u_tilde_expected <- u * exp(lambda * v_u)
  d_tilde_expected <- d * exp(-lambda * v_d)

  expect_equal(factors$u_tilde, u_tilde_expected, tolerance = 1e-10)
  expect_equal(factors$d_tilde, d_tilde_expected, tolerance = 1e-10)
})

test_that("check_no_arbitrage correctly identifies valid cases", {
  # Valid case: d_tilde < r < u_tilde
  result <- check_no_arbitrage(1.05, 1.2, 0.8, 0.1, 1, 1)

  expect_true(is.logical(result))
  expect_length(result, 1)
  expect_true(result)
})

test_that("check_no_arbitrage detects r too high", {
  # Invalid: r >= u_tilde
  result <- check_no_arbitrage(2.0, 1.2, 0.8, 0.1, 1, 1)

  expect_false(result)
})

test_that("check_no_arbitrage detects r too low", {
  # Invalid: d_tilde >= r
  result <- check_no_arbitrage(0.5, 1.2, 0.8, 0.1, 1, 1)

  expect_false(result)
})

test_that("check_no_arbitrage works with zero price impact", {
  # Standard CRR: d < r < u
  result <- check_no_arbitrage(1.05, 1.2, 0.8, 0, 0, 0)

  expect_true(result)
})

test_that("check_no_arbitrage handles edge cases", {
  # r exactly at boundary should fail
  # First compute what u_tilde would be
  u_tilde <- 1.2 * exp(0.1 * 1)

  result <- check_no_arbitrage(u_tilde, 1.2, 0.8, 0.1, 1, 1)

  expect_false(result)  # r must be strictly less than u_tilde
})

test_that("Utility functions work together consistently", {
  r <- 1.05
  u <- 1.2
  d <- 0.8
  lambda <- 0.1
  v_u <- 1
  v_d <- 1

  # Get effective factors
  factors <- compute_effective_factors(u, d, lambda, v_u, v_d)

  # Compute p_eff
  p_eff <- compute_p_eff(r, u, d, lambda, v_u, v_d)

  # Manual calculation of p_eff from factors
  p_eff_manual <- (r - factors$d_tilde) / (factors$u_tilde - factors$d_tilde)

  expect_equal(p_eff, p_eff_manual, tolerance = 1e-10)

  # Check no-arbitrage
  no_arb <- check_no_arbitrage(r, u, d, lambda, v_u, v_d)

  expect_true(no_arb)

  # If no-arbitrage holds, p_eff should be in [0,1]
  expect_true(p_eff >= 0)
  expect_true(p_eff <= 1)
})

test_that("Increasing lambda affects factors appropriately", {
  lambdas <- c(0, 0.1, 0.2, 0.3)
  u_tildes <- numeric(length(lambdas))
  d_tildes <- numeric(length(lambdas))

  for (i in seq_along(lambdas)) {
    factors <- compute_effective_factors(1.2, 0.8, lambdas[i], 1, 1)
    u_tildes[i] <- factors$u_tilde
    d_tildes[i] <- factors$d_tilde
  }

  # u_tilde should be increasing
  expect_true(all(diff(u_tildes) > 0))

  # d_tilde should be decreasing
  expect_true(all(diff(d_tildes) < 0))
})

test_that("Asymmetric volumes handled correctly", {
  # Different volumes
  factors <- compute_effective_factors(1.2, 0.8, 0.1, 0.5, 1.5)

  expect_true(is.numeric(factors$u_tilde))
  expect_true(is.numeric(factors$d_tilde))
  expect_true(factors$u_tilde > factors$d_tilde)
})

test_that("Very small price impact behaves correctly", {
  # Very small lambda
  factors <- compute_effective_factors(1.2, 0.8, 0.001, 1, 1)

  # Should be very close to base factors
  expect_equal(factors$u_tilde, 1.2, tolerance = 0.01)
  expect_equal(factors$d_tilde, 0.8, tolerance = 0.01)
})

test_that("compute_p_eff is consistent with manual calculation", {
  r <- 1.05
  u <- 1.2
  d <- 0.8
  lambda <- 0.15
  v_u <- 0.8
  v_d <- 1.2

  # Using function
  p_eff_func <- compute_p_eff(r, u, d, lambda, v_u, v_d)

  # Manual calculation
  u_tilde <- u * exp(lambda * v_u)
  d_tilde <- d * exp(-lambda * v_d)
  p_eff_manual <- (r - d_tilde) / (u_tilde - d_tilde)

  expect_equal(p_eff_func, p_eff_manual, tolerance = 1e-12)
})

test_that("Results are reproducible", {
  # Test reproducibility of all utility functions
  p1 <- compute_p_eff(1.05, 1.2, 0.8, 0.1, 1, 1)
  p2 <- compute_p_eff(1.05, 1.2, 0.8, 0.1, 1, 1)
  expect_equal(p1, p2)

  f1 <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)
  f2 <- compute_effective_factors(1.2, 0.8, 0.1, 1, 1)
  expect_equal(f1, f2)

  c1 <- check_no_arbitrage(1.05, 1.2, 0.8, 0.1, 1, 1)
  c2 <- check_no_arbitrage(1.05, 1.2, 0.8, 0.1, 1, 1)
  expect_equal(c1, c2)
})
