# ============================================================================
# BLACK-SCHOLES OPTION PRICING TESTS
# ============================================================================
# Tests for Black-Scholes analytical formulas (continuous-time benchmark)

# ============================================================================
# CALL OPTION TESTS
# ============================================================================

test_that("Black-Scholes call option has correct properties", {
  # Basic computation
  price <- price_black_scholes_call(S0 = 100, K = 100, r = 0.05,
                                     sigma = 0.2, time_to_maturity = 1)

  expect_true(is.numeric(price))
  expect_true(price > 0)
  expect_length(price, 1)
  expect_false(is.na(price))
  expect_false(is.infinite(price))
})

test_that("BS call price decreases as strike increases", {
  # Monotonicity in strike
  price_K90 <- price_black_scholes_call(100, 90, 0.05, 0.2, 1)
  price_K100 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price_K110 <- price_black_scholes_call(100, 110, 0.05, 0.2, 1)

  expect_true(price_K90 > price_K100)
  expect_true(price_K100 > price_K110)
})

test_that("BS call price increases with initial stock price", {
  # Monotonicity in S0
  price_S90 <- price_black_scholes_call(90, 100, 0.05, 0.2, 1)
  price_S100 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price_S110 <- price_black_scholes_call(110, 100, 0.05, 0.2, 1)

  expect_true(price_S90 < price_S100)
  expect_true(price_S100 < price_S110)
})

test_that("BS call price increases with volatility", {
  # Volatility effect (vega positive)
  price_low_vol <- price_black_scholes_call(100, 100, 0.05, 0.1, 1)
  price_mid_vol <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price_high_vol <- price_black_scholes_call(100, 100, 0.05, 0.3, 1)

  expect_true(price_low_vol < price_mid_vol)
  expect_true(price_mid_vol < price_high_vol)
})

test_that("BS call price increases with time to maturity", {
  # Time value (theta)
  price_T025 <- price_black_scholes_call(100, 100, 0.05, 0.2, 0.25)
  price_T05 <- price_black_scholes_call(100, 100, 0.05, 0.2, 0.5)
  price_T1 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1.0)

  expect_true(price_T025 < price_T05)
  expect_true(price_T05 < price_T1)
})

test_that("BS call price increases with interest rate", {
  # Rho positive for calls
  price_r001 <- price_black_scholes_call(100, 100, 0.01, 0.2, 1)
  price_r005 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price_r010 <- price_black_scholes_call(100, 100, 0.10, 0.2, 1)

  expect_true(price_r001 < price_r005)
  expect_true(price_r005 < price_r010)
})

test_that("BS call with zero volatility gives discounted intrinsic value", {
  # Zero volatility: deterministic stock price
  S0 <- 100
  K <- 100
  r <- 0.05
  T <- 1

  price <- price_black_scholes_call(S0, K, r, sigma = 0, T)

  # S_T = S0 * exp(r*T)
  S_T <- S0 * exp(r * T)
  expected <- max(0, S_T - K) * exp(-r * T)

  expect_equal(price, expected, tolerance = 1e-10)
})

test_that("BS call deep ITM approaches intrinsic value", {
  # Very low strike -> deep in-the-money
  S0 <- 100
  K <- 50
  price <- price_black_scholes_call(S0, K, 0.05, 0.2, 1)

  # Should be approximately S0 - K * exp(-r*T)
  intrinsic <- S0 - K * exp(-0.05 * 1)

  expect_true(price > intrinsic)  # Time value adds to intrinsic
  expect_true(price < S0)  # Can't exceed stock price
  expect_true(price > 40)  # Should be substantial
})

test_that("BS call deep OTM has small value", {
  # Very high strike -> deep out-of-the-money
  price <- price_black_scholes_call(100, 200, 0.05, 0.2, 1)

  expect_true(price < 1)
  expect_true(price >= 0)
})

test_that("BS call ATM has intermediate value", {
  # At-the-money options have maximum time value
  price_itm <- price_black_scholes_call(100, 80, 0.05, 0.2, 1)
  price_atm <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price_otm <- price_black_scholes_call(100, 120, 0.05, 0.2, 1)

  expect_true(price_atm > price_otm)
  expect_true(price_atm < price_itm)
})

test_that("BS call input validation works", {
  # Negative S0
  expect_error(
    price_black_scholes_call(-100, 100, 0.05, 0.2, 1),
    "S0 must be a positive number"
  )

  # Negative K
  expect_error(
    price_black_scholes_call(100, -100, 0.05, 0.2, 1),
    "K must be a positive number"
  )

  # Negative sigma
  expect_error(
    price_black_scholes_call(100, 100, 0.05, -0.2, 1),
    "sigma must be a non-negative number"
  )

  # Negative T
  expect_error(
    price_black_scholes_call(100, 100, 0.05, 0.2, -1),
    "time_to_maturity must be a positive number"
  )

  # Zero T
  expect_error(
    price_black_scholes_call(100, 100, 0.05, 0.2, 0),
    "time_to_maturity must be a positive number"
  )
})

test_that("BS call results are reproducible", {
  price1 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)
  price2 <- price_black_scholes_call(100, 100, 0.05, 0.2, 1)

  expect_equal(price1, price2)
})

# ============================================================================
# PUT OPTION TESTS
# ============================================================================

test_that("Black-Scholes put option has correct properties", {
  # Basic computation
  price <- price_black_scholes_put(S0 = 100, K = 100, r = 0.05,
                                    sigma = 0.2, time_to_maturity = 1)

  expect_true(is.numeric(price))
  expect_true(price > 0)
  expect_length(price, 1)
  expect_false(is.na(price))
  expect_false(is.infinite(price))
})

test_that("BS put price increases as strike increases", {
  # Monotonicity in strike (opposite of call)
  price_K90 <- price_black_scholes_put(100, 90, 0.05, 0.2, 1)
  price_K100 <- price_black_scholes_put(100, 100, 0.05, 0.2, 1)
  price_K110 <- price_black_scholes_put(100, 110, 0.05, 0.2, 1)

  expect_true(price_K90 < price_K100)
  expect_true(price_K100 < price_K110)
})

test_that("BS put price decreases with initial stock price", {
  # Monotonicity in S0 (opposite of call)
  price_S90 <- price_black_scholes_put(90, 100, 0.05, 0.2, 1)
  price_S100 <- price_black_scholes_put(100, 100, 0.05, 0.2, 1)
  price_S110 <- price_black_scholes_put(110, 100, 0.05, 0.2, 1)

  expect_true(price_S90 > price_S100)
  expect_true(price_S100 > price_S110)
})

test_that("BS put price increases with volatility", {
  # Volatility effect (vega positive)
  price_low_vol <- price_black_scholes_put(100, 100, 0.05, 0.1, 1)
  price_mid_vol <- price_black_scholes_put(100, 100, 0.05, 0.2, 1)
  price_high_vol <- price_black_scholes_put(100, 100, 0.05, 0.3, 1)

  expect_true(price_low_vol < price_mid_vol)
  expect_true(price_mid_vol < price_high_vol)
})

test_that("BS put with zero volatility gives discounted intrinsic value", {
  # Zero volatility: deterministic stock price
  S0 <- 100
  K <- 100
  r <- 0.05
  T <- 1

  price <- price_black_scholes_put(S0, K, r, sigma = 0, T)

  # S_T = S0 * exp(r*T)
  S_T <- S0 * exp(r * T)
  expected <- max(0, K - S_T) * exp(-r * T)

  expect_equal(price, expected, tolerance = 1e-10)
})

test_that("BS put deep ITM has large value", {
  # Very high strike -> deep in-the-money for put
  price <- price_black_scholes_put(100, 150, 0.05, 0.2, 1)

  # Should be substantial but bounded by K * exp(-r*T)
  max_value <- 150 * exp(-0.05 * 1)

  expect_true(price > 30)
  expect_true(price < max_value)
})

test_that("BS put deep OTM has small value", {
  # Very low strike -> deep out-of-the-money for put
  price <- price_black_scholes_put(100, 50, 0.05, 0.2, 1)

  expect_true(price < 1)
  expect_true(price >= 0)
})

test_that("BS put input validation works", {
  # Negative S0
  expect_error(
    price_black_scholes_put(-100, 100, 0.05, 0.2, 1),
    "S0 must be a positive number"
  )

  # Negative K
  expect_error(
    price_black_scholes_put(100, -100, 0.05, 0.2, 1),
    "K must be a positive number"
  )

  # Negative sigma
  expect_error(
    price_black_scholes_put(100, 100, 0.05, -0.2, 1),
    "sigma must be a non-negative number"
  )

  # Negative T
  expect_error(
    price_black_scholes_put(100, 100, 0.05, 0.2, -1),
    "time_to_maturity must be a positive number"
  )
})

test_that("BS put results are reproducible", {
  price1 <- price_black_scholes_put(100, 100, 0.05, 0.2, 1)
  price2 <- price_black_scholes_put(100, 100, 0.05, 0.2, 1)

  expect_equal(price1, price2)
})

# ============================================================================
# PUT-CALL PARITY TESTS
# ============================================================================

test_that("Black-Scholes put-call parity holds exactly", {
  # Put-call parity: C - P = S0 - K * exp(-r*T)
  S0 <- 100
  K <- 100
  r <- 0.05
  sigma <- 0.2
  T <- 1

  call_price <- price_black_scholes_call(S0, K, r, sigma, T)
  put_price <- price_black_scholes_put(S0, K, r, sigma, T)

  parity_lhs <- call_price - put_price
  parity_rhs <- S0 - K * exp(-r * T)

  expect_equal(parity_lhs, parity_rhs, tolerance = 1e-10)
})

test_that("Put-call parity holds for various parameter combinations", {
  # Test multiple scenarios
  scenarios <- list(
    list(S0 = 100, K = 100, r = 0.05, sigma = 0.2, time_to_maturity = 1),
    list(S0 = 50, K = 60, r = 0.03, sigma = 0.3, time_to_maturity = 0.5),
    list(S0 = 150, K = 140, r = 0.08, sigma = 0.15, time_to_maturity = 2),
    list(S0 = 80, K = 100, r = 0.02, sigma = 0.4, time_to_maturity = 0.25)
  )

  for (scenario in scenarios) {
    call <- price_black_scholes_call(scenario$S0, scenario$K, scenario$r,
                                      scenario$sigma, scenario$time_to_maturity)
    put <- price_black_scholes_put(scenario$S0, scenario$K, scenario$r,
                                    scenario$sigma, scenario$time_to_maturity)

    parity_lhs <- call - put
    parity_rhs <- scenario$S0 - scenario$K * exp(-scenario$r * scenario$time_to_maturity)

    expect_equal(parity_lhs, parity_rhs, tolerance = 1e-10,
                 info = paste("Failed for S0 =", scenario$S0, "K =", scenario$K))
  }
})

test_that("Put-call parity holds with zero volatility", {
  # Special case: zero volatility
  S0 <- 100
  K <- 100
  r <- 0.05
  T <- 1

  call_price <- price_black_scholes_call(S0, K, r, 0, T)
  put_price <- price_black_scholes_put(S0, K, r, 0, T)

  parity_lhs <- call_price - put_price
  parity_rhs <- S0 - K * exp(-r * T)

  expect_equal(parity_lhs, parity_rhs, tolerance = 1e-10)
})

# ============================================================================
# BINOMIAL PARAMETER CONVERSION TESTS
# ============================================================================

test_that("price_black_scholes_binomial works correctly", {
  # Basic test
  price <- price_black_scholes_binomial(
    S0 = 100, K = 100, r_gross = 1.05,
    u = 1.2, d = 0.8, n = 50, option_type = "call"
  )

  expect_true(is.numeric(price))
  expect_true(price > 0)
  expect_true(is.finite(price))
})

test_that("BS binomial call and put both work", {
  # Call option
  call_price <- price_black_scholes_binomial(
    100, 100, 1.05, 1.2, 0.8, 50, "call"
  )

  # Put option
  put_price <- price_black_scholes_binomial(
    100, 100, 1.05, 1.2, 0.8, 50, "put"
  )

  expect_true(call_price > 0)
  expect_true(put_price > 0)
  expect_true(call_price != put_price)
})

test_that("BS binomial pricing increases with n", {
  # As n increases, the binomial approximation should stabilize
  S0 <- 100
  K <- 100
  r_gross <- 1.05
  u <- 1.2
  d <- 0.8

  # Calculate for different n values
  price_n10 <- price_black_scholes_binomial(S0, K, r_gross, u, d, 10, "call")
  price_n50 <- price_black_scholes_binomial(S0, K, r_gross, u, d, 50, "call")
  price_n100 <- price_black_scholes_binomial(S0, K, r_gross, u, d, 100, "call")

  # All should be positive
  expect_true(price_n10 > 0)
  expect_true(price_n50 > 0)
  expect_true(price_n100 > 0)

  # Prices should stabilize as n increases (changes become smaller)
  diff_10_50 <- abs(price_n50 - price_n10)
  diff_50_100 <- abs(price_n100 - price_n50)

  # Change should decrease as n increases (convergence property)
  expect_true(diff_50_100 < diff_10_50)
})

test_that("BS binomial parameter conversion is correct", {
  # Verify the parameter conversion formulas
  r_gross <- 1.05
  u <- 1.2
  d <- 0.8
  n <- 50

  # Expected conversions:
  # r_continuous = log(r_gross)
  # dt = 1/n
  # sigma = log(u/d) / (2 * sqrt(dt))

  r_cont_expected <- log(r_gross)
  dt <- 1 / n
  sigma_expected <- log(u / d) / (2 * sqrt(dt))
  T <- 1

  # Get price using binomial parameters
  bs_price <- price_black_scholes_binomial(100, 100, r_gross, u, d, n, "call")

  # Get price using continuous parameters directly
  direct_price <- price_black_scholes_call(100, 100, r_cont_expected,
                                            sigma_expected, T)

  # Should be identical
  expect_equal(bs_price, direct_price, tolerance = 1e-10)
})

test_that("BS binomial input validation works", {
  # Invalid n
  expect_error(
    price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, -5, "call"),
    "n must be a positive integer"
  )

  # Invalid u (too small)
  expect_error(
    price_black_scholes_binomial(100, 100, 1.05, 0.9, 0.8, 10, "call"),
    "u must be greater than 1"
  )

  # Invalid d (too large)
  expect_error(
    price_black_scholes_binomial(100, 100, 1.05, 1.2, 1.1, 10, "call"),
    "d must be less than 1"
  )

  # Invalid d >= u
  expect_error(
    price_black_scholes_binomial(100, 100, 1.05, 1.2, 1.3, 10, "call"),
    "d must be less than 1 and less than u"
  )

  # Invalid option_type
  expect_error(
    price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, 10, "invalid"),
    "should be one of"
  )
})

test_that("BS binomial default is call", {
  # Default option_type should be "call"
  price_default <- price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, 50)
  price_call <- price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, 50, "call")

  expect_equal(price_default, price_call)
})

test_that("BS binomial results are reproducible", {
  price1 <- price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, 50, "call")
  price2 <- price_black_scholes_binomial(100, 100, 1.05, 1.2, 0.8, 50, "call")

  expect_equal(price1, price2)
})

# ============================================================================
# EDGE CASES AND SPECIAL SCENARIOS
# ============================================================================

test_that("BS handles very short time to maturity", {
  # T very small -> should approach intrinsic value
  S0 <- 105
  K <- 100
  T_small <- 1e-6

  call_price <- price_black_scholes_call(S0, K, 0.05, 0.2, T_small)
  put_price <- price_black_scholes_put(S0, K, 0.05, 0.2, T_small)

  # Should be approximately intrinsic value
  expect_true(abs(call_price - (S0 - K)) < 0.1)
  expect_true(put_price < 0.1)
})

test_that("BS handles very high volatility", {
  # High volatility increases option value
  call_price <- price_black_scholes_call(100, 100, 0.05, 2.0, 1)
  put_price <- price_black_scholes_put(100, 100, 0.05, 2.0, 1)

  # Both should have substantial value
  expect_true(call_price > 20)
  expect_true(put_price > 20)
})

test_that("BS handles very low volatility", {
  # Low volatility reduces option value
  call_price <- price_black_scholes_call(100, 100, 0.05, 0.01, 1)
  put_price <- price_black_scholes_put(100, 100, 0.05, 0.01, 1)

  # Should be close to zero volatility case
  call_zero <- price_black_scholes_call(100, 100, 0.05, 0, 1)
  put_zero <- price_black_scholes_put(100, 100, 0.05, 0, 1)

  expect_true(abs(call_price - call_zero) < 0.5)
  expect_true(abs(put_price - put_zero) < 0.5)
})

test_that("BS handles extreme strikes", {
  S0 <- 100

  # Very low strike (deep ITM call)
  call_low_K <- price_black_scholes_call(S0, 1, 0.05, 0.2, 1)
  expect_true(call_low_K > S0 * 0.9)  # Almost equals forward price

  # Very high strike (deep OTM call)
  call_high_K <- price_black_scholes_call(S0, 1000, 0.05, 0.2, 1)
  expect_true(call_high_K < 0.01)

  # Very low strike (deep OTM put)
  put_low_K <- price_black_scholes_put(S0, 1, 0.05, 0.2, 1)
  expect_true(put_low_K < 0.01)

  # Very high strike (deep ITM put)
  put_high_K <- price_black_scholes_put(S0, 500, 0.05, 0.2, 1)
  expect_true(put_high_K > 300)
})

test_that("BS handles negative interest rates", {
  # Modern markets have negative rates
  call_price <- price_black_scholes_call(100, 100, -0.01, 0.2, 1)
  put_price <- price_black_scholes_put(100, 100, -0.01, 0.2, 1)

  # Both should be valid positive prices
  expect_true(is.numeric(call_price))
  expect_true(is.numeric(put_price))
  expect_true(call_price > 0)
  expect_true(put_price > 0)

  # Put-call parity should still hold
  parity_lhs <- call_price - put_price
  parity_rhs <- 100 - 100 * exp(0.01 * 1)  # Note: -r in exponent
  expect_equal(parity_lhs, parity_rhs, tolerance = 1e-10)
})

# ============================================================================
# COMPARISON WITH OTHER METHODS
# ============================================================================

test_that("BS call and put satisfy basic properties", {
  # Test that Black-Scholes satisfies fundamental option properties
  S0 <- 100
  K <- 100
  r_gross <- 1.05
  u <- 1.2
  d <- 0.8
  n <- 50

  # Calculate call and put using binomial parameters
  bs_call <- price_black_scholes_binomial(S0, K, r_gross, u, d, n, "call")
  bs_put <- price_black_scholes_binomial(S0, K, r_gross, u, d, n, "put")

  # Both should be positive
  expect_true(bs_call > 0)
  expect_true(bs_put > 0)

  # Call should be more valuable than put for this parameter set
  # (since S0 = K and r > 0, forward price > K)
  expect_true(bs_call > bs_put)

  # Put-call parity from binomial conversion
  r_cont <- log(r_gross)
  T <- 1
  parity_lhs <- bs_call - bs_put
  parity_rhs <- S0 - K * exp(-r_cont * T)
  expect_equal(parity_lhs, parity_rhs, tolerance = 1e-10)
})

test_that("BS call always >= geometric Asian call", {
  # European option >= Asian option (more volatile = higher value for call)
  # This is a theoretical property

  S0 <- 100
  K <- 100
  r_gross <- 1.05
  u <- 1.2
  d <- 0.8
  n <- 10

  # Black-Scholes limit
  bs_call <- price_black_scholes_binomial(S0, K, r_gross, u, d, n, "call")

  # Geometric Asian (no price impact)
  asian_call <- price_geometric_asian(S0, K, r_gross, u, d,
                                       lambda = 0, v_u = 0, v_d = 0, n = n,
                                       option_type = "call")

  # European should be >= Asian (with some tolerance for discrete vs continuous)
  expect_true(bs_call >= asian_call * 0.95)
})
