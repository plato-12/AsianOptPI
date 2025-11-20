# AsianOptPI 0.1.0

## Initial Release (November 2025)

This is the initial development release of AsianOptPI, implementing binomial tree pricing for Asian options with market price impact from hedging activities.

### Core Features

#### Pricing Functions
- `price_geometric_asian()`: Exact pricing for geometric Asian call options
  - Complete path enumeration algorithm
  - Efficient C++ implementation via Rcpp
  - Handles up to n = 20 time steps comfortably

- `arithmetic_asian_bounds()`: Upper and lower bounds for arithmetic Asian options
  - Lower bound using AM-GM inequality
  - Upper bound via reverse Jensen's inequality
  - Returns comprehensive bound information (lower, upper, ρ*, E^Q[G_n])

#### Utility Functions
- `compute_p_eff()`: Compute effective risk-neutral probability with price impact
- `compute_effective_factors()`: Calculate modified up/down factors (ũ, d̃)
- `check_no_arbitrage()`: Validate no-arbitrage condition d̃ < r < ũ

#### Price Impact Model
- Incorporates hedging-induced stock price movements: ΔS = λ·v·sign(trade)
- Modifies binomial tree with effective factors: ũ = u·e^(λv^u), d̃ = d·e^(-λv^d)
- Adjusts risk-neutral probability: p^eff = (r - d̃)/(ũ - d̃)

### Input Validation

Comprehensive parameter validation including:
- Positivity checks (S0, K, r, u, d must be positive)
- Non-negativity for price impact parameters (λ, v_u, v_d ≥ 0)
- Ordering constraint (u > d)
- **Critical no-arbitrage validation** (d̃ < r < ũ)
- Risk-neutral probability bounds (p^eff ∈ [0,1])
- Performance warnings for large n (> 20)

### Documentation

#### Package Documentation
- Comprehensive package-level documentation in `?AsianOptPI`
- Mathematical framework with LaTeX formulas
- Price impact mechanism explained
- No-arbitrage condition detailed
- Computational complexity analysis

#### Function Documentation
- Complete Roxygen documentation for all functions
- All parameters documented with @param
- Return values specified with @return
- Mathematical details in @details sections
- Working examples in @examples
- Academic references in @references

#### README
- Quick start guide with examples
- Detailed mathematical explanations
- Usage examples for all functions
- Sensitivity analysis demonstrations
- Error handling examples
- Performance benchmarks

### Implementation Details

#### C++ Core (src/)
- `utils.cpp`: Core utility functions
  - Effective factor calculations
  - Geometric and arithmetic mean computations
  - Price path generation

- `geometric_asian.cpp`: Geometric Asian option pricing
  - Recursive binary path enumeration (2^n paths)
  - Risk-neutral valuation with price impact
  - Optimized for performance

- `arithmetic_bounds.cpp`: Arithmetic Asian bounds
  - Jensen's inequality implementation
  - Spread parameter ρ* calculation
  - Expected geometric average computation

#### R Wrapper Layer (R/)
- `validation.R`: Input validation module
- `price_impact_utils.R`: Utility function wrappers
- `geometric_asian.R`: Geometric pricing wrapper
- `arithmetic_asian.R`: Arithmetic bounds wrapper with S3 print method

### Performance

- **Fast**: n ≤ 15 completes in < 1 second
- **Acceptable**: n = 20 takes ~10 seconds (1 million paths)
- **Warning**: Automatic warning issued for n > 20
- **Efficient**: C++11 implementation with Rcpp integration

### Testing

- All core functions tested and validated
- Mathematical properties verified:
  - Price with impact > Price without impact (for calls)
  - Lower bound ≤ Upper bound
  - ρ* ≥ 1 (required by theory)
  - No-arbitrage condition enforcement

- Input validation thoroughly tested:
  - Catches invalid parameters (negative values, u ≤ d, etc.)
  - Detects no-arbitrage violations
  - Issues performance warnings

### S3 Methods

- `print.arithmetic_bounds()`: Pretty printing for bounds objects
  - Formatted table display
  - Shows all key metrics
  - Includes midpoint estimate

### Development Status

**Completed Phases**:
- ✅ Phase 1: Package skeleton and infrastructure
- ✅ Phase 2: Core C++ implementation
- ✅ Phase 3: R wrapper functions with validation
- ✅ Phase 4: Enhanced documentation

**Planned for Future Releases**:
- Phase 5: Comprehensive unit testing with testthat
- Phase 6: Theory and examples vignettes
- Phase 7: CRAN compliance checks
- Phase 8: CRAN submission

### Dependencies

- R (>= 4.0.0)
- Rcpp (>= 1.0.0)

### References

**Primary Model**:
Cox, J. C., Ross, S. A., & Rubinstein, M. (1979). Option pricing: A simplified approach. *Journal of Financial Economics*, 7(3), 229-263.

**Bounds Theory**:
Budimir, I., Dragomir, S. S., & Pečarić, J. (2000). Further reverse results for Jensen's discrete inequality and applications in information theory. *Journal of Inequalities in Pure and Applied Mathematics*, 2(1).

### Notes

- This is a development release implementing core functionality
- Package uses gross rates (r = 1.05 for 5%, not r = 0.05)
- All functions automatically validate no-arbitrage conditions
- C++11 standard required for compilation
- Comprehensive error messages for invalid inputs

### Known Limitations

- Path enumeration complexity: O(2^n) limits practical use to n ≤ 20
- Memory usage: O(n·2^n) for storing all paths
- Currently supports only call options (put options planned for future releases)
- Single option type per call (no portfolio pricing yet)

### Acknowledgments

Development supported by comprehensive mathematical analysis and rigorous testing procedures. Implementation follows CRAN best practices for R package development.
