#' Price Geometric Asian Option with Price Impact
#'
#' Computes the exact price of a geometric Asian option (call or put) using the
#' Cox-Ross-Rubinstein (CRR) binomial model with price impact from
#' hedging activities.
#'
#' @param S0 Initial stock price (must be positive)
#' @param K Strike price (must be positive)
#' @param r Gross risk-free rate per period (e.g., 1.05)
#' @param u Base up factor in CRR model (must be > d)
#' @param d Base down factor in CRR model (must be positive)
#' @param lambda Price impact coefficient (non-negative)
#' @param v_u Hedging volume on up move (non-negative)
#' @param v_d Hedging volume on down move (non-negative)
#' @param n Number of time steps (positive integer, recommended n <= 20)
#' @param option_type Character; either "call" (default) or "put"
#' @param validate Logical; if TRUE, performs input validation
#'
#' @details
#' The geometric Asian option payoff is:
#' \itemize{
#'   \item Call: \eqn{V_n = \max(0, G_n - K)}
#'   \item Put: \eqn{V_n = \max(0, K - G_n)}
#' }
#' where \eqn{G_n = (S_0 \cdot S_1 \cdot \ldots \cdot S_n)^{1/(n+1)}}
#'
#' Price impact modifies the stock dynamics:
#' \itemize{
#'   \item Effective up factor: \eqn{\tilde{u} = u \cdot e^{\lambda v^u}}
#'   \item Effective down factor: \eqn{\tilde{d} = d \cdot e^{-\lambda v^d}}
#'   \item Risk-neutral probability: \eqn{p^{eff} = \frac{r - \tilde{d}}{\tilde{u} - \tilde{d}}}
#' }
#'
#' The function enumerates all \eqn{2^n} possible price paths, making it
#' computationally intensive for large n.
#'
#' @return Geometric Asian option price (numeric)
#' @export
#'
#' @examples
#' # Call option with no price impact
#' price_geometric_asian(
#'   S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
#'   lambda = 0, v_u = 0, v_d = 0, n = 3, option_type = "call"
#' )
#'
#' # Put option with price impact
#' price_geometric_asian(
#'   S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
#'   lambda = 0.1, v_u = 1, v_d = 1, n = 3, option_type = "put"
#' )
#'
#' @references
#' Cox, J. C., Ross, S. A., & Rubinstein, M. (1979).
#' Option pricing: A simplified approach.
#' \emph{Journal of Financial Economics}, 7(3), 229-263.
#'
#' @seealso \code{\link{arithmetic_asian_bounds}}, \code{\link{compute_p_eff}}
price_geometric_asian <- function(S0, K, r, u, d, lambda, v_u, v_d, n,
                                   option_type = "call",
                                   validate = TRUE) {
  # Input validation
  if (validate) {
    validate_inputs(S0, K, r, u, d, lambda, v_u, v_d, n)
  }

  # Validate option_type
  option_type <- match.arg(option_type, c("call", "put"))

  # Call C++ implementation
  result <- price_geometric_asian_cpp(S0, K, r, u, d, lambda, v_u, v_d, n, option_type)

  return(result)
}
