#' Validate Input Parameters for Asian Option Pricing
#'
#' @param S0 Initial stock price
#' @param K Strike price
#' @param r Gross risk-free rate
#' @param u Up factor
#' @param d Down factor
#' @param lambda Price impact coefficient
#' @param v_u Hedging volume (up)
#' @param v_d Hedging volume (down)
#' @param n Number of time steps
#'
#' @return NULL (throws error if validation fails)
#' @keywords internal
validate_inputs <- function(S0, K, r, u, d, lambda, v_u, v_d, n) {

  # Check positivity
  if (S0 <= 0) stop("S0 must be positive")
  if (K <= 0) stop("K must be positive")
  if (r <= 0) stop("r must be positive (use gross rate, e.g., 1.05)")
  if (u <= 0) stop("u must be positive")
  if (d <= 0) stop("d must be positive")
  if (lambda < 0) stop("lambda must be non-negative")
  if (v_u < 0) stop("v_u must be non-negative")
  if (v_d < 0) stop("v_d must be non-negative")

  # Check integer constraint
  if (!is.numeric(n) || n != as.integer(n) || n <= 0) {
    stop("n must be a positive integer")
  }

  # Check ordering: u > d
  if (u <= d) {
    stop("Up factor u must be greater than down factor d")
  }

  # Compute effective factors
  u_tilde <- u * exp(lambda * v_u)
  d_tilde <- d * exp(-lambda * v_d)

  # Check no-arbitrage condition
  if (d_tilde >= r) {
    stop(sprintf(
      "No-arbitrage condition violated: d_tilde (%.4f) >= r (%.4f). Need d̃ < r.",
      d_tilde, r
    ))
  }

  if (r >= u_tilde) {
    stop(sprintf(
      "No-arbitrage condition violated: r (%.4f) >= u_tilde (%.4f). Need r < ũ.",
      r, u_tilde
    ))
  }

  # Compute and check risk-neutral probability
  p_eff <- (r - d_tilde) / (u_tilde - d_tilde)

  if (p_eff < 0 || p_eff > 1) {
    stop(sprintf(
      "Effective risk-neutral probability out of bounds: p_eff = %.4f (must be in [0,1])",
      p_eff
    ))
  }

  # Warning for computational complexity
  # Note: This warning is only relevant for path-dependent options (Asian)
  # European options are O(n) and don't enumerate paths
  if (n > 20) {
    # Use scientific notation for large numbers to avoid overflow
    num_paths <- 2^n
    if (n > 30) {
      warning(sprintf(
        "n = %d will enumerate 2^%d = %.2e paths. This may be slow.",
        n, n, num_paths
      ))
    } else {
      warning(sprintf(
        "n = %d will enumerate 2^%d = %g paths. This may be slow.",
        n, n, num_paths
      ))
    }
  }

  invisible(NULL)
}
