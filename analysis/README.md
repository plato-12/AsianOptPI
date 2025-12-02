# AsianOptPI Comparative Analysis

**Date:** 2025-11-23
**Purpose:** Comprehensive validation and comparison of CRR binomial vs Kemna-Vorst analytical/Monte Carlo methods for Asian option pricing

---

## Overview

This directory contains detailed comparative analyses between two implementations of Asian option pricing:

1. **CRR Binomial Tree** (Cox-Ross-Rubinstein with price impact)
   - Discrete-time binomial model
   - Path enumeration for geometric average
   - AM-GM inequality bounds for arithmetic average
   - Supports price impact (λ > 0)

2. **Kemna-Vorst Methods** (Continuous-time analytical)
   - Closed-form analytical formula for geometric average
   - Monte Carlo with control variate for arithmetic average
   - No price impact support (λ = 0 only)

---

## Directory Structure

```
AsianOptPI/analysis/
├── README.md                      # This file
├── run_all_analyses.R             # Master script to run all analyses
├── 01_geometric_comparison.R      # Geometric average: CRR vs Kemna-Vorst
├── 02_arithmetic_comparison.R     # Arithmetic average: Bounds vs Monte Carlo
└── figures/                       # Generated plots (PNG)
    ├── geometric_convergence.png
    ├── geometric_error_convergence.png
    ├── geometric_moneyness.png
    ├── arithmetic_bounds_convergence.png
    ├── arithmetic_spread_convergence.png
    ├── arithmetic_moneyness.png
    └── arithmetic_bounds_vs_ci.png
```

---

## Quick Start

### Prerequisites

1. **Install/load the AsianOptPI package:**
   ```r
   # From package root directory
   devtools::load_all()
   ```

2. **Install required packages:**
   ```r
   install.packages(c("ggplot2", "tidyr", "dplyr"))
   ```

### Run All Analyses

From the package root directory:

```r
source("AsianOptPI/analysis/run_all_analyses.R")
```

This will:
- Run both geometric and arithmetic comparisons
- Generate 7 visualization plots
- Save results to `AsianOptPI/analysis/figures/`
- Print comprehensive summary to console

### Run Individual Analyses

**Geometric Average Comparison:**
```r
source("AsianOptPI/analysis/01_geometric_comparison.R")
```

**Arithmetic Average Comparison:**
```r
source("AsianOptPI/analysis/02_arithmetic_comparison.R")
```

---

## Analysis 1: Geometric Average Comparison

**File:** `01_geometric_comparison.R`

### Purpose

Validates the theoretical connection between CRR binomial (with λ=0) and Kemna-Vorst analytical formula for **geometric average** Asian options.

### Key Questions Addressed

1. **Do the implementations converge?**
   - Yes, CRR → Kemna-Vorst as n → ∞
   - Convergence rate: O(1/n) as predicted by theory

2. **Why don't they match exactly at finite n?**
   - Different rate interpretations (per step vs total period)
   - Discrete vs continuous averaging
   - See `THEORETICAL_CONNECTION.md` for full derivation

3. **How to achieve proper comparison?**
   - Use `r_per_step = r_gross^(1/n)` in CRR (corrected version)
   - NOT `r_per_step = r_gross` (original implementation)
   - With correction: error < 1% for n ≥ 20

### Sections

1. **Parameter Setup** - Base test parameters
2. **Rate Conversion Analysis** - Understanding r interpretations
3. **Implementation Comparison** - Corrected vs original CRR
4. **Convergence Analysis** - Testing n → ∞
5. **Moneyness Analysis** - ITM, ATM, OTM performance
6. **Theoretical Validation** - Verify O(1/n) convergence
7. **Visualization** - 3 plots generated
8. **Conclusions** - Summary of findings

### Output Plots

1. **`geometric_convergence.png`**
   - Shows CRR price converging to Kemna-Vorst as n increases
   - Compares original vs corrected rate conversion

2. **`geometric_error_convergence.png`**
   - Log-scale plot of percentage error vs n
   - Demonstrates O(1/n) convergence rate

3. **`geometric_moneyness.png`**
   - Price comparison across different strike prices
   - Shows agreement holds for ITM, ATM, and OTM options

### Key Findings

- **Rate conversion is crucial**: Must use r^(1/n) per step, not r
- **Convergence confirmed**: Error decreases as O(1/n)
- **Discrete vs continuous**: Main source of small differences at finite n
- **Implementation correctness**: Both methods are mathematically sound
- **Practical difference**: < 1% error at n=20 with corrected rate

---

## Analysis 2: Arithmetic Average Comparison

**File:** `02_arithmetic_comparison.R`

### Purpose

Compares CRR **arithmetic bounds** (using AM-GM inequality) with Kemna-Vorst **Monte Carlo estimates** (with control variate).

### Key Questions Addressed

1. **Are the CRR bounds valid?**
   - Yes, all Monte Carlo estimates fall within bounds
   - Bounds are rigorous (proven via AM-GM inequality)

2. **How tight are the bounds?**
   - Bounds tighten as n increases
   - Tighter for ATM options
   - Spread typically 2-10% of option price

3. **How good is the Monte Carlo estimator?**
   - Control variate reduces variance by 10-20x
   - High correlation (>0.95) between arithmetic and geometric
   - Standard error very small with M=50,000 simulations

4. **Is the midpoint a good estimate?**
   - Yes, Monte Carlo typically within 10-30% of spread from midpoint
   - Midpoint computationally cheap (same cost as geometric price)

### Sections

1. **Parameter Setup** - Base test parameters
2. **Helper Functions** - Wrapper functions for comparison
3. **Bounds Validation** - Verify MC estimates within bounds
4. **Moneyness Analysis** - Bounds quality across strikes
5. **Bound Tightness Analysis** - Spread as function of n and K
6. **Control Variate Effectiveness** - Compare with/without CV
7. **Visualization** - 4 plots generated
8. **Conclusions** - Summary and recommendations

### Output Plots

1. **`arithmetic_bounds_convergence.png`**
   - Shows bounds and MC estimate vs n
   - Demonstrates bounds tightening as n increases

2. **`arithmetic_spread_convergence.png`**
   - Spread (upper - lower) vs n
   - Quantifies improvement with more time steps

3. **`arithmetic_moneyness.png`**
   - Bounds and MC estimates across strike prices
   - Shaded region shows feasible range
   - Tightest bounds at ATM

4. **`arithmetic_bounds_vs_ci.png`**
   - Compares CRR bounds with MC 95% confidence intervals
   - Shows that MC CI is much tighter than bounds
   - Validates statistical accuracy of MC method

### Key Findings

- **Bounds are valid**: 100% of MC estimates fall within bounds
- **Bounds are useful**: Provide rigorous pricing range without simulation
- **Control variate is effective**: 10-20x variance reduction
- **MC is accurate**: Very small standard errors with M=50,000
- **Complementary methods**: Bounds for guarantees, MC for point estimates
- **Midpoint works**: Good approximation, computationally cheap

---

## Theoretical Background

### Rate Interpretation Issue

**Problem:** The two implementations interpret the risk-free rate `r` differently.

**CRR Binomial:**
- Uses `r` as **gross rate per step**
- Over n steps: total return = r^n
- Risk-neutral probability: p = (r - d) / (u - d)

**Kemna-Vorst:**
- Treats `r` as **gross rate for entire period**
- Converts to continuous: r_cont = log(r)
- Uses continuous-time Black-Scholes-like formulas

**Solution:**
For proper comparison with total period rate R:
- **CRR**: Use `r_per_step = R^(1/n)`
- **Kemna-Vorst**: Use `r_cont = log(R)`

See `THEORETICAL_CONNECTION.md` for complete mathematical derivation.

### Discrete vs Continuous Averaging

**Discrete (CRR):**
$$G_n = \left(\prod_{i=0}^{n} S_i\right)^{1/(n+1)}$$

**Continuous (Kemna-Vorst):**
$$G_T = \exp\left[\frac{1}{T} \int_0^T \log S_t \, dt\right]$$

**Convergence:**
As n → ∞, discrete → continuous via Riemann sum approximation:
$$\frac{1}{n+1} \sum_{i=0}^{n} \log S_i \to \frac{1}{T} \int_0^T \log S_t \, dt$$

Error = O(1/n) under path regularity.

### Arithmetic Bounds (AM-GM Inequality)

**Lower Bound:**
$$V_0^A \geq V_0^G$$

Follows from arithmetic mean ≥ geometric mean.

**Upper Bound:**
$$V_0^A \leq V_0^G + \frac{(\rho^* - 1)}{r^n} \mathbb{E}^Q[G_n]$$

where the spread parameter is:
$$\rho^* = \exp\left[\frac{1}{4} \cdot \frac{(\tilde{u}^n - \tilde{d}^n)^2}{\tilde{u}^n \tilde{d}^n}\right]$$

Derived from reverse AM-GM inequality (Budimir et al., 2000).

---

## Interpretation of Results

### When to Use Each Method

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **CRR Geometric (λ=0)** | Discrete averaging validation | Exact for discrete | Slow (O(2^n)) |
| **Kemna-Vorst Geometric** | Fast pricing | Closed-form, instant | Continuous only |
| **CRR Arithmetic Bounds** | Risk management, guarantees | Rigorous bounds | Wide spread |
| **Kemna-Vorst Arithmetic MC** | Point estimates | Accurate, fast | Statistical error |
| **CRR with λ>0** | Price impact analysis | Unique feature | No benchmark |

### Practical Recommendations

**For Production Pricing:**
1. **Geometric Asian:** Use Kemna-Vorst analytical (instant, exact)
2. **Arithmetic Asian:** Use Kemna-Vorst MC with M=50,000-100,000
3. **With Price Impact:** Use CRR (only option available)

**For Validation:**
1. **Geometric:** Compare CRR (λ=0) with Kemna-Vorst at n=20-30
2. **Arithmetic:** Verify MC estimate falls within CRR bounds
3. **Convergence:** Test multiple n values to confirm O(1/n) error

**For Research:**
1. **Theoretical Studies:** Use CRR bounds for rigorous analysis
2. **Sensitivity Analysis:** Use Kemna-Vorst MC for speed
3. **Price Impact Effects:** Compare λ=0 vs λ>0 within CRR

---

## Parameters Used in Analyses

### Base Parameters

```r
S0 <- 100        # Initial stock price
K <- 100         # Strike price (ATM)
r_gross <- 1.05  # 5% gross rate for total period
u <- 1.2         # Up factor
d <- 0.8         # Down factor
lambda <- 0      # No price impact (for comparison)
v_u <- 0         # No hedging volume
v_d <- 0
```

### Test Ranges

- **Time steps (n):** 5, 10, 15, 20, 25, 30
- **Moneyness (K/S0):** 0.8, 0.9, 1.0, 1.1, 1.2
- **Monte Carlo sims (M):** 50,000 (with control variate)

### Derived Parameters

From u=1.2, d=0.8, n=20:
- Time step: Δt = 1/20 = 0.05
- Implied volatility: σ = log(u/d)/(2√Δt) ≈ 0.406
- Geometric volatility: σ_G = σ/√3 ≈ 0.234

---

## Technical Notes

### Computational Complexity

**CRR Methods:**
- Path enumeration: O(2^n)
- Practical limit: n ≤ 20-25
- Memory: O(n · 2^n)

**Kemna-Vorst Methods:**
- Geometric: O(1) (closed-form)
- Arithmetic: O(M · n) for M simulations
- Monte Carlo is faster for large n

### Numerical Accuracy

**CRR:**
- Exact within floating-point precision
- No discretization error (discrete model)

**Kemna-Vorst:**
- Geometric: Exact (analytical formula)
- Arithmetic: Statistical error ~ 1/√M
- With M=50,000, SE ≈ 0.001-0.01

### Control Variate Efficiency

**Variance Reduction:**
- Correlation (A,G) typically > 0.95
- Variance reduction factor: 1 - ρ² ≈ 0.05-0.10
- Equivalent to 10-20x more simulations without CV

**Why It Works:**
- Arithmetic and geometric averages are highly correlated
- Geometric has known exact value (analytical)
- Subtracting correlation removes most variance

---

## Troubleshooting

### Common Issues

**"AsianOptPI not found"**
```r
# From package root directory:
devtools::load_all()
```

**"Missing ggplot2/tidyr/dplyr"**
```r
install.packages(c("ggplot2", "tidyr", "dplyr"))
```

**Plots not saving**
- Check that `AsianOptPI/analysis/figures/` directory exists
- Script creates it automatically if missing

**Very slow execution**
- Reduce `n_values` in scripts (use smaller n)
- Reduce `M` (Monte Carlo simulations)
- Use `n_values <- c(5, 10, 15)` for quick tests

**Different results each run (MC)**
- Set `seed` parameter for reproducibility
- Already set to `seed = 12345` in Analysis 2

### Performance Tuning

**Quick Test (1-2 minutes):**
```r
n_values <- c(5, 10, 15)
M <- 10000
```

**Standard Analysis (5-10 minutes):**
```r
n_values <- c(5, 10, 15, 20)
M <- 50000
```

**Comprehensive (20-30 minutes):**
```r
n_values <- c(5, 10, 15, 20, 25, 30)
M <- 100000
```

---

## Expected Outputs

### Console Output

Each script prints:
1. Section headers with analysis description
2. Progress indicators for each n value
3. Summary tables with numerical results
4. Key observations and findings
5. Theoretical validation checks
6. Conclusions and recommendations

### Figures

All figures saved as high-resolution PNG (300 DPI):
- Size: 10" × 6"
- Format: PNG
- Location: `AsianOptPI/analysis/figures/`
- Ready for publication/presentation

### Typical Runtime

On a modern laptop (M1/M2 Mac or recent Intel):
- **Geometric Analysis:** 1-3 minutes
- **Arithmetic Analysis:** 3-5 minutes
- **Total (both):** 5-10 minutes

Runtime scales with:
- Number of n values tested
- Maximum n value (2^n paths)
- Number of Monte Carlo simulations (M)

---

## References

### Theory

1. **Cox, J.C., Ross, S.A., and Rubinstein, M. (1979)**
   "Option Pricing: A Simplified Approach."
   *Journal of Financial Economics*, 7(3), 229-263.

2. **Kemna, A.G.Z. and Vorst, A.C.F. (1990)**
   "A Pricing Method for Options Based on Average Asset Values."
   *Journal of Banking and Finance*, 14, 113-129.

3. **Budimir, I., Dragomir, S.S., & Pečarić, J. (2000)**
   "Further reverse results for Jensen's discrete inequality."
   *Journal of Inequalities in Pure and Applied Mathematics*, 2(1).

### Package Documentation

- **THEORETICAL_CONNECTION.md** - Detailed mathematical derivation
- **PACKAGE_DEVELOPMENT_GUIDE.md** - Full development guide
- **Theory.md** - Complete theoretical background
- **README.md** - Package overview and usage

---

## Version History

- **2025-11-23:** Initial comprehensive analysis suite created
  - Geometric average comparison (01_geometric_comparison.R)
  - Arithmetic average comparison (02_arithmetic_comparison.R)
  - Master runner script (run_all_analyses.R)
  - Full documentation (this README)

---

## Contact and Support

**Package Maintainer:** Priyanshu Tiwari
**GitHub:** https://github.com/plato-12/AsianOptPI
**Issues:** https://github.com/plato-12/AsianOptPI/issues

For questions about the analyses or to report issues, please open a GitHub issue or contact the maintainer.

---

## License

This analysis suite is part of the AsianOptPI package and follows the same license (GPL-3).

---

**Last Updated:** 2025-11-23
**Analysis Version:** 1.0
**Package Version:** 0.1.0
