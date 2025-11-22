# ==============================================================================
# VISUALIZATION SCRIPT FOR BENCHMARK RESULTS
# ==============================================================================
#
# Purpose: Generate publication-quality plots from benchmark results
# Run this after running benchmark_comparison.Rmd
#
# ==============================================================================

library(AsianOptPI)
library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# Create plots directory
if (!dir.exists("benchmark/plots")) {
  dir.create("benchmark/plots", recursive = TRUE)
}

cat("\n")
cat("================================================================================\n")
cat("  GENERATING BENCHMARK VISUALIZATIONS\n")
cat("================================================================================\n\n")

# ==============================================================================
# LOAD RESULTS
# ==============================================================================

cat("Loading results...\n")

equivalence <- read.csv("benchmark/results/equivalence_test.csv")
impact <- read.csv("benchmark/results/price_impact_analysis.csv")
performance <- read.csv("benchmark/results/performance_comparison.csv")
sensitivity <- read.csv("benchmark/results/sensitivity_analysis.csv")

cat("✓ All results loaded\n\n")

# ==============================================================================
# PLOT 1: PRICE VS LAMBDA (Multiple Volumes)
# ==============================================================================

cat("Creating Plot 1: Price vs Lambda...\n")

p1 <- ggplot(impact, aes(x = lambda, y = Price, color = factor(v_u), group = v_u)) +
  geom_line(size = 1.5) +
  geom_point(size = 3, shape = 21, fill = "white", stroke = 1.5) +
  labs(
    title = "Option Price vs Price Impact Parameter",
    subtitle = "Geometric Average Asian Call Option (S0=K=100, n=10)",
    x = expression(paste("Price Impact Coefficient (", lambda, ")")),
    y = "Option Price ($)",
    color = "Hedging\nVolume (v)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold")
  ) +
  scale_color_brewer(palette = "Set1") +
  scale_x_continuous(breaks = seq(0, 0.5, 0.1)) +
  annotate("text", x = 0.05, y = min(impact$Price) * 1.02,
           label = "Kemma-Vorst\nBaseline", size = 3.5, hjust = 0, color = "gray50")

ggsave("benchmark/plots/price_vs_lambda.pdf", p1, width = 10, height = 6)
ggsave("benchmark/plots/price_vs_lambda.png", p1, width = 10, height = 6, dpi = 300)

cat("✓ Saved to: benchmark/plots/price_vs_lambda.pdf/png\n\n")

# ==============================================================================
# PLOT 2: IMPACT COST HEATMAP
# ==============================================================================

cat("Creating Plot 2: Impact Cost Heatmap...\n")

p2 <- impact %>%
  filter(lambda > 0) %>%
  ggplot(aes(x = factor(lambda), y = factor(v_u), fill = Delta_pct)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = sprintf("%.1f%%", Delta_pct)),
            color = "white", size = 5, fontface = "bold") +
  labs(
    title = "Price Increase Due to Hedging Impact",
    subtitle = "Percentage increase over λ=0 baseline (Kemma-Vorst)",
    x = expression(paste("Price Impact Coefficient (", lambda, ")")),
    y = "Hedging Volume (v)",
    fill = "Price\nIncrease (%)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    panel.grid = element_blank()
  ) +
  scale_fill_gradient2(
    low = "#2166AC", mid = "#FFFFBF", high = "#B2182B",
    midpoint = median(impact$Delta_pct[impact$lambda > 0]),
    breaks = seq(0, max(impact$Delta_pct), length.out = 5)
  )

ggsave("benchmark/plots/impact_cost_heatmap.pdf", p2, width = 10, height = 6)
ggsave("benchmark/plots/impact_cost_heatmap.png", p2, width = 10, height = 6, dpi = 300)

cat("✓ Saved to: benchmark/plots/impact_cost_heatmap.pdf/png\n\n")

# ==============================================================================
# PLOT 3: COMPUTATION TIME COMPARISON
# ==============================================================================

cat("Creating Plot 3: Computation Time Comparison...\n")

perf_long <- performance %>%
  select(n, Kemma_Vorst_Time_ms, Price_Impact_Time_ms) %>%
  pivot_longer(cols = c(Kemma_Vorst_Time_ms, Price_Impact_Time_ms),
               names_to = "Method", values_to = "Time_ms") %>%
  mutate(Method = recode(Method,
                         "Kemma_Vorst_Time_ms" = "Kemma-Vorst (Analytical)",
                         "Price_Impact_Time_ms" = "Price Impact (O(2^n))"))

p3 <- ggplot(perf_long, aes(x = n, y = Time_ms, color = Method, group = Method)) +
  geom_line(size = 1.5) +
  geom_point(size = 4, shape = 21, fill = "white", stroke = 1.5) +
  scale_y_log10(labels = scales::comma,
                breaks = c(0.1, 1, 10, 100, 1000, 10000)) +
  labs(
    title = "Computational Performance Comparison",
    subtitle = "Log scale shows exponential growth of path enumeration method",
    x = "Number of Time Steps (n)",
    y = "Computation Time (milliseconds, log scale)",
    color = "Method"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = c(0.25, 0.85),
    legend.title = element_text(face = "bold"),
    legend.background = element_rect(fill = "white", color = "gray70"),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold")
  ) +
  scale_color_manual(values = c("Kemma-Vorst (Analytical)" = "#2E86AB",
                                 "Price Impact (O(2^n))" = "#A23B72")) +
  annotate("text", x = 13, y = 0.5, label = "O(1)\nConstant Time",
           color = "#2E86AB", size = 4, fontface = "bold") +
  annotate("text", x = 13, y = 1000, label = "O(2^n)\nExponential Growth",
           color = "#A23B72", size = 4, fontface = "bold")

ggsave("benchmark/plots/computation_time.pdf", p3, width = 10, height = 6)
ggsave("benchmark/plots/computation_time.png", p3, width = 10, height = 6, dpi = 300)

cat("✓ Saved to: benchmark/plots/computation_time.pdf/png\n\n")

# ==============================================================================
# PLOT 4: STRIKE SENSITIVITY
# ==============================================================================

cat("Creating Plot 4: Strike Sensitivity...\n")

p4 <- ggplot(sensitivity, aes(x = Strike, y = Price, color = factor(Lambda), group = Lambda)) +
  geom_line(size = 1.5) +
  geom_point(size = 3, shape = 21, fill = "white", stroke = 1.5) +
  labs(
    title = "Option Price Surface: Strike vs Price Impact",
    subtitle = "Effect of moneyness across different price impact levels (S0=100, n=10)",
    x = "Strike Price (K)",
    y = "Option Price ($)",
    color = expression(lambda)
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold")
  ) +
  scale_color_brewer(palette = "Set1") +
  geom_vline(xintercept = 100, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  annotate("text", x = 101, y = max(sensitivity$Price) * 0.9,
           label = "ATM", angle = 90, color = "gray50", size = 4, fontface = "bold")

ggsave("benchmark/plots/strike_sensitivity.pdf", p4, width = 10, height = 6)
ggsave("benchmark/plots/strike_sensitivity.png", p4, width = 10, height = 6, dpi = 300)

cat("✓ Saved to: benchmark/plots/strike_sensitivity.pdf/png\n\n")

# ==============================================================================
# PLOT 5: IMPACT BY MONEYNESS
# ==============================================================================

cat("Creating Plot 5: Impact by Moneyness...\n")

p5 <- sensitivity %>%
  filter(Lambda > 0) %>%
  mutate(Moneyness = factor(Moneyness, levels = c("ITM", "ATM", "OTM"))) %>%
  ggplot(aes(x = Strike, y = Impact_pct, color = factor(Lambda), group = Lambda)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  facet_wrap(~Moneyness, scales = "free_x") +
  labs(
    title = "Price Impact by Moneyness Category",
    subtitle = "Percentage increase over λ=0 baseline",
    x = "Strike Price (K)",
    y = "Price Increase (%)",
    color = expression(lambda)
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 12),
    strip.background = element_rect(fill = "gray90", color = NA),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold")
  ) +
  scale_color_brewer(palette = "Set1")

ggsave("benchmark/plots/impact_by_moneyness.pdf", p5, width = 12, height = 6)
ggsave("benchmark/plots/impact_by_moneyness.png", p5, width = 12, height = 6, dpi = 300)

cat("✓ Saved to: benchmark/plots/impact_by_moneyness.pdf/png\n\n")

# ==============================================================================
# PLOT 6: COMBINED SUMMARY PANEL
# ==============================================================================

cat("Creating Plot 6: Combined Summary Panel...\n")

# Small versions for panel
p1_small <- p1 + theme(legend.position = "none", plot.title = element_text(size = 12))
p2_small <- p2 + theme(legend.position = "none", plot.title = element_text(size = 12))
p3_small <- p3 + theme(legend.position = "none", plot.title = element_text(size = 12))
p4_small <- p4 + theme(legend.position = "none", plot.title = element_text(size = 12))

combined <- grid.arrange(p1_small, p2_small, p3_small, p4_small, ncol = 2,
                         top = grid::textGrob("Benchmark Summary: Kemma-Vorst vs Price Impact",
                                        gp = grid::gpar(fontsize = 18, fontface = "bold")))

ggsave("benchmark/plots/combined_summary.pdf", combined, width = 14, height = 10)
ggsave("benchmark/plots/combined_summary.png", combined, width = 14, height = 10, dpi = 300)

cat("✓ Saved to: benchmark/plots/combined_summary.pdf/png\n\n")

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("  VISUALIZATION COMPLETE\n")
cat("================================================================================\n\n")

cat("Generated plots:\n")
cat("1. price_vs_lambda.pdf/png         - Price as function of λ\n")
cat("2. impact_cost_heatmap.pdf/png     - Heatmap of price increase\n")
cat("3. computation_time.pdf/png        - Performance comparison\n")
cat("4. strike_sensitivity.pdf/png      - Price surface over K and λ\n")
cat("5. impact_by_moneyness.pdf/png     - Impact across moneyness categories\n")
cat("6. combined_summary.pdf/png        - All plots in one panel\n\n")

cat("All plots saved to: benchmark/plots/\n\n")

cat("✓ Visualization complete!\n\n")
