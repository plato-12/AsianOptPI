test_that("Arithmetic bounds satisfy inequality", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_true(bounds$lower_bound <= bounds$upper_bound)
})

test_that("Arithmetic bounds are non-negative", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_true(bounds$lower_bound >= 0)
  expect_true(bounds$upper_bound >= 0)
  expect_true(bounds$EQ_G >= 0)
})

test_that("Rho star is at least 1", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # By theory, rho_star >= 1
  expect_true(bounds$rho_star >= 1)
})

test_that("Lower bound equals geometric option price", {
  V_G <- price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_equal(bounds$lower_bound, V_G, tolerance = 1e-10)
  expect_equal(bounds$V0_G, V_G, tolerance = 1e-10)
})

test_that("Bounds object has correct structure", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_type(bounds, "list")
  expect_named(bounds, c("lower_bound", "upper_bound", "rho_star", "EQ_G", "V0_G"))

  expect_true(is.numeric(bounds$lower_bound))
  expect_true(is.numeric(bounds$upper_bound))
  expect_true(is.numeric(bounds$rho_star))
  expect_true(is.numeric(bounds$EQ_G))
  expect_true(is.numeric(bounds$V0_G))

  expect_length(bounds$lower_bound, 1)
  expect_length(bounds$upper_bound, 1)
})

test_that("Bounds object has correct class", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_s3_class(bounds, "arithmetic_bounds")
  expect_s3_class(bounds, "list")
})

test_that("Print method works for arithmetic_bounds", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_output(print(bounds), "Arithmetic Asian Option Bounds")
  expect_output(print(bounds), "Lower bound")
  expect_output(print(bounds), "Upper bound")
  expect_output(print(bounds), "Midpoint estimate")
  expect_output(print(bounds), "Spread")
  expect_output(print(bounds), "E\\^Q\\[G_n\\]")
})

test_that("Bounds tighten with lower volatility", {
  # Higher volatility
  bounds_high <- arithmetic_asian_bounds(100, 100, 1.05, 1.3, 0.7, 0.1, 1, 1, 3)
  spread_high <- bounds_high$upper_bound - bounds_high$lower_bound

  # Lower volatility
  bounds_low <- arithmetic_asian_bounds(100, 100, 1.05, 1.1, 0.9, 0.1, 1, 1, 3)
  spread_low <- bounds_low$upper_bound - bounds_low$lower_bound

  # Lower volatility should have tighter bounds
  expect_true(spread_low < spread_high)
})

test_that("Expected geometric average is positive", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_true(bounds$EQ_G > 0)
  expect_false(is.na(bounds$EQ_G))
  expect_false(is.infinite(bounds$EQ_G))
})

test_that("Bounds scale with initial stock price", {
  # S0 = 100
  bounds_100 <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # S0 = 200 (double)
  bounds_200 <- arithmetic_asian_bounds(200, 200, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # Bounds should roughly scale (not exactly linear for Asian options)
  expect_true(bounds_200$lower_bound > bounds_100$lower_bound)
  expect_true(bounds_200$upper_bound > bounds_100$upper_bound)
  expect_true(bounds_200$EQ_G > bounds_100$EQ_G)
})

test_that("ITM options have higher bounds", {
  # ITM (K < S0)
  bounds_itm <- arithmetic_asian_bounds(100, 80, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # ATM (K = S0)
  bounds_atm <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # OTM (K > S0)
  bounds_otm <- arithmetic_asian_bounds(100, 120, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_true(bounds_itm$lower_bound > bounds_atm$lower_bound)
  expect_true(bounds_atm$lower_bound > bounds_otm$lower_bound)
})

test_that("Rho star increases with volatility spread", {
  # Low volatility
  bounds_low <- arithmetic_asian_bounds(100, 100, 1.05, 1.1, 0.9, 0.1, 1, 1, 3)

  # High volatility
  bounds_high <- arithmetic_asian_bounds(100, 100, 1.05, 1.3, 0.7, 0.1, 1, 1, 3)

  # Higher volatility spread should increase rho_star
  expect_true(bounds_high$rho_star > bounds_low$rho_star)
})

test_that("Bounds work for n=1 case", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 1)

  expect_true(bounds$lower_bound >= 0)
  expect_true(bounds$upper_bound >= bounds$lower_bound)
  expect_true(bounds$rho_star >= 1)
})

test_that("Bounds work for various n values", {
  for (n in c(1, 2, 3, 5, 8, 10)) {
    bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, n)

    expect_true(bounds$lower_bound >= 0, info = paste("n =", n))
    expect_true(bounds$upper_bound >= bounds$lower_bound, info = paste("n =", n))
    expect_true(bounds$rho_star >= 1, info = paste("n =", n))
    expect_true(bounds$EQ_G > 0, info = paste("n =", n))
  }
})

test_that("Price impact increases bounds", {
  # No price impact
  bounds_no <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 3)

  # With price impact
  bounds_yes <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  # Price impact should increase lower bound (and typically upper bound)
  expect_true(bounds_yes$lower_bound >= bounds_no$lower_bound)
})

test_that("Midpoint is between bounds", {
  bounds <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  midpoint <- mean(c(bounds$lower_bound, bounds$upper_bound))

  expect_true(midpoint >= bounds$lower_bound)
  expect_true(midpoint <= bounds$upper_bound)
})

test_that("Results are reproducible", {
  bounds1 <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)
  bounds2 <- arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3)

  expect_equal(bounds1$lower_bound, bounds2$lower_bound)
  expect_equal(bounds1$upper_bound, bounds2$upper_bound)
  expect_equal(bounds1$rho_star, bounds2$rho_star)
  expect_equal(bounds1$EQ_G, bounds2$EQ_G)
})
