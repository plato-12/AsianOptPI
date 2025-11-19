# AsianOptPI 0.1.0

## Initial Release

- Implemented geometric Asian option pricing with price impact
- Added arithmetic Asian option bounds via Jensen's inequality
- Included utility functions for risk-neutral probability computation
- Comprehensive documentation with mathematical background
- Full test coverage
- Two vignettes: theory and practical examples

## Features

- `price_geometric_asian()`: Exact binomial pricing
- `arithmetic_asian_bounds()`: Lower and upper bounds
- `compute_p_eff()`: Effective risk-neutral probability
- `compute_effective_factors()`: Modified up/down factors
- `check_no_arbitrage()`: Validation utility

## Performance

- Efficient C++ implementation with Rcpp
- Handles n ≤ 20 comfortably
- Warnings for large n (> 20)
