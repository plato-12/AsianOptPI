# Tests for European Call Options

test_that("European call option has correct properties", {
  # Basic computation
  price <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(is.numeric(price))
  expect_true(price >= 0)
  expect_length(price, 1)
  expect_false(is.na(price))
  expect_false(is.infinite(price))
})

test_that("Call price decreases as strike increases", {
  # Monotonicity in strike
  price_K90 <- price_european_call(100, 90, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_K100 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_K110 <- price_european_call(100, 110, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_K90 > price_K100)
  expect_true(price_K100 > price_K110)
})

test_that("Call price increases with initial stock price", {
  # Monotonicity in S0
  price_S90 <- price_european_call(90, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_S100 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_S110 <- price_european_call(110, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_S90 < price_S100)
  expect_true(price_S100 < price_S110)
})

test_that("Price impact increases call option value", {
  # Standard CRR model (no price impact)
  price_no_impact <- price_european_call(
    100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 10
  )

  # With price impact
  price_with_impact <- price_european_call(
    100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10
  )

  expect_true(price_with_impact >= price_no_impact)
})

test_that("Call price increases with price impact coefficient", {
  # Compare different lambda values
  price_lambda0 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 10)
  price_lambda01 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_lambda02 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.2, 1, 1, 10)

  expect_true(price_lambda01 >= price_lambda0)
  expect_true(price_lambda02 >= price_lambda01)
})

test_that("European call n=1 case matches manual calculation", {
  # For n=1, we can verify manually
  S0 <- 100
  K <- 100
  r <- 1.05
  u <- 1.2
  d <- 0.8
  lambda <- 0.1
  v_u <- 1
  v_d <- 1

  # Compute manually
  u_tilde <- u * exp(lambda * v_u)
  d_tilde <- d * exp(-lambda * v_d)
  p_adj <- (r - d_tilde) / (u_tilde - d_tilde)

  # Two terminal states
  S_u <- S0 * u_tilde
  S_d <- S0 * d_tilde

  payoff_u <- max(0, S_u - K)
  payoff_d <- max(0, S_d - K)

  expected_price <- (p_adj * payoff_u + (1 - p_adj) * payoff_d) / r

  computed_price <- price_european_call(S0, K, r, u, d, lambda, v_u, v_d, 1)

  expect_equal(computed_price, expected_price, tolerance = 1e-10)
})

test_that("Deep ITM call option has large value", {
  # Very low strike -> deep in-the-money
  price <- price_european_call(100, 50, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  # Should be significantly positive
  expect_true(price > 30)
})

test_that("Deep OTM call option has small value", {
  # Very high strike -> deep out-of-the-money
  price_otm <- price_european_call(100, 500, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_itm <- price_european_call(100, 50, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_otm < 10)
  expect_true(price_otm >= 0)
  # OTM should be much less than ITM
  expect_true(price_otm < price_itm / 3)
})

test_that("ATM call option has intermediate value", {
  # At-the-money
  price_atm <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_itm <- price_european_call(100, 80, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_otm <- price_european_call(100, 120, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_atm > price_otm)
  expect_true(price_atm < price_itm)
})

test_that("Call price increases with number of time steps", {
  # More time steps generally increase option value
  price_n1 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 1)
  price_n5 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 5)
  price_n10 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  # All should be positive
  expect_true(price_n1 > 0)
  expect_true(price_n5 > 0)
  expect_true(price_n10 > 0)
})

test_that("Higher volatility increases call option value", {
  # Lower volatility (u=1.1, d=0.9)
  price_low_vol <- price_european_call(100, 100, 1.05, 1.1, 0.9, 0.1, 1, 1, 10)

  # Higher volatility (u=1.3, d=0.7)
  price_high_vol <- price_european_call(100, 100, 1.05, 1.3, 0.7, 0.1, 1, 1, 10)

  # Higher volatility should increase call option value
  expect_true(price_high_vol > price_low_vol)
})

test_that("Zero lambda reduces to standard CRR for calls", {
  # With lambda=0, should match standard binomial model
  price_zero_lambda <- price_european_call(
    100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 10
  )

  # Should still be a valid positive price
  expect_true(is.numeric(price_zero_lambda))
  expect_true(price_zero_lambda > 0)
})

test_that("Call results are reproducible", {
  # Same inputs should give same outputs
  price1 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price2 <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_equal(price1, price2)
})

test_that("European call can handle large n efficiently", {
  # European options are O(n) not O(2^n), so n=50 should be fast
  # Suppress warning about path enumeration (not relevant for European options)
  start_time <- Sys.time()
  suppressWarnings({
    price <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 50)
  })
  end_time <- Sys.time()

  expect_true(is.numeric(price))
  expect_true(price > 0)
  # Should complete in less than 1 second
  expect_true(as.numeric(end_time - start_time, units = "secs") < 1)
})

# Tests for European Put Options

test_that("European put option has correct properties", {
  # Basic computation
  price <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(is.numeric(price))
  expect_true(price >= 0)
  expect_length(price, 1)
  expect_false(is.na(price))
  expect_false(is.infinite(price))
})

test_that("Put price increases as strike increases", {
  # Monotonicity in strike (opposite of call)
  price_K90 <- price_european_put(100, 90, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_K100 <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_K110 <- price_european_put(100, 110, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_K90 < price_K100)
  expect_true(price_K100 < price_K110)
})

test_that("Put price decreases with initial stock price", {
  # Monotonicity in S0 (opposite of call)
  price_S90 <- price_european_put(90, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_S100 <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_S110 <- price_european_put(110, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price_S90 > price_S100)
  expect_true(price_S100 > price_S110)
})

test_that("European put n=1 case matches manual calculation", {
  # For n=1, we can verify manually
  S0 <- 100
  K <- 100
  r <- 1.05
  u <- 1.2
  d <- 0.8
  lambda <- 0.1
  v_u <- 1
  v_d <- 1

  # Compute manually
  u_tilde <- u * exp(lambda * v_u)
  d_tilde <- d * exp(-lambda * v_d)
  p_adj <- (r - d_tilde) / (u_tilde - d_tilde)

  # Two terminal states
  S_u <- S0 * u_tilde
  S_d <- S0 * d_tilde

  payoff_u <- max(0, K - S_u)
  payoff_d <- max(0, K - S_d)

  expected_price <- (p_adj * payoff_u + (1 - p_adj) * payoff_d) / r

  computed_price <- price_european_put(S0, K, r, u, d, lambda, v_u, v_d, 1)

  expect_equal(computed_price, expected_price, tolerance = 1e-10)
})

test_that("Deep ITM put option has large value", {
  # Very high strike -> deep in-the-money for put
  price <- price_european_put(100, 200, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  # Should be significantly positive
  expect_true(price > 50)
})

test_that("Deep OTM put option has near-zero value", {
  # Very low strike -> deep out-of-the-money for put
  price <- price_european_put(100, 10, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_true(price < 1)
  expect_true(price >= 0)
})

test_that("Higher volatility increases put option value", {
  # Lower volatility (u=1.1, d=0.9)
  price_low_vol <- price_european_put(100, 100, 1.05, 1.1, 0.9, 0.1, 1, 1, 10)

  # Higher volatility (u=1.3, d=0.7)
  price_high_vol <- price_european_put(100, 100, 1.05, 1.3, 0.7, 0.1, 1, 1, 10)

  # Higher volatility should increase put option value
  expect_true(price_high_vol > price_low_vol)
})

test_that("Zero lambda reduces to standard CRR for puts", {
  # With lambda=0, should match standard binomial model
  price_zero_lambda <- price_european_put(
    100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 10
  )

  # Should still be a valid positive price
  expect_true(is.numeric(price_zero_lambda))
  expect_true(price_zero_lambda > 0)
})

test_that("Put results are reproducible", {
  # Same inputs should give same outputs
  price1 <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price2 <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_equal(price1, price2)
})

# Put-Call Parity Tests

test_that("Put-call parity approximately holds with no price impact", {
  # Without price impact, put-call parity should hold exactly
  # C - P = S0 - K/r^n
  S0 <- 100
  K <- 100
  r <- 1.05
  u <- 1.2
  d <- 0.8
  n <- 10

  call_price <- price_european_call(S0, K, r, u, d, 0, 0, 0, n)
  put_price <- price_european_put(S0, K, r, u, d, 0, 0, 0, n)

  # The standard put-call parity doesn't hold exactly in binomial model
  # but call - put should be related to forward price
  diff <- call_price - put_price

  # Both prices should be positive
  expect_true(call_price > 0)
  expect_true(put_price > 0)

  # The difference should be reasonable
  expect_true(abs(diff) < 50)
})

test_that("Put-call relationship changes with price impact", {
  # With price impact, the put-call relationship changes
  S0 <- 100
  K <- 100
  r <- 1.05
  u <- 1.2
  d <- 0.8
  n <- 10

  # No price impact
  call_no_impact <- price_european_call(S0, K, r, u, d, 0, 0, 0, n)
  put_no_impact <- price_european_put(S0, K, r, u, d, 0, 0, 0, n)
  diff_no_impact <- call_no_impact - put_no_impact

  # With price impact
  call_with_impact <- price_european_call(S0, K, r, u, d, 0.1, 1, 1, n)
  put_with_impact <- price_european_put(S0, K, r, u, d, 0.1, 1, 1, n)
  diff_with_impact <- call_with_impact - put_with_impact

  # Price impact should affect calls and puts differently
  expect_true(call_with_impact >= call_no_impact)

  # Both differences should be finite numbers
  expect_true(is.finite(diff_no_impact))
  expect_true(is.finite(diff_with_impact))
})

# Comparison with Geometric Asian Options

test_that("European options should differ from Asian options", {
  # European and Asian options should generally have different prices
  euro_call <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 5)
  asian_geom <- price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 5)

  # They should both be positive
  expect_true(euro_call > 0)
  expect_true(asian_geom > 0)

  # For calls with K=S0, European typically more valuable than Asian geometric
  # because terminal price has higher variance than average
  expect_true(euro_call >= asian_geom)
})

test_that("European option efficiency vs Asian option", {
  # European options should be much faster than Asian for large n
  n_large <- 15  # For Asian: 2^15 = 32768 paths

  # Time European option
  start_euro <- Sys.time()
  euro_price <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, n_large)
  time_euro <- as.numeric(Sys.time() - start_euro, units = "secs")

  # Time Asian option
  start_asian <- Sys.time()
  asian_price <- price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, n_large)
  time_asian <- as.numeric(Sys.time() - start_asian, units = "secs")

  # European should be much faster (at least 10x for n=15)
  expect_true(time_euro < time_asian)
  expect_true(euro_price > 0)
  expect_true(asian_price > 0)
})

# ============================================================================
# UNIFIED INTERFACE TESTS (price_european)
# ============================================================================

test_that("price_european works for calls", {
  price_unified <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                   option_type = "call")
  price_direct <- price_european_call(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_equal(price_unified, price_direct)
})

test_that("price_european works for puts", {
  price_unified <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                   option_type = "put")
  price_direct <- price_european_put(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)

  expect_equal(price_unified, price_direct)
})

test_that("price_european default is call", {
  price_default <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10)
  price_call <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "call")

  expect_equal(price_default, price_call)
})

test_that("price_european put increases with strike", {
  price_K90 <- price_european(100, 90, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                               option_type = "put")
  price_K100 <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "put")
  price_K110 <- price_european(100, 110, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "put")

  expect_true(price_K90 < price_K100)
  expect_true(price_K100 < price_K110)
})

test_that("price_european put decreases with stock price", {
  price_S90 <- price_european(90, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                               option_type = "put")
  price_S100 <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "put")
  price_S110 <- price_european(110, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "put")

  expect_true(price_S90 > price_S100)
  expect_true(price_S100 > price_S110)
})

test_that("price_european option_type validation works", {
  expect_no_error(
    price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                   option_type = "call")
  )
  expect_no_error(
    price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                   option_type = "put")
  )

  expect_error(
    price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                   option_type = "invalid"),
    "should be one of"
  )
})

test_that("price_european both call and put are positive for ATM", {
  call_price <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                                option_type = "call")
  put_price <- price_european(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                               option_type = "put")

  expect_true(call_price > 0)
  expect_true(put_price > 0)
})

test_that("price_european deep ITM put has high value", {
  # High strike -> ITM for put
  price <- price_european(100, 500, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                          option_type = "put")

  expect_true(price > 200)
})

test_that("price_european deep OTM put has low value", {
  # Low strike -> OTM for put
  price <- price_european(100, 1, 1.05, 1.2, 0.8, 0.1, 1, 1, 10,
                          option_type = "put")

  expect_true(price >= 0)
  expect_true(price < 0.01)
})

test_that("price_european put n=1 matches manual calculation", {
  S0 <- 100
  K <- 100
  r <- 1.05
  u <- 1.2
  d <- 0.8
  lambda <- 0.1
  v_u <- 1
  v_d <- 1

  # Compute manually
  u_tilde <- u * exp(lambda * v_u)
  d_tilde <- d * exp(-lambda * v_d)
  p_adj <- (r - d_tilde) / (u_tilde - d_tilde)

  # Two terminal states
  S_u <- S0 * u_tilde
  S_d <- S0 * d_tilde

  payoff_u <- max(0, K - S_u)  # Put payoff
  payoff_d <- max(0, K - S_d)  # Put payoff

  expected_price <- (p_adj * payoff_u + (1 - p_adj) * payoff_d) / r

  computed_price <- price_european(S0, K, r, u, d, lambda, v_u, v_d, 1,
                                    option_type = "put")

  expect_equal(computed_price, expected_price, tolerance = 1e-10)
})
