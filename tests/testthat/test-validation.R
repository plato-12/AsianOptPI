test_that("Input validation catches invalid parameters", {
  # Negative prices
  expect_error(
    price_geometric_asian(-100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3),
    "S0 must be positive"
  )

  expect_error(
    price_geometric_asian(100, -100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3),
    "K must be positive"
  )

  # Invalid rate (negative or zero)
  expect_error(
    price_geometric_asian(100, 100, -1, 1.2, 0.8, 0.1, 1, 1, 3),
    "r must be positive"
  )

  expect_error(
    price_geometric_asian(100, 100, 0, 1.2, 0.8, 0.1, 1, 1, 3),
    "r must be positive"
  )

  # Invalid factors
  expect_error(
    price_geometric_asian(100, 100, 1.05, -1.2, 0.8, 0.1, 1, 1, 3),
    "u must be positive"
  )

  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, -0.8, 0.1, 1, 1, 3),
    "d must be positive"
  )

  # Invalid factor ordering
  expect_error(
    price_geometric_asian(100, 100, 1.05, 0.8, 1.2, 0.1, 1, 1, 3),
    "Up factor u must be greater than down factor d"
  )

  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.0, 1.0, 0.1, 1, 1, 3),
    "Up factor u must be greater than down factor d"
  )

  # Negative lambda
  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, -0.1, 1, 1, 3),
    "lambda must be non-negative"
  )

  # Negative volumes
  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, -1, 1, 3),
    "v_u must be non-negative"
  )

  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, -1, 3),
    "v_d must be non-negative"
  )

  # Non-integer n
  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3.5),
    "n must be a positive integer"
  )

  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, -3),
    "n must be a positive integer"
  )

  expect_error(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 0),
    "n must be a positive integer"
  )
})

test_that("No-arbitrage violation is detected", {
  # r too high (r >= u_tilde)
  expect_error(
    price_geometric_asian(100, 100, 2.0, 1.2, 0.8, 0.1, 1, 1, 3),
    "No-arbitrage condition violated.*r.*>=.*u_tilde"
  )

  # r too low (d_tilde >= r)
  expect_error(
    price_geometric_asian(100, 100, 0.5, 1.2, 0.8, 0.1, 1, 1, 3),
    "No-arbitrage condition violated.*d_tilde.*>=.*r"
  )
})

test_that("Warning issued for large n", {
  expect_warning(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 21),
    "2\\^21"
  )

  expect_warning(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 25),
    "2\\^25.*33554432"
  )

  # No warning for n <= 20
  expect_warning(
    price_geometric_asian(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 20),
    NA
  )
})

test_that("Validation can be disabled", {
  # With validation=FALSE, no errors should occur for parameter checks
  # (but C++ may still error on internal issues)
  result <- price_geometric_asian(
    100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3,
    validate = FALSE
  )
  expect_true(is.numeric(result))
  expect_length(result, 1)
})

test_that("Arithmetic bounds validation works", {
  # Test same validation for arithmetic bounds
  expect_error(
    arithmetic_asian_bounds(-100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 3),
    "S0 must be positive"
  )

  expect_error(
    arithmetic_asian_bounds(100, 100, 1.05, 0.8, 1.2, 0.1, 1, 1, 3),
    "Up factor u must be greater than down factor d"
  )

  expect_error(
    arithmetic_asian_bounds(100, 100, 2.0, 1.2, 0.8, 0.1, 1, 1, 3),
    "No-arbitrage condition violated"
  )

  expect_warning(
    arithmetic_asian_bounds(100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 22),
    "2\\^22"
  )
})

test_that("Edge cases in validation", {
  # Very small positive values should work
  result <- price_geometric_asian(
    0.01, 0.01, 1.01, 1.1, 0.9, 0.01, 0.1, 0.1, 2
  )
  expect_true(is.numeric(result))

  # Zero price impact should work
  result <- price_geometric_asian(
    100, 100, 1.05, 1.2, 0.8, 0, 0, 0, 3
  )
  expect_true(is.numeric(result))

  # n = 1 should work
  result <- price_geometric_asian(
    100, 100, 1.05, 1.2, 0.8, 0.1, 1, 1, 1
  )
  expect_true(is.numeric(result))
})
