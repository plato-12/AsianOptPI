#include <Rcpp.h>
#include "utils.h"
#include <vector>
#include <cmath>
#include <algorithm>

// External function from geometric_asian.cpp
std::vector<std::vector<int>> generate_all_paths(int n);

//' Compute Bounds for Arithmetic Asian Call Option
//'
//' Computes lower and upper bounds for the arithmetic Asian call option
//' using Jensen's inequality and the relationship between arithmetic
//' and geometric means.
//'
//' @param S0 Initial stock price
//' @param K Strike price
//' @param r Gross risk-free rate
//' @param u Base up factor
//' @param d Base down factor
//' @param lambda Price impact coefficient
//' @param v_u Hedging volume on up move
//' @param v_d Hedging volume on down move
//' @param n Number of time steps
//'
//' @return List containing:
//' \itemize{
//'   \item \code{lower_bound}: Lower bound (geometric option price)
//'   \item \code{upper_bound}: Upper bound
//'   \item \code{rho_star}: Spread parameter
//'   \item \code{EQ_G}: Expected geometric average
//' }
//'
//' @details
//' Lower bound: \eqn{V_0^A \ge V_0^G} (by AM-GM inequality)
//'
//' Upper bound: \eqn{V_0^A \le V_0^G + (rho^* - 1) \cdot E^Q(G_n) / r^n}
//'
//' where \eqn{rho^* = \exp((u_{tilde}^n - d_{tilde}^n)^2 / (4 \cdot u_{tilde}^n \cdot d_{tilde}^n))}
//'
//' @export
// [[Rcpp::export]]
Rcpp::List arithmetic_asian_bounds_cpp(
    double S0, double K, double r, double u, double d,
    double lambda, double v_u, double v_d, int n
) {
    // Compute effective factors
    EffectiveFactors factors = compute_effective_factors(r, u, d, lambda, v_u, v_d);

    // Generate all paths
    std::vector<std::vector<int>> all_paths = generate_all_paths(n);

    double discount = std::pow(r, -n);

    // Compute lower bound (geometric option value)
    double lower_bound = 0.0;
    double EQ_G = 0.0;  // Expected geometric average

    for (const auto& path : all_paths) {
        std::vector<double> prices = generate_price_path(S0, path,
                                                         factors.u_tilde,
                                                         factors.d_tilde);

        double G = geometric_mean(prices);
        double payoff = std::max(0.0, G - K);

        int n_ups = 0;
        for (int move : path) {
            if (move == 1) n_ups++;
        }

        double path_prob = std::pow(factors.p_eff, n_ups) *
                          std::pow(1.0 - factors.p_eff, n - n_ups);

        lower_bound += path_prob * payoff;
        EQ_G += path_prob * G;
    }

    lower_bound *= discount;

    // Compute rho_star (global spread parameter)
    double u_n = std::pow(factors.u_tilde, n);
    double d_n = std::pow(factors.d_tilde, n);
    double spread = std::pow(u_n - d_n, 2) / (4.0 * u_n * d_n);
    double rho_star = std::exp(spread);

    // Compute upper bound
    double upper_bound = lower_bound + discount * (rho_star - 1.0) * EQ_G;

    return Rcpp::List::create(
        Rcpp::Named("lower_bound") = lower_bound,
        Rcpp::Named("upper_bound") = upper_bound,
        Rcpp::Named("rho_star") = rho_star,
        Rcpp::Named("EQ_G") = EQ_G,
        Rcpp::Named("V0_G") = lower_bound
    );
}
