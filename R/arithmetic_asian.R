#' Bounds for Arithmetic Asian Call Option with Price Impact
#'
#' Computes lower and upper bounds for the arithmetic Asian call option
#' using the relationship between arithmetic and geometric means (Jensen's
#' inequality).
#'
#' @inheritParams price_geometric_asian
#'
#' @details
#' The arithmetic Asian option has payoff:
#' \deqn{V_n = \max(0, A_n - K)}
#' where \eqn{A_n = \frac{1}{n+1}\sum_{i=0}^{n} S_i}
#'
#' Since \eqn{A_n \geq G_n} (AM-GM inequality), we have:
#' \deqn{V_0^A \geq V_0^G}
#'
#' The upper bound is derived using the reverse AM-GM inequality:
#' \deqn{V_0^A \leq V_0^G + \frac{(\rho^* - 1)}{r^n} \mathbb{E}^Q[G_n]}
#'
#' where \eqn{\rho^* = \exp\left[\frac{(\tilde{u}^n - \tilde{d}^n)^2}{4\tilde{u}^n\tilde{d}^n}\right]}
#'
#' @return List containing:
#' \describe{
#'   \item{lower_bound}{Lower bound for arithmetic option (= geometric option price)}
#'   \item{upper_bound}{Upper bound for arithmetic option}
#'   \item{rho_star}{Spread parameter \eqn{\rho^*}}
#'   \item{EQ_G}{Expected geometric average under risk-neutral measure}
#'   \item{V0_G}{Geometric Asian option price (same as lower_bound)}
#' }
#'
#' @export
#'
#' @examples
#' # Compute bounds
#' bounds <- arithmetic_asian_bounds(
#'   S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
#'   lambda = 0.1, v_u = 1, v_d = 1, n = 3
#' )
#'
#' print(bounds)
#'
#' # Estimate arithmetic option price as midpoint
#' estimated_price <- mean(c(bounds$lower_bound, bounds$upper_bound))
#'
#' @references
#' Budimir, I., Dragomir, S. S., & Pečarić, J. (2000).
#' Further reverse results for Jensen's discrete inequality and
#' applications in information theory.
#' \emph{Journal of Inequalities in Pure and Applied Mathematics}, 2(1).
#'
#' @seealso \code{\link{price_geometric_asian}}
arithmetic_asian_bounds <- function(S0, K, r, u, d, lambda, v_u, v_d, n,
                                     validate = TRUE) {
  # Input validation
  if (validate) {
    validate_inputs(S0, K, r, u, d, lambda, v_u, v_d, n)
  }

  # Call C++ implementation
  result <- arithmetic_asian_bounds_cpp(S0, K, r, u, d, lambda, v_u, v_d, n)

  # Add class for pretty printing
  class(result) <- c("arithmetic_bounds", "list")

  return(result)
}

#' Print Method for Arithmetic Asian Bounds
#'
#' @param x Object of class \code{arithmetic_bounds}
#' @param ... Additional arguments (unused)
#'
#' @return Invisible x
#' @export
print.arithmetic_bounds <- function(x, ...) {
  cat("Arithmetic Asian Option Bounds\n")
  cat("================================\n")
  cat(sprintf("Lower bound (V0_G):  %.6f\n", x$lower_bound))
  cat(sprintf("Upper bound:         %.6f\n", x$upper_bound))
  cat(sprintf("Midpoint estimate:   %.6f\n", mean(c(x$lower_bound, x$upper_bound))))
  cat(sprintf("Spread (ρ*):         %.6f\n", x$rho_star))
  cat(sprintf("E^Q[G_n]:            %.6f\n", x$EQ_G))
  invisible(x)
}
