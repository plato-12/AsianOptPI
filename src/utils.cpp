#include "utils.h"

EffectiveFactors compute_effective_factors(
    double r, double u, double d,
    double lambda, double v_u, double v_d
) {
    EffectiveFactors factors;

    // Compute effective up and down factors
    factors.u_tilde = u * std::exp(lambda * v_u);
    factors.d_tilde = d * std::exp(-lambda * v_d);

    // Compute effective risk-neutral probability
    factors.p_eff = (r - factors.d_tilde) / (factors.u_tilde - factors.d_tilde);

    // Validation (should be done in R wrapper, but double-check)
    if (factors.p_eff < 0.0 || factors.p_eff > 1.0) {
        Rcpp::stop("Invalid risk-neutral probability: p_eff must be in [0,1]");
    }

    return factors;
}

double geometric_mean(const std::vector<double>& prices) {
    if (prices.empty()) {
        Rcpp::stop("Cannot compute geometric mean of empty vector");
    }

    double log_sum = 0.0;
    for (double price : prices) {
        if (price <= 0.0) {
            Rcpp::stop("All prices must be positive for geometric mean");
        }
        log_sum += std::log(price);
    }

    return std::exp(log_sum / prices.size());
}

double arithmetic_mean(const std::vector<double>& prices) {
    if (prices.empty()) {
        Rcpp::stop("Cannot compute arithmetic mean of empty vector");
    }

    double sum = 0.0;
    for (double price : prices) {
        sum += price;
    }

    return sum / prices.size();
}

std::vector<double> generate_price_path(
    double S0,
    const std::vector<int>& path,
    double u_tilde,
    double d_tilde
) {
    int n = path.size();
    std::vector<double> prices(n + 1);

    prices[0] = S0;

    // Build cumulative path
    int n_ups = 0;
    int n_downs = 0;

    for (int i = 0; i < n; ++i) {
        if (path[i] == 1) {  // Up move
            n_ups++;
        } else {  // Down move
            n_downs++;
        }

        // Stock price at time i+1
        prices[i + 1] = S0 * std::pow(u_tilde, n_ups) * std::pow(d_tilde, n_downs);
    }

    return prices;
}
