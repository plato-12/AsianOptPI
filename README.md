# AsianOptPI: Asian Option Pricing with Price Impact

<!-- badges: start -->
[![R-CMD-check](https://github.com/yourusername/AsianOptPI/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yourusername/AsianOptPI/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/AsianOptPI)](https://CRAN.R-project.org/package=AsianOptPI)
<!-- badges: end -->

## Overview

AsianOptPI implements binomial tree pricing for Asian options with market price impact from hedging activities. The package provides:

- **Exact geometric Asian option pricing** via path enumeration
- **Arithmetic Asian option bounds** using Jensen's inequality
- **Price impact modeling** for hedging-induced price movements
- **Risk-neutral valuation** with the replicating portfolio method

## Installation

```r
# Install from CRAN (once published)
install.packages("AsianOptPI")

# Development version from GitHub
# install.packages("devtools")
devtools::install_github("yourusername/AsianOptPI")
```

## Quick Start

```r
library(AsianOptPI)

# Price geometric Asian call option
price <- price_geometric_asian(
  S0 = 100,      # Initial stock price
  K = 100,       # Strike price
  r = 1.05,      # Gross risk-free rate (5%)
  u = 1.2,       # Up factor
  d = 0.8,       # Down factor
  lambda = 0.1,  # Price impact coefficient
  v_u = 1,       # Hedging volume (up)
  v_d = 1,       # Hedging volume (down)
  n = 3          # Time steps
)

print(price)

# Compute bounds for arithmetic Asian option
bounds <- arithmetic_asian_bounds(
  S0 = 100, K = 100, r = 1.05,
  u = 1.2, d = 0.8,
  lambda = 0.1, v_u = 1, v_d = 1, n = 3
)

print(bounds)
```

## Key Features

### Price Impact Mechanism

When market makers hedge options, their trading causes price movements:

$$\Delta S = \lambda \cdot v \cdot \text{sign}(\text{trade})$$

This modifies the binomial tree:
- Effective up factor: $\tilde{u} = u \cdot e^{\lambda v^u}$
- Effective down factor: $\tilde{d} = d \cdot e^{-\lambda v^d}$
- Risk-neutral probability: $p^{eff} = \frac{r - \tilde{d}}{\tilde{u} - \tilde{d}}$

### Computational Complexity

The algorithm enumerates all $2^n$ price paths, making it suitable for:
- **n ≤ 15**: Fast (< 1 second)
- **n = 20**: ~1 million paths (~10 seconds)
- **n > 20**: Memory/time intensive (warnings issued)

## Documentation

- Theoretical Background: Mathematical derivations (vignette)
- Practical Examples: Use cases and comparisons (vignette)
- Function Reference: Complete API documentation

## Citation

If you use this package in research, please cite:

```
Tiwari, P. (2025). AsianOptPI: Asian Option Pricing with Price Impact.
R package version 0.1.0.
```

## License

GPL-3

## References

Cox, J. C., Ross, S. A., & Rubinstein, M. (1979). Option pricing: A simplified approach. *Journal of Financial Economics*, 7(3), 229-263.
