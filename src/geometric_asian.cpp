#include <Rcpp.h>
#include "utils.h"
#include <vector>
#include <cmath>

// Helper function to generate all binary paths of length n
void generate_all_paths_recursive(
    int n,
    int current_step,
    std::vector<int>& current_path,
    std::vector<std::vector<int>>& all_paths
) {
    if (current_step == n) {
        all_paths.push_back(current_path);
        return;
    }

    // Try up move (1)
    current_path[current_step] = 1;
    generate_all_paths_recursive(n, current_step + 1, current_path, all_paths);

    // Try down move (0)
    current_path[current_step] = 0;
    generate_all_paths_recursive(n, current_step + 1, current_path, all_paths);
}

std::vector<std::vector<int>> generate_all_paths(int n) {
    std::vector<std::vector<int>> all_paths;
    std::vector<int> current_path(n);

    generate_all_paths_recursive(n, 0, current_path, all_paths);

    return all_paths;
}

//' Price Geometric Asian Call Option with Price Impact
//'
//' Computes the exact price of a geometric Asian call option using the
//' binomial tree model with price impact from hedging activities.
//'
//' @param S0 Initial stock price (positive)
//' @param K Strike price (positive)
//' @param r Gross risk-free rate per period (e.g., 1.05 for 5\% rate)
//' @param u Base up factor in CRR model (e.g., 1.2)
//' @param d Base down factor in CRR model (e.g., 0.8)
//' @param lambda Price impact coefficient (non-negative)
//' @param v_u Hedging volume on up move (non-negative)
//' @param v_d Hedging volume on down move (non-negative)
//' @param n Number of time steps (positive integer)
//'
//' @return Geometric Asian call option price
//'
//' @details
//' The function enumerates all 2^n possible price paths and computes:
//' \itemize{
//'   \item Geometric average: \eqn{G = (S_0 \cdot S_1 \cdot \ldots \cdot S_n)^{1/(n+1)}}
//'   \item Payoff: \eqn{\max(0, G - K)}
//'   \item Option value: \eqn{(1/r^n) \cdot \sum_{paths} p^k (1-p)^{(n-k)} \cdot payoff}
//' }
//'
//' Price impact modifies the up and down factors:
//' \itemize{
//'   \item Adjusted up factor: \eqn{u_{tilde} = u \cdot \exp(\lambda \cdot v_u)}
//'   \item Adjusted down factor: \eqn{d_{tilde} = d \cdot \exp(-\lambda \cdot v_d)}
//' }
//'
//' @references
//' Cox, J. C., Ross, S. A., & Rubinstein, M. (1979). Option pricing:
//' A simplified approach. Journal of Financial Economics, 7(3), 229-263.
//'
//' @examples
//' \dontrun{
//' # Basic example with 3 time steps
//' price_geometric_asian_cpp(
//'   S0 = 100, K = 100, r = 1.05, u = 1.2, d = 0.8,
//'   lambda = 0.1, v_u = 1.0, v_d = 1.0, n = 3
//' )
//' }
//'
//' @export
// [[Rcpp::export]]
double price_geometric_asian_cpp(
    double S0, double K, double r, double u, double d,
    double lambda, double v_u, double v_d, int n
) {
    // Compute adjusted factors and risk-neutral probability
    AdjustedFactors factors = compute_adjusted_factors(r, u, d, lambda, v_u, v_d);

    // Generate all 2^n paths
    std::vector<std::vector<int>> all_paths = generate_all_paths(n);

    // Discount factor
    double discount = std::pow(r, -n);

    // Sum of discounted expected payoffs
    double option_value = 0.0;

    // Iterate over all paths
    for (const auto& path : all_paths) {
        // Generate stock price sequence for this path
        std::vector<double> prices = generate_price_path(S0, path,
                                                         factors.u_tilde,
                                                         factors.d_tilde);

        // Compute geometric average
        double G = geometric_mean(prices);

        // Compute payoff
        double payoff = std::max(0.0, G - K);

        // Count number of up moves
        int n_ups = 0;
        for (int move : path) {
            if (move == 1) n_ups++;
        }

        // Compute path probability
        double path_prob = std::pow(factors.p_adj, n_ups) *
                          std::pow(1.0 - factors.p_adj, n - n_ups);

        // Add to option value
        option_value += path_prob * payoff;
    }

    // Apply discounting
    option_value *= discount;

    return option_value;
}
