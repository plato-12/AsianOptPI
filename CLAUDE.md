# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**AsianOptPI** is an R package implementing binomial tree pricing for Asian options with market price impact from hedging activities. The package targets CRAN submission and is currently in Phase 6 complete (vignettes), preparing for Phase 7 (CRAN compliance).

**GitHub**: https://github.com/plato-12/AsianOptPI
**Status**: Phase 6 complete - Core functionality, documentation, tests, and vignettes implemented

**Progress**: 75% complete (6/8 phases)
- ✅ Phase 1: Initial Setup
- ✅ Phase 2: Core Implementation (C++/Rcpp)
- ✅ Phase 3: R Wrapper Functions
- ✅ Phase 4: Documentation
- ✅ Phase 5: Testing (166 tests passing)
- ✅ Phase 6: Vignettes
- ⏳ Phase 7: CRAN Compliance (next)
- ⏳ Phase 8: Submission

## Mathematical Foundation

### Price Impact Mechanism

The package extends the Cox-Ross-Rubinstein (CRR) binomial model to incorporate **hedging-induced price movements**:

When market makers hedge an option by trading volume $v$, the stock price is impacted:
$$\Delta S = \lambda v \cdot \text{sign}(\text{trade})$$

This modifies the binomial tree dynamics:
- **Effective up factor**: $\tilde{u} = u \cdot e^{\lambda v^u}$
- **Effective down factor**: $\tilde{d} = d \cdot e^{-\lambda v^d}$
- **Effective risk-neutral probability**: $p^{eff} = \frac{r - \tilde{d}}{\tilde{u} - \tilde{d}}$

### No-Arbitrage Constraint

For valid pricing, the following **must** hold:
$$\boxed{\tilde{d} < r < \tilde{u}}$$

This ensures $p^{eff} \in [0,1]$. Under standard assumptions ($d < r < u$ and $v^u, v^d \geq 0$), this is automatically satisfied.

### Geometric Asian Options

**Payoff**: $V_n = \max[0, G_n - K]$ where $G_n = \left(\prod_{i=0}^{n} S_i\right)^{1/(n+1)}$

**Key Property**: The geometric average depends on the **cumulative sum of exponents**, making it path-dependent:
$$G(\text{path}) = S_0 \left(\tilde{u}^{A(\text{path})} \tilde{d}^{B(\text{path})}\right)^{1/(n+1)}$$

where $A(\text{path}) = \sum_{i=0}^{n} a_i$ (sum of cumulative up-counts) and $a_i + b_i = i$ at each time $i$.

**No Closed Form**: Unlike standard European options, geometric Asian options with price impact have **no simple closed-form solution** because:
1. The average depends on **when** ups/downs occur, not just **how many**
2. Tree does not recombine—must enumerate all $2^n$ paths
3. Path probabilities follow binomial distribution, but payoffs do not

**Pricing Formula**:
$$V_0 = \frac{1}{r^n} \sum_{\omega \in \{U,D\}^n} \left(p^{eff}\right)^{\#U(\omega)} \left(1-p^{eff}\right)^{n-\#U(\omega)} \max[0, G(\omega) - K]$$

### Arithmetic Asian Options

**Payoff**: $V_n = \max[0, A_n - K]$ where $A_n = \frac{1}{n+1}\sum_{i=0}^{n} S_i$

**No Exact Formula**: Even more complex than geometric—use bounds instead.

**Lower Bound** (from AM-GM inequality):
$$V_0^A \geq V_0^G$$

**Upper Bound** (from reverse AM-GM, Budimir et al. 2000):
$$V_0^A \leq V_0^G + \frac{(\rho^* - 1)}{r^n} \mathbb{E}^Q[G_n]$$

where the **spread parameter** is:
$$\rho^* = \exp\left[\frac{1}{4} \cdot \frac{(\tilde{u}^n - \tilde{d}^n)^2}{\tilde{u}^n \tilde{d}^n}\right]$$

**Interpretation**:
- Lower bound is tight (exact geometric price)
- Upper bound depends on price volatility spread
- Higher price impact (larger $\lambda$) → looser bounds
- Midpoint often provides good estimate for $V_0^A$

**Key Insight**: Both bounds require computing $V_0^G$ and $\mathbb{E}^Q[G_n]$, so computational complexity is still $O(2^n)$.

## Computational Efficiency

### Algorithmic Complexity

**Path Enumeration**: $O(2^n)$ complexity—must generate and evaluate all possible price paths.

**Memory**: Each path stores $n+1$ stock prices → $O(n \cdot 2^n)$ total memory.

**Practical Limits**:
- **n ≤ 15**: Fast (< 1 second, 32K paths)
- **n = 20**: ~1 million paths (~10 seconds)
- **n > 20**: Issue **warning** to user

### Implementation Strategy

**Path Generation** (recursive binary enumeration):
```cpp
void generate_paths(int n, int step, vector<int>& current, vector<vector<int>>& all_paths) {
    if (step == n) {
        all_paths.push_back(current);
        return;
    }
    current[step] = 1; generate_paths(n, step+1, current, all_paths); // Up
    current[step] = 0; generate_paths(n, step+1, current, all_paths); // Down
}
```

**Critical**: Use **pre-allocation** for vectors to avoid repeated memory allocation during recursion.

**Optimization Opportunities** (future):
1. **Early termination**: Skip deep OTM paths (if $S_0 \tilde{u}^n < K$, geometric avg always < K)
2. **OpenMP parallelization**: Parallelize outer path loop (independent computations)
3. **Iterative generation**: Avoid recursion stack overhead for large $n$

### Performance Warnings

**Must warn users when n > 20**:
```r
if (n > 20) {
  warning(sprintf("n = %d will enumerate 2^%d = %d paths. This may be slow.",
                  n, n, 2^n))
}
```

## Development Commands

### Core Workflow

```r
# Load package (from package root)
devtools::load_all()

# After C++ changes: clean and rebuild
pkgbuild::clean_dll()
devtools::load_all()

# Generate documentation
devtools::document()

# Run tests
devtools::test()
```

### Validation

```r
# Full R CMD check
devtools::check()                    # Must return 0 errors, 0 warnings, 0 notes

# Multi-platform checks
devtools::check_win_devel()          # Windows
rhub::check_for_cran()               # Multiple platforms

# Additional checks
spelling::spell_check_package()      # Spelling
urlchecker::url_check()              # URLs
covr::package_coverage()             # Coverage (target > 90%)
```

### Building

```r
# Build source tarball (for CRAN)
devtools::build()

# Build vignettes
devtools::build_vignettes()
```

## CRAN Submission Standards

### Critical Requirements

1. **R CMD check**: **0 errors, 0 warnings, 0 notes**
   - Run `devtools::check()` repeatedly during development
   - Address all issues immediately

2. **Examples**: Must run in **< 5 seconds** each
   - Wrap slow examples: `\donttest{ ... }`
   - Use small $n$ values in examples ($n \leq 5$)

3. **Documentation**: All exported functions need:
   - `@param` for every parameter
   - `@return` describing output type and structure
   - `@examples` with working code
   - `@references` for academic citations (use DOI format)

4. **Tests**: Coverage **> 90%**
   - Test input validation thoroughly
   - Test mathematical properties (monotonicity, bounds)
   - Test edge cases (deep ITM/OTM, n=1, lambda=0)

5. **No-arbitrage validation**: **Critical** that all functions check $\tilde{d} < r < \tilde{u}$ and reject invalid inputs with clear error messages

### Common CRAN Rejections to Avoid

- **Undocumented parameters**: Every `@param` must be documented
- **Long examples**: Use `\donttest{}` or reduce $n$
- **Non-ASCII characters**: Use `\eqn{}` for math symbols
- **Missing references**: DESCRIPTION must cite Cox, Ross & Rubinstein (1979) with DOI
- **No `.registration = TRUE`**: Already in `R/AsianOptPI-package.R`

### Parameter Convention

**Critical**: Use **gross rates** (not net rates):
```r
r = 1.05  # Correct (5% rate)
r = 0.05  # WRONG
```

This is documented in Theory.md and must be enforced in validation.

## Code Architecture (Implemented)

### C++ Layer (`src/`)

**`utils.cpp`**:
- `compute_effective_factors()`: Returns `{u_tilde, d_tilde, p_eff}`
- `geometric_mean()`, `arithmetic_mean()`: Average computations
- `generate_price_path()`: Constructs $S_0, S_1, \ldots, S_n$ for a given path

**`geometric_asian.cpp`**:
- `generate_all_paths()`: Recursive binary path generation
- `price_geometric_asian_cpp()`: Main pricing algorithm
  - Enumerate $2^n$ paths
  - Compute $G(\omega)$ per path using product of prices
  - Calculate payoff: $\max(0, G(\omega) - K)$
  - Return: $\frac{1}{r^n} \sum_{\omega} P(\omega) \cdot \text{payoff}(\omega)$

**`arithmetic_bounds.cpp`**:
- `arithmetic_asian_bounds_cpp()`: Compute bounds
  - Lower bound: Call `price_geometric_asian_cpp()`
  - Compute $\mathbb{E}^Q[G_n] = \sum_{\omega} P(\omega) G(\omega)$
  - Compute $\rho^* = \exp\left[\frac{(\tilde{u}^n - \tilde{d}^n)^2}{4\tilde{u}^n\tilde{d}^n}\right]$
  - Upper bound: $V_0^G + \frac{(\rho^* - 1)}{r^n} \mathbb{E}^Q[G_n]$
  - Return list: `{lower_bound, upper_bound, rho_star, EQ_G, V0_G}`

### R Layer (`R/`)

**`validation.R`**:
- `validate_inputs()`: Comprehensive parameter checking
  - Positivity: $S_0, K, r, u, d, \lambda, v^u, v^d > 0$ (except $\lambda, v^u, v^d \geq 0$)
  - Ordering: $u > d$
  - No-arbitrage: $\tilde{d} < r < \tilde{u}$ (**critical**)
  - Probability: $p^{eff} \in [0,1]$ (redundant check but good to verify)
  - Warning: $n > 20$

**`geometric_asian.R`**:
- `price_geometric_asian()`: User-facing wrapper
  - Calls `validate_inputs()` if `validate=TRUE` (default)
  - Calls `price_geometric_asian_cpp()`
  - Returns numeric value

**`arithmetic_asian.R`**:
- `arithmetic_asian_bounds()`: User-facing wrapper
  - Validation → calls C++ → returns list with class `"arithmetic_bounds"`
- `print.arithmetic_bounds()`: Pretty printing method

**`price_impact_utils.R`**:
- `compute_p_eff()`: Calculate $p^{eff}$
- `compute_effective_factors()`: Return $\{\tilde{u}, \tilde{d}\}$
- `check_no_arbitrage()`: Boolean validator

## Testing Strategy

### Test Categories (`tests/testthat/`)

**Status**: ✅ 166 tests passing (0 failures, 0 warnings, 0 skips)

1. **Validation** (`test-validation.R`): 28 tests
   - Invalid inputs → errors
   - No-arbitrage violations → errors
   - Large $n$ → warnings

2. **Mathematical Properties** (`test-geometric.R`): 29 tests
   - Monotonicity: Price decreases as $K$ increases
   - Price impact: $\lambda > 0$ → higher price (for calls)
   - Boundary: $\lambda = 0$ → standard CRR model
   - Hand calculation: $n=1$ case matches manual computation

3. **Bounds** (`test-arithmetic.R`): 68 tests
   - $V_0^G \leq V_0^A \leq \text{upper bound}$
   - $\rho^* \geq 1$
   - Lower bound equals geometric price

4. **Utilities** (`test-utils.R`): 41 tests
   - $p^{eff} \in [0,1]$
   - $\tilde{u} > \tilde{d}$ when factors computed correctly

## Vignettes

### Available Vignettes (`vignettes/`)

**Status**: ✅ Both vignettes created and ready

1. **Theory Vignette** (`vignettes/theory.Rmd`):
   - Complete mathematical background
   - CRR binomial model
   - Price impact mechanism
   - Replicating portfolio method
   - Geometric and arithmetic Asian options
   - No-arbitrage constraints
   - Computational complexity
   - Working R examples integrated
   - Access: `vignette("theory", package = "AsianOptPI")`

2. **Examples Vignette** (`vignettes/examples.Rmd`):
   - 12 comprehensive examples
   - 11 visualization plots
   - Sensitivity analyses (λ, K, v, n)
   - Comparative studies (with/without impact)
   - Volatility surface
   - Moneyness analysis
   - Asymmetric hedging scenarios
   - Access: `vignette("examples", package = "AsianOptPI")`

**Content**:
- Theory: 211 lines, 4 R chunks, 20 LaTeX equations
- Examples: 321 lines, 14 R chunks, 9 plots

## Documentation Standards

### Roxygen Format

**Math notation**:
- Inline: `\eqn{\tilde{u}}`
- Display: `\deqn{p^{eff} = \frac{r - \tilde{d}}{\tilde{u} - \tilde{d}}}`
- Escape: `\%` for percent

**References** (in DESCRIPTION and function docs):
```
Cox, Ross & Rubinstein (1979) <doi:10.1016/0304-405X(79)90015-1>
```

**Examples** (use small $n$):
```r
#' @examples
#' # Basic example (n=3 for speed)
#' price_geometric_asian(
#'   S0 = 100, K = 100, r = 1.05,
#'   u = 1.2, d = 0.8,
#'   lambda = 0.1, v_u = 1, v_d = 1,
#'   n = 3
#' )
#'
#' # Larger n (slower)
#' \donttest{
#'   price_geometric_asian(..., n = 15)
#' }
```

## Key Implementation Notes

### Parameter Order Convention

Standard order for all functions:
```r
func(S0, K, r, u, d, lambda, v_u, v_d, n, validate = TRUE)
```

### Critical Validation

**Always validate** before calling C++:
1. $\tilde{d} < r < \tilde{u}$ (no-arbitrage)
2. $p^{eff} \in [0,1]$ (valid probability)
3. Warn if $n > 20$ (performance)

### Rcpp Integration

**Required in `R/AsianOptPI-package.R`**:
```r
#' @useDynLib AsianOptPI, .registration = TRUE
#' @importFrom Rcpp sourceCpp
```

**Compilation flags** (`src/Makevars`):
```makefile
CXX_STD = CXX11
PKG_CXXFLAGS = -DRCPP_USE_GLOBAL_ROSTREAM
```

## Common Pitfalls

1. **Forgetting gross rate**: $r = 1.05$ not $0.05$
2. **Path-dependence**: Cannot simplify to binomial sum—must enumerate all paths
3. **Memory pre-allocation**: Critical for performance with large $n$
4. **Long examples**: Will fail CRAN checks if > 5 seconds
5. **No-arbitrage**: Easy to create invalid parameter combinations—validation is critical

## Reference Documentation

- **Complete Development Guide**: `../PACKAGE_DEVELOPMENT_GUIDE.md` (comprehensive 8-phase guide)
- **Mathematical Theory**: `../Theory.md` (full derivations and proofs)
- **Package README**: `README.md` (user-facing documentation)
- **News**: `NEWS.md` (version history and changes)

## Package Status Summary

**Current Phase**: Phase 6 complete, Phase 7 next

**Implemented**:
- ✅ C++ core implementation (Rcpp)
  - `utils.cpp`, `utils.h`
  - `geometric_asian.cpp`
  - `arithmetic_bounds.cpp`
- ✅ R wrapper functions
  - `price_geometric_asian()`
  - `arithmetic_asian_bounds()`
  - Utility functions (compute_p_eff, check_no_arbitrage)
- ✅ Input validation (`validation.R`)
- ✅ Documentation (Roxygen2, all functions documented)
- ✅ Testing (166 tests passing)
- ✅ Vignettes (theory + examples)

**Pending**:
- ⏳ CRAN compliance checks (Phase 7)
- ⏳ Multi-platform testing
- ⏳ Final polishing
- ⏳ CRAN submission (Phase 8)

## Contact

**Maintainer**: Priyanshu Tiwari
**GitHub**: https://github.com/plato-12/AsianOptPI
**Status**: Phase 6 complete (75% ready for CRAN submission)
**Next Steps**: Run devtools::check() for CRAN compliance
