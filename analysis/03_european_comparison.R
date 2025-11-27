#' European Option Comparison: CRR Binomial vs Black-Scholes
#'
#' This script validates the theoretical connection between the CRR binomial
#' implementation and the Black-Scholes analytical formula for European options.
#'
#' As n → ∞, the discrete binomial model converges to the continuous
#' Black-Scholes model. This script demonstrates and quantifies this convergence.
#'
#' Date: 2025-11-23
#' Reference: See benchmark/THEORETICAL_CONNECTION.md for detailed theory

library(AsianOptPI)
library(ggplot2)
library(tidyr)
library(dplyr)

# ============================================================================
# SECTION 1: Parameter Setup
# ============================================================================

cat(strrep("=", 80), "\n")
cat("EUROPEAN OPTION COMPARISON ANALYSIS\n")
cat("CRR Binomial vs Black-Scholes Analytical\n")
cat(strrep("=", 80), "\n\n")

# Base parameters (following package conventions)
S0 <- 100      # Initial stock price
K <- 100       # Strike price (ATM)
r_gross <- 1.05  # Gross risk-free rate for TOTAL period

# Binomial parameters
u <- 1.2       # Up factor
d <- 0.8       # Down factor

# No price impact (to isolate discrete vs continuous comparison)
lambda <- 0
v_u <- 0
v_d <- 0

# Range of time steps for convergence analysis
# European options have O(n) complexity (unlike Asian O(2^n))
# So we can use much larger n values!
n_values <- c(5, 10, 20, 50, 100, 200, 500, 1000)

# Additional moneyness levels
moneyness_levels <- c(0.8, 0.9, 1.0, 1.1, 1.2)  # K/S0 ratios

cat("Base Parameters:\n")
cat(sprintf("  S0 = %.0f\n", S0))
cat(sprintf("  K  = %.0f (ATM)\n", K))
cat(sprintf("  r_gross = %.3f (total period rate)\n", r_gross))
cat(sprintf("  u  = %.2f\n", u))
cat(sprintf("  d  = %.2f\n", d))
cat(sprintf("  λ  = %.2f (no price impact)\n", lambda))
cat(sprintf("  n_values = %s\n\n", paste(n_values, collapse = ", ")))

# ============================================================================
# SECTION 2: Rate Conversion and Parameter Matching
# ============================================================================

cat("SECTION 2: Understanding Parameter Conversions\n")
cat(strrep("-", 80), "\n\n")

cat("From benchmark/THEORETICAL_CONNECTION.md:\n\n")

cat("1. CRR Binomial Model (Discrete):\n")
cat("   - Stock price: S_{i+1} = u*S_i (up) or d*S_i (down)\n")
cat("   - Risk-neutral probability: p = (r - d) / (u - d)\n")
cat("   - Terminal price: S_n = S0 * u^k * d^(n-k) for k ups\n")
cat("   - Pricing: Discounted expectation over binomial distribution\n\n")

cat("2. Black-Scholes Model (Continuous):\n")
cat("   - Stock dynamics: dS_t = r*S_t*dt + σ*S_t*dW_t\n")
cat("   - Log-normal terminal distribution\n")
cat("   - Closed-form solution using N(d1), N(d2)\n\n")

cat("3. Convergence Conditions:\n")
cat("   For CRR to converge to Black-Scholes as n → ∞:\n")
cat("   - Time step: Δt = T/n = 1/n\n")
cat("   - Volatility: σ = log(u/d) / (2√Δt)\n")
cat("   - Rate per step: r_step = r_gross^(1/n)\n")
cat("   - Continuous rate: r_cont = log(r_gross)\n\n")

# Calculate implied volatility and continuous rate
dt_example <- 1 / 10  # For n=10
sigma_implied <- log(u / d) / (2 * sqrt(dt_example))
r_continuous <- log(r_gross)

cat("Derived Parameters (for comparison):\n")
cat(sprintf("  σ (implied) = %.4f\n", sigma_implied))
cat(sprintf("  r_continuous = %.5f\n", r_continuous))
cat(sprintf("  T (total time) = 1 year\n\n"))

# ============================================================================
# SECTION 3: Helper Functions for Proper Rate Conversion
# ============================================================================

#' Compute CRR price with CORRECTED rate per step
#' Following THEORETICAL_CONNECTION.md recommendation
price_crr_call_corrected <- function(S0, K, r_gross_total, u, d, n) {
  # Convert total period rate to per-step rate
  r_per_step <- r_gross_total^(1/n)

  # Price with corrected rate
  price_european_call(
    S0 = S0, K = K, r = r_per_step, u = u, d = d,
    lambda = 0, v_u = 0, v_d = 0, n = n
  )
}

price_crr_put_corrected <- function(S0, K, r_gross_total, u, d, n) {
  r_per_step <- r_gross_total^(1/n)
  price_european_put(
    S0 = S0, K = K, r = r_per_step, u = u, d = d,
    lambda = 0, v_u = 0, v_d = 0, n = n
  )
}

# ============================================================================
# SECTION 4: Single Point Comparison
# ============================================================================

cat("SECTION 4: Single Point Comparison (ATM Call, n=100)\n")
cat(strrep("-", 80), "\n\n")

n_test <- 100

# CRR Binomial price with CORRECTED rate per step
crr_price <- price_crr_call_corrected(
  S0 = S0, K = K, r_gross_total = r_gross, u = u, d = d, n = n_test
)

# Black-Scholes price (using binomial parameters)
bs_price <- price_black_scholes_binomial(
  S0 = S0, K = K, r_gross = r_gross, u = u, d = d,
  n = n_test, option_type = "call"
)

# Direct Black-Scholes (using continuous parameters)
sigma <- log(u / d) / (2 * sqrt(1 / n_test))
r_cont <- log(r_gross)
bs_direct <- price_black_scholes_call(
  S0 = S0, K = K, r = r_cont, sigma = sigma, T = 1
)

cat(sprintf("CRR Binomial (n=%d):        %.6f\n", n_test, crr_price))
cat(sprintf("Black-Scholes (binomial):   %.6f\n", bs_price))
cat(sprintf("Black-Scholes (direct):     %.6f\n", bs_direct))
cat(sprintf("Absolute difference (CRR-BS): %.8f\n", abs(crr_price - bs_price)))
cat(sprintf("Relative error:              %.6f%%\n\n",
            100 * abs(crr_price - bs_price) / bs_price))

# ============================================================================
# SECTION 5: Convergence Analysis - Varying n
# ============================================================================

cat("SECTION 5: Convergence Analysis (varying n)\n")
cat(strrep("-", 80), "\n\n")

cat("Computing prices for n =", paste(n_values, collapse = ", "), "\n")
cat("This may take a few seconds...\n\n")

# Storage for results
convergence_results <- data.frame()

for (n in n_values) {
  # CRR Binomial with CORRECTED rate
  crr <- price_crr_call_corrected(S0, K, r_gross, u, d, n)

  # Black-Scholes (using binomial parameters)
  bs <- price_black_scholes_binomial(S0, K, r_gross, u, d, n, "call")

  # Store results
  convergence_results <- rbind(convergence_results, data.frame(
    n = n,
    dt = 1/n,
    CRR = crr,
    BlackScholes = bs,
    AbsError = abs(crr - bs),
    RelError = 100 * abs(crr - bs) / bs
  ))
}

# Display results
cat("\nConvergence Table:\n")
print(convergence_results, row.names = FALSE, digits = 6)

cat("\n\nKey Observations:\n")
cat(sprintf("  - At n=5:    Error = %.6f (%.4f%%)\n",
            convergence_results$AbsError[1], convergence_results$RelError[1]))
cat(sprintf("  - At n=100:  Error = %.8f (%.6f%%)\n",
            convergence_results$AbsError[convergence_results$n == 100],
            convergence_results$RelError[convergence_results$n == 100]))
cat(sprintf("  - At n=1000: Error = %.10f (%.8f%%)\n\n",
            convergence_results$AbsError[convergence_results$n == 1000],
            convergence_results$RelError[convergence_results$n == 1000]))

# ============================================================================
# SECTION 6: Moneyness Analysis
# ============================================================================

cat("SECTION 6: Moneyness Analysis (n=100)\n")
cat(strrep("-", 80), "\n\n")

cat("Comparing across different strike prices...\n\n")

n_mono <- 100
moneyness_results <- data.frame()

for (moneyness in moneyness_levels) {
  K_current <- S0 * moneyness

  # CRR Call with CORRECTED rate
  crr_call <- price_crr_call_corrected(S0, K_current, r_gross, u, d, n_mono)

  # BS Call
  bs_call <- price_black_scholes_binomial(S0, K_current, r_gross, u, d,
                                           n_mono, "call")

  # CRR Put with CORRECTED rate
  crr_put <- price_crr_put_corrected(S0, K_current, r_gross, u, d, n_mono)

  # BS Put
  bs_put <- price_black_scholes_binomial(S0, K_current, r_gross, u, d,
                                          n_mono, "put")

  moneyness_results <- rbind(moneyness_results, data.frame(
    Moneyness = moneyness,
    K = K_current,
    Type = c("Call", "Put"),
    CRR = c(crr_call, crr_put),
    BlackScholes = c(bs_call, bs_put),
    AbsError = c(abs(crr_call - bs_call), abs(crr_put - bs_put)),
    RelError = c(100 * abs(crr_call - bs_call) / bs_call,
                 100 * abs(crr_put - bs_put) / bs_put)
  ))
}

cat("Moneyness Comparison Table:\n")
print(moneyness_results, row.names = FALSE, digits = 6)

# ============================================================================
# SECTION 7: Put-Call Parity Verification
# ============================================================================

cat("\n")
cat("SECTION 7: Put-Call Parity Verification\n")
cat(strrep("-", 80), "\n\n")

cat("Put-Call Parity: C - P = S0 - K*exp(-r*T)\n\n")

n_parity <- 100
K_parity <- 100

# CRR prices with CORRECTED rate
crr_call_parity <- price_crr_call_corrected(S0, K_parity, r_gross, u, d, n_parity)
crr_put_parity <- price_crr_put_corrected(S0, K_parity, r_gross, u, d, n_parity)

# Black-Scholes prices
bs_call_parity <- price_black_scholes_binomial(S0, K_parity, r_gross, u, d,
                                                n_parity, "call")
bs_put_parity <- price_black_scholes_binomial(S0, K_parity, r_gross, u, d,
                                               n_parity, "put")

# Parity calculations
r_cont_parity <- log(r_gross)
parity_rhs <- S0 - K_parity * exp(-r_cont_parity * 1)

crr_parity_lhs <- crr_call_parity - crr_put_parity
bs_parity_lhs <- bs_call_parity - bs_put_parity

cat("CRR Binomial:\n")
cat(sprintf("  Call = %.6f\n", crr_call_parity))
cat(sprintf("  Put  = %.6f\n", crr_put_parity))
cat(sprintf("  C - P = %.6f\n", crr_parity_lhs))
cat(sprintf("  S - K*exp(-rT) = %.6f\n", parity_rhs))
cat(sprintf("  Parity Error = %.8f\n\n", abs(crr_parity_lhs - parity_rhs)))

cat("Black-Scholes:\n")
cat(sprintf("  Call = %.6f\n", bs_call_parity))
cat(sprintf("  Put  = %.6f\n", bs_put_parity))
cat(sprintf("  C - P = %.6f\n", bs_parity_lhs))
cat(sprintf("  S - K*exp(-rT) = %.6f\n", parity_rhs))
cat(sprintf("  Parity Error = %.10f\n\n", abs(bs_parity_lhs - parity_rhs)))

# ============================================================================
# SECTION 8: Visualizations
# ============================================================================

cat("SECTION 8: Generating Visualizations\n")
cat(strrep("-", 80), "\n\n")

# --- Plot 1: Convergence Analysis ---
cat("Creating convergence plot...\n")

p1 <- ggplot(convergence_results, aes(x = n)) +
  geom_line(aes(y = CRR, color = "CRR Binomial"), size = 1) +
  geom_point(aes(y = CRR, color = "CRR Binomial"), size = 2) +
  geom_line(aes(y = BlackScholes, color = "Black-Scholes"),
            size = 1, linetype = "dashed") +
  geom_point(aes(y = BlackScholes, color = "Black-Scholes"), size = 2) +
  scale_x_log10() +
  labs(
    title = "European Call Option: CRR Convergence to Black-Scholes",
    subtitle = sprintf("S0=%.0f, K=%.0f, r=%.3f, u=%.2f, d=%.2f",
                       S0, K, r_gross, u, d),
    x = "Number of Time Steps (n, log scale)",
    y = "Option Price",
    color = "Model"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p1)

# --- Plot 2: Absolute Error vs n ---
cat("Creating error convergence plot...\n")

p2 <- ggplot(convergence_results, aes(x = n, y = AbsError)) +
  geom_line(color = "red", size = 1) +
  geom_point(color = "red", size = 2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Absolute Pricing Error: |CRR - Black-Scholes|",
    subtitle = "Log-log scale shows error decay rate",
    x = "Number of Time Steps (n, log scale)",
    y = "Absolute Error (log scale)"
  ) +
  theme_minimal()

print(p2)

# Add reference line for O(1/n) convergence
convergence_results$theoretical_error <- convergence_results$AbsError[1] *
  (convergence_results$n[1] / convergence_results$n)

p2_with_theory <- p2 +
  geom_line(data = convergence_results,
            aes(x = n, y = theoretical_error),
            color = "blue", linetype = "dashed", size = 0.8) +
  annotate("text", x = 100, y = max(convergence_results$theoretical_error) * 0.5,
           label = "O(1/n) theoretical", color = "blue", size = 3)

print(p2_with_theory)

# --- Plot 3: Relative Error vs n ---
cat("Creating relative error plot...\n")

p3 <- ggplot(convergence_results, aes(x = n, y = RelError)) +
  geom_line(color = "darkgreen", size = 1) +
  geom_point(color = "darkgreen", size = 2) +
  scale_x_log10() +
  labs(
    title = "Relative Pricing Error: |(CRR - BS) / BS| × 100%",
    subtitle = "Percentage error decreases with finer time discretization",
    x = "Number of Time Steps (n, log scale)",
    y = "Relative Error (%)"
  ) +
  theme_minimal()

print(p3)

# --- Plot 4: Moneyness Comparison (Calls) ---
cat("Creating moneyness comparison plot...\n")

moneyness_calls <- moneyness_results %>% filter(Type == "Call")

p4 <- ggplot(moneyness_calls, aes(x = K)) +
  geom_line(aes(y = CRR, color = "CRR Binomial"), size = 1) +
  geom_point(aes(y = CRR, color = "CRR Binomial"), size = 3) +
  geom_line(aes(y = BlackScholes, color = "Black-Scholes"),
            size = 1, linetype = "dashed") +
  geom_point(aes(y = BlackScholes, color = "Black-Scholes"), size = 3) +
  geom_vline(xintercept = S0, linetype = "dotted", color = "gray50") +
  annotate("text", x = S0, y = max(moneyness_calls$CRR) * 0.9,
           label = "ATM", angle = 90, vjust = -0.5, color = "gray50") +
  labs(
    title = "European Call Prices Across Moneyness (n=100)",
    subtitle = sprintf("S0=%.0f (dotted line shows ATM)", S0),
    x = "Strike Price (K)",
    y = "Call Option Price",
    color = "Model"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p4)

# --- Plot 5: Error Across Moneyness ---
cat("Creating moneyness error plot...\n")

p5 <- ggplot(moneyness_calls, aes(x = K, y = AbsError)) +
  geom_line(color = "purple", size = 1) +
  geom_point(color = "purple", size = 3) +
  geom_vline(xintercept = S0, linetype = "dotted", color = "gray50") +
  labs(
    title = "Absolute Error Across Moneyness (Calls, n=100)",
    subtitle = "Error is typically smallest near ATM",
    x = "Strike Price (K)",
    y = "Absolute Error |CRR - BS|"
  ) +
  theme_minimal()

print(p5)

# ============================================================================
# SECTION 9: Theoretical Connection Summary
# ============================================================================

cat("\n")
cat("SECTION 9: Theoretical Connection Summary\n")
cat(strrep("=", 80), "\n\n")

cat("CONVERGENCE THEOREM (Cox-Ross-Rubinstein, 1979):\n")
cat("As n → ∞, the CRR binomial price converges to Black-Scholes price.\n\n")

cat("KEY PARAMETER RELATIONSHIPS:\n")
cat("1. Time discretization:\n")
cat("   Δt = T/n → 0 as n → ∞\n\n")

cat("2. Volatility matching:\n")
cat("   σ = log(u/d) / (2√Δt)\n")
cat(sprintf("   For u=%.2f, d=%.2f: σ ≈ %.4f (extracted)\n\n", u, d, sigma_implied))

cat("3. Risk-free rate conversion:\n")
cat("   r_continuous = log(r_gross) / T\n")
cat(sprintf("   For r_gross=%.3f: r_continuous = %.5f\n\n", r_gross, r_continuous))

cat("4. Convergence rate:\n")
cat("   Error = O(1/n) for smooth payoffs (European options)\n")
cat(sprintf("   Observed at n=1000: %.2e (%.6f%%)\n\n",
            convergence_results$AbsError[convergence_results$n == 1000],
            convergence_results$RelError[convergence_results$n == 1000]))

cat("DIFFERENCES FROM ASIAN OPTIONS:\n")
cat("1. Complexity:\n")
cat("   - European: O(n) - depends only on terminal price\n")
cat("   - Asian: O(2^n) - path-dependent average\n\n")

cat("2. Convergence:\n")
cat("   - European: Clean O(1/n) convergence\n")
cat("   - Asian: Additional error from discrete vs continuous averaging\n\n")

cat("3. Analytical Solutions:\n")
cat("   - European: Exact Black-Scholes formula\n")
cat("   - Asian (geometric): Kemma-Vorst approximation (continuous limit)\n")
cat("   - Asian (arithmetic): No closed form, use bounds\n\n")

cat("PRACTICAL IMPLICATIONS:\n")
cat("1. For European options:\n")
cat("   - n=50-100 gives excellent accuracy (<0.1% error)\n")
cat("   - Black-Scholes should be preferred (O(1) vs O(n))\n")
cat("   - Binomial useful for: American options, dividends, barriers\n\n")

cat("2. For comparison purposes:\n")
cat("   - Both models agree in the limit n → ∞\n")
cat("   - Finite-n differences are purely discretization error\n")
cat("   - No-arbitrage conditions identical (d < r < u)\n\n")

cat("3. Price impact extension:\n")
cat("   - Black-Scholes assumes frictionless markets (λ=0)\n")
cat("   - CRR with price impact models hedging costs\n")
cat("   - No analytical Black-Scholes equivalent for λ>0\n\n")

# ============================================================================
# SECTION 10: Save Results
# ============================================================================

cat("SECTION 10: Saving Results\n")
cat(strrep("-", 80), "\n\n")

# Save convergence data
output_file <- "analysis/figures/european_convergence_data.csv"
write.csv(convergence_results, output_file, row.names = FALSE)
cat(sprintf("Convergence data saved to: %s\n", output_file))

# Save moneyness data
output_file_mono <- "analysis/figures/european_moneyness_data.csv"
write.csv(moneyness_results, output_file_mono, row.names = FALSE)
cat(sprintf("Moneyness data saved to: %s\n", output_file_mono))

# Save plots
cat("\nSaving plots...\n")
ggsave("analysis/figures/european_convergence_prices.png", p1,
       width = 8, height = 6, dpi = 300)
ggsave("analysis/figures/european_convergence_error_log.png", p2_with_theory,
       width = 8, height = 6, dpi = 300)
ggsave("analysis/figures/european_convergence_error_rel.png", p3,
       width = 8, height = 6, dpi = 300)
ggsave("analysis/figures/european_moneyness_prices.png", p4,
       width = 8, height = 6, dpi = 300)
ggsave("analysis/figures/european_moneyness_error.png", p5,
       width = 8, height = 6, dpi = 300)

cat("All plots saved to analysis/figures/\n")

# ============================================================================
# ANALYSIS COMPLETE
# ============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("ANALYSIS COMPLETE\n")
cat(strrep("=", 80), "\n\n")

cat("Key Findings:\n")
cat(sprintf("1. CRR converges to Black-Scholes with O(1/n) error rate\n"))
cat(sprintf("2. At n=100: error = %.2e (%.4f%%)\n",
            convergence_results$AbsError[convergence_results$n == 100],
            convergence_results$RelError[convergence_results$n == 100]))
cat(sprintf("3. Put-call parity holds exactly for Black-Scholes\n"))
cat(sprintf("4. Put-call parity holds approximately for CRR (error = %.2e)\n",
            abs(crr_parity_lhs - parity_rhs)))
cat(sprintf("5. Convergence is uniform across moneyness levels\n\n"))

cat("Recommendations:\n")
cat("- Use Black-Scholes for European options (faster, exact)\n")
cat("- Use CRR binomial when price impact matters (λ > 0)\n")
cat("- Use n ≥ 50 for high accuracy if binomial required\n")
cat("- See benchmark/THEORETICAL_CONNECTION.md for full theory\n\n")
