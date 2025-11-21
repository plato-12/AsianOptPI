#ifndef UTILS_H
#define UTILS_H

#include <Rcpp.h>
#include <vector>
#include <cmath>

// Compute effective factors with price impact
struct EffectiveFactors {
    double u_tilde;
    double d_tilde;
    double p_eff;
};

EffectiveFactors compute_effective_factors(
    double r, double u, double d,
    double lambda, double v_u, double v_d
);

// Compute geometric average of a vector
double geometric_mean(const std::vector<double>& prices);

// Compute arithmetic average of a vector
double arithmetic_mean(const std::vector<double>& prices);

// Generate stock price path
std::vector<double> generate_price_path(
    double S0,
    const std::vector<int>& path,
    double u_tilde,
    double d_tilde
);

// Compute binomial coefficient C(n, k) = n! / (k! * (n-k)!)
double binomial_coefficient(int n, int k);

#endif
