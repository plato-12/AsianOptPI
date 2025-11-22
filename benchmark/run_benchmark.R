# Standalone Benchmark Script (no pandoc required)
# This extracts the core analysis from the Rmd file

# Load the package from source
suppressPackageStartupMessages({
  library(devtools)
  setwd("AsianOptPI")
  load_all(".", quiet = TRUE)
  setwd("..")
})

# Create results directory
dir.create("benchmark/results", recursive = TRUE, showWarnings = FALSE)

cat("\n=== RUNNING BENCHMARK TESTS ===\n\n")

# Common parameters
S0_base <- 100
K_base <- 100
r_base <- 1.05
u_base <- 1.2
d_base <- 0.8
n_base <- 10

# TEST 1: Equivalence
cat("Test 1: Verifying lambda = 0 equivalence...\n")

test_cases <- expand.grid(
  n = c(5, 8, 10, 12),
  S0 = c(90, 100, 110),
  K = c(90, 100, 110)
)

equivalence_results <- data.frame()

for (i in 1:nrow(test_cases)) {
  tc <- test_cases[i, ]
  moneyness <- if (tc$K < tc$S0) "ITM" else if (tc$K == tc$S0) "ATM" else "OTM"

  kv_price <- price_kemma_vorst_geometric_binomial(
    S0 = tc$S0, K = tc$K, r = r_base, u = u_base, d = d_base, n = tc$n
  )

  pi_price <- price_geometric_asian(
    S0 = tc$S0, K = tc$K, r = r_base, u = u_base, d = d_base,
    lambda = 0, v_u = 1, v_d = 1, n = tc$n
  )

  abs_diff <- abs(kv_price - pi_price)
  rel_diff_pct <- 100 * abs_diff / kv_price

  equivalence_results <- rbind(equivalence_results, data.frame(
    n = tc$n, S0 = tc$S0, K = tc$K, Moneyness = moneyness,
    Kemma_Vorst = kv_price, Price_Impact_Lambda0 = pi_price,
    Absolute_Diff = abs_diff, Relative_Diff_pct = rel_diff_pct
  ))
}

write.csv(equivalence_results, "benchmark/results/equivalence_test.csv", row.names = FALSE)
cat(sprintf("  Max absolute difference: %.2e\n", max(equivalence_results$Absolute_Diff)))
cat(sprintf("  Equivalence: %s\n\n", ifelse(max(equivalence_results$Absolute_Diff) < 1e-8, "VERIFIED ✓", "FAILED")))

# TEST 2: Price Impact Analysis
cat("Test 2: Price impact analysis...\n")

lambda_values <- c(0, 0.01, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5)
volume_values <- c(0.5, 1, 2, 5)

impact_results <- data.frame()
baseline_price <- price_kemma_vorst_geometric_binomial(S0_base, K_base, r_base, u_base, d_base, n_base)

for (v in volume_values) {
  for (lam in lambda_values) {
    if (lam == 0) {
      price <- baseline_price
    } else {
      price <- price_geometric_asian(S0_base, K_base, r_base, u_base, d_base, lam, v, v, n_base)
    }

    delta <- price - baseline_price
    delta_pct <- 100 * delta / baseline_price

    impact_results <- rbind(impact_results, data.frame(
      lambda = lam, v_u = v, v_d = v, Price = price,
      Delta_from_Lambda0 = delta, Delta_pct = delta_pct
    ))
  }
}

write.csv(impact_results, "benchmark/results/price_impact_analysis.csv", row.names = FALSE)
cat(sprintf("  Baseline (λ=0): $%.4f\n", baseline_price))
cat(sprintf("  λ=0.1, v=1: $%.4f (+%.2f%%)\n",
            impact_results$Price[impact_results$lambda==0.1 & impact_results$v_u==1],
            impact_results$Delta_pct[impact_results$lambda==0.1 & impact_results$v_u==1]))
cat(sprintf("  λ=0.2, v=1: $%.4f (+%.2f%%)\n\n",
            impact_results$Price[impact_results$lambda==0.2 & impact_results$v_u==1],
            impact_results$Delta_pct[impact_results$lambda==0.2 & impact_results$v_u==1]))

# TEST 3: Performance
cat("Test 3: Computational performance...\n")

n_values <- c(5, 8, 10, 12, 14, 16)
performance_results <- data.frame()

for (n_val in n_values) {
  kv_time <- system.time({
    kv_price <- price_kemma_vorst_geometric_binomial(S0_base, K_base, r_base, u_base, d_base, n_val)
  })
  kv_time_ms <- kv_time["elapsed"] * 1000

  pi_time <- system.time({
    pi_price <- price_geometric_asian(S0_base, K_base, r_base, u_base, d_base, 0.1, 1, 1, n_val)
  })
  pi_time_ms <- pi_time["elapsed"] * 1000

  time_ratio <- pi_time_ms / kv_time_ms
  num_paths <- 2^n_val

  performance_results <- rbind(performance_results, data.frame(
    n = n_val, Kemma_Vorst_Time_ms = kv_time_ms,
    Price_Impact_Time_ms = pi_time_ms, Time_Ratio = time_ratio, Num_Paths = num_paths
  ))
}

write.csv(performance_results, "benchmark/results/performance_comparison.csv", row.names = FALSE)
cat(sprintf("  n=10: KV=%.2fms, PI=%.1fms (%.0fx slower)\n",
            performance_results$Kemma_Vorst_Time_ms[performance_results$n==10],
            performance_results$Price_Impact_Time_ms[performance_results$n==10],
            performance_results$Time_Ratio[performance_results$n==10]))
cat(sprintf("  n=16: KV=%.2fms, PI=%.1fms (%.0fx slower)\n\n",
            performance_results$Kemma_Vorst_Time_ms[performance_results$n==16],
            performance_results$Price_Impact_Time_ms[performance_results$n==16],
            performance_results$Time_Ratio[performance_results$n==16]))

# TEST 4: Sensitivity
cat("Test 4: Strike sensitivity analysis...\n")

strike_values <- seq(80, 120, by = 5)
lambda_values_sens <- c(0, 0.05, 0.1, 0.2)
sensitivity_results <- data.frame()

for (K in strike_values) {
  moneyness <- if (K < S0_base) "ITM" else if (K == S0_base) "ATM" else "OTM"
  baseline <- price_kemma_vorst_geometric_binomial(S0_base, K, r_base, u_base, d_base, n_base)

  for (lam in lambda_values_sens) {
    if (lam == 0) {
      price <- baseline
    } else {
      price <- price_geometric_asian(S0_base, K, r_base, u_base, d_base, lam, 1, 1, n_base)
    }

    impact_cost <- price - baseline
    impact_pct <- 100 * impact_cost / baseline

    sensitivity_results <- rbind(sensitivity_results, data.frame(
      Strike = K, Lambda = lam, Moneyness = moneyness,
      Price = price, Impact_Cost = impact_cost, Impact_pct = impact_pct
    ))
  }
}

write.csv(sensitivity_results, "benchmark/results/sensitivity_analysis.csv", row.names = FALSE)
cat("  Completed for 9 strikes x 4 lambda values\n\n")

cat("=== BENCHMARK COMPLETE ===\n\n")
cat("Results saved to benchmark/results/\n")
