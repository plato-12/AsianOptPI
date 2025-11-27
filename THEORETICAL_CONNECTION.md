# Theoretical Connection: Kemma-Vorst vs Price Impact (λ=0)

**Date:** 2025-11-22
**Purpose:** Derive the mathematical relationship connecting the two implementations

---

## The Two Models

### 1. Kemma-Vorst (Continuous-Time Analytical)

**Stock Price Dynamics:**
$$dS_t = \mu S_t dt + \sigma S_t dW_t$$

where:
- $\mu$ = drift (continuously compounded)
- $\sigma$ = volatility
- $W_t$ = Brownian motion

**Geometric Average (Continuous):**
$$G_T = \exp\left[\frac{1}{T} \int_0^T \log S_t \, dt\right]$$

**Key Property:** Under risk-neutral measure ($\mu = r$):
$$\log G_T \sim N\left(\log S_0 + \frac{1}{2}\left(r - \frac{\sigma^2}{2}\right)T, \frac{\sigma^2 T}{3}\right)$$

**Closed-Form Price:**
$$C = S_0 e^{d^*} N(d) - K N(d - \sigma_G\sqrt{T})$$

where:
- $\sigma_G = \sigma/\sqrt{3}$ (reduced volatility)
- $d^* = \frac{1}{2}\left(r - \frac{\sigma^2}{6}\right)T$
- $d = \frac{\log(S_0/K) + \frac{1}{2}(r + \frac{\sigma^2}{6})T}{\sigma\sqrt{T/3}}$

---

### 2. Price Impact Model with λ=0 (Discrete Binomial)

**Stock Price Dynamics:**
At each time step $\Delta t$:
$$S_{i+1} = \begin{cases} u S_i & \text{with probability } p \\ d S_i & \text{with probability } 1-p \end{cases}$$

where (when λ=0):
- $u$ = up factor
- $d$ = down factor
- $p = \frac{r - d}{u - d}$ (risk-neutral probability)
- $r$ = gross risk-free rate per period

**Geometric Average (Discrete):**
$$G_n = \left(\prod_{i=0}^{n} S_i\right)^{1/(n+1)} = S_0 \left(u^{N_u} d^{N_d}\right)^{1/(n+1)}$$

where $N_u$ + $N_d$ = cumulative sum of up/down moves across all times.

**Price (Path Enumeration):**
$$V_0 = \frac{1}{r^n} \sum_{\omega \in \{U,D\}^n} p^{\#U(\omega)} (1-p)^{n-\#U(\omega)} \max[0, G(\omega) - K]$$

---

## The Connection: CRR Convergence Theorem

### Standard CRR Matching (Cox-Ross-Rubinstein, 1979)

For the binomial tree to approximate continuous GBM as $n \to \infty$:

**Time Step:**
$$\Delta t = \frac{T}{n}$$

**Binomial Parameters:**
$$u = e^{\sigma\sqrt{\Delta t}}$$
$$d = e^{-\sigma\sqrt{\Delta t}} = \frac{1}{u}$$

**Risk-Neutral Drift:**
Under risk-neutral measure, stock has expected return = risk-free rate:
$$r_{continuous} = \log(r_{gross}) \quad \text{per period}$$

**Risk-Neutral Probability:**
$$p = \frac{e^{r_{continuous} \Delta t} - d}{u - d}$$

Substituting:
$$p = \frac{e^{r \Delta t} - e^{-\sigma\sqrt{\Delta t}}}{e^{\sigma\sqrt{\Delta t}} - e^{-\sigma\sqrt{\Delta t}}}$$

**Taylor Expansion** (for small $\Delta t$):
$$p \approx \frac{1}{2} + \frac{r - \sigma^2/2}{2\sigma}\sqrt{\Delta t}$$

---

## Key Issue: Discrete vs Continuous Geometric Average

### The Discrete Geometric Average is Path-Dependent

For a specific path $\omega = (m_0, m_1, ..., m_n)$ where $m_i \in \{U, D\}$:

$$G(\omega) = S_0 \left(\prod_{i=0}^{n} u^{a_i} d^{i - a_i}\right)^{1/(n+1)}$$

where $a_i$ = number of ups by time $i$.

**Critical Observation:**
$$\log G(\omega) = \log S_0 + \frac{1}{n+1} \sum_{i=0}^{n} \left[a_i \log u + (i - a_i) \log d\right]$$

This is **NOT** simply proportional to the number of ups in the path!

The sum $\sum_{i=0}^{n} a_i$ depends on **when** the ups occur, not just **how many**.

**Example (n=2):**
- Path UU: $a_0=0, a_1=1, a_2=2 \Rightarrow \sum a_i = 3$
- Path DU: $a_0=0, a_1=0, a_2=1 \Rightarrow \sum a_i = 1$

Both have 1 up move, but different geometric averages!

---

## Convergence Analysis

### Limiting Distribution of Discrete Geometric Average

As $n \to \infty$, the discrete observations approach continuous averaging:

$$\frac{1}{n+1}\sum_{i=0}^{n} \log S_i \to \frac{1}{T}\int_0^T \log S_t \, dt$$

**Riemann Sum Approximation:**

Let $t_i = i \Delta t$ for $i = 0, 1, ..., n$ where $\Delta t = T/n$.

The discrete geometric average:
$$\log G_n = \frac{1}{n+1} \sum_{i=0}^{n} \log S(t_i)$$

is a Riemann sum approximating:
$$\log G_T = \frac{1}{T} \int_0^T \log S_t \, dt$$

**Convergence Rate:**
$$|\log G_n - \log G_T| = O(1/n)$$

under regularity conditions on the stock price path.

---

## Why The Implementations Don't Match Exactly

### 1. **Different Averaging Schemes**

**Kemma-Vorst:**
- Assumes **continuous** averaging: $\frac{1}{T}\int_0^T \log S_t \, dt$
- This is the limit of infinitely many observations

**Price Impact (λ=0):**
- Uses **discrete** averaging: $\frac{1}{n+1}\sum_{i=0}^{n} \log S_i$
- Exactly $n+1$ observations at times $0, \Delta t, 2\Delta t, ..., n\Delta t$

### 2. **Discrete vs Continuous Compounding**

**Kemma-Vorst formula** assumes continuously compounded rate $r_{cont}$.

**Binomial tree** uses gross rate $r_{gross}$ per period.

**Relationship:**
$$r_{cont} = \log(r_{gross})$$

But this is the rate **per period**, not per unit time!

**Correct conversion:**
$$r_{continuous \, per \, unit \, time} = \frac{\log(r_{gross})}{T/n} = \frac{n \log(r_{gross})}{T}$$

For $T=1$ (total time = 1 year):
$$r_{cont} = n \log(r_{gross})$$

This grows with $n$, which is **wrong**!

### 3. **The Correct CRR Parameterization**

The issue is in how the **gross rate per period** relates to the **annual rate**.

**If $r_{annual}$ is the continuously compounded annual rate:**
$$r_{gross \, per \, period} = e^{r_{annual} \cdot (T/n)} = e^{r_{annual} \Delta t}$$

**Equivalently:**
$$r_{annual} = \frac{\log(r_{gross})}{\Delta t} = \frac{n \log(r_{gross})}{T}$$

**For the current implementation with $r_{gross} = 1.05$ and $T=1$:**
$$r_{annual} = n \log(1.05) = n \times 0.04879...$$

As $n$ increases, this effective annual rate **increases**, which explains why the binomial prices don't match Kemma-Vorst!

---

## The Fix: Proper Parameter Conversion

### Option A: Fix Gross Rate for Given n

If we want the binomial tree with $n$ steps to match annual rate $r_{annual}$:

$$r_{gross} = e^{r_{annual}/n}$$

**Example:** $r_{annual} = 0.05$ (5% continuously compounded), $n=10$:
$$r_{gross} = e^{0.05/10} = e^{0.005} = 1.005012...$$

**NOT** $r_{gross} = 1.05$!

The $r_{gross} = 1.05$ implies $r_{annual} \approx n \times 0.04879$, which is huge for large $n$.

### Option B: Kemma-Vorst Uses Per-Period Rate

The `price_kemma_vorst_geometric_binomial` function does:
```r
r_continuous <- log(r_gross)  # This is per-period rate
sigma <- log(u/d) / (2 * sqrt(dt))
T <- 1  # Total time in periods
```

This treats $r_{gross} = 1.05$ as **5% per total period**, not per step!

So the annual rate is:
$$r_{annual} = \log(1.05) = 0.04879$$

And each step has:
$$r_{step} = \frac{r_{annual}}{n} = \frac{0.04879}{n}$$

The binomial tree should use:
$$r_{gross \, per \, step} = e^{r_{annual}/n} = e^{0.04879/n}$$

---

## Exact Matching Condition

For **exact convergence** as $n \to \infty$:

**Given:**
- Annual continuously compounded rate: $r_{annual}$
- Annual volatility: $\sigma_{annual}$
- Total time: $T$ years
- Number of steps: $n$

**Binomial Parameters:**
$$\Delta t = \frac{T}{n}$$
$$u = e^{\sigma_{annual}\sqrt{\Delta t}}$$
$$d = e^{-\sigma_{annual}\sqrt{\Delta t}}$$
$$r_{gross \, per \, step} = e^{r_{annual} \Delta t}$$

**Risk-Neutral Probability:**
$$p = \frac{r_{gross} - d}{u - d}$$

**Then as $n \to \infty$:**
$$\text{Binomial Price}_{n \to \infty} \to \text{Kemma-Vorst Price}$$

---

## Current Implementation Mismatch

### In `price_kemma_vorst_geometric_binomial`:

```r
r_continuous <- log(r)        # Treats r as gross rate for ENTIRE period
sigma <- log(u/d)/(2*sqrt(dt))
T <- 1
```

This interprets:
- $r = 1.05$ means 5% over the **entire** period (all $n$ steps combined)
- Each step has rate: $r_{step} = r^{1/n} = 1.05^{1/n}$

### In `price_geometric_asian` (binomial tree):

```r
# Uses r directly as gross rate PER STEP
p = (r - d) / (u - d)
```

This interprets:
- $r = 1.05$ means 5% **per step**
- Over $n$ steps: total gross return = $r^n = 1.05^n$

**These are inconsistent!**

---

## Resolution

### Two Valid Interpretations:

**Interpretation 1: r is gross rate per step**
- Binomial: Use $r$ directly per step
- Kemma-Vorst: Use annual rate $r_{annual} = n \log(r)$, time $T = n$ (in step units)
- **Problem:** Annual rate grows with $n$ (unphysical)

**Interpretation 2: r is gross rate for total period** (CORRECT)
- Binomial: Use $r_{step} = r^{1/n}$ per step
- Kemma-Vorst: Use annual rate $r_{annual} = \log(r)$, time $T = 1$
- **This matches as $n \to \infty$**

---

## Theoretical Result

### Convergence Theorem

**Given:**
- Total time: $T = 1$ (in some units, e.g., years)
- Gross rate over total period: $R$ (e.g., $R = 1.05$ for 5%)
- Up/down factors: $u, d$ with $\sigma = \frac{\log(u/d)}{2\sqrt{T/n}}$

**Binomial Model** with:
- Steps: $n$
- Rate per step: $r_{step} = R^{1/n}$
- Prob per step: $p_n = \frac{r_{step} - d}{u - d}$

**Kemma-Vorst Model** with:
- Continuous rate: $r_{cont} = \log(R)/T = \log(R)$ (for $T=1$)
- Volatility: $\sigma$ (same as binomial)

**Then:**
$$\lim_{n \to \infty} \text{Price}_{\text{binomial}}(n) = \text{Price}_{\text{Kemma-Vorst}}$$

---

## Practical Implications

### For Comparison:

**If you want to compare models at fixed $n$:**

The difference is:
1. **Continuous averaging** (Kemma-Vorst) vs **discrete averaging** (binomial)
2. The error is $O(1/n)$

**Typical differences for $n=10$:**
- Continuous integral overestimates discrete sum slightly
- For ATM options: ~5-10% difference
- For deep OTM/ITM: larger relative differences

**As $n \to \infty$:** Difference → 0

### Current Results Explained:

Your benchmark showed ~20-30% differences between models. This is due to:
1. **Different rate interpretation** (major factor)
2. **Discrete vs continuous averaging** (minor factor for n=10)

**If we fix the rate interpretation:**
- Binomial should use $r_{step} = 1.05^{1/n}$ not $1.05$
- Then difference would be ~5% (due to discrete averaging)
- As $n$ increases → 0

---

## Recommendation

### For Proper Comparison:

**Modify the binomial tree to use:**
```r
r_per_step <- r_gross^(1/n)
```

instead of using `r_gross` directly per step.

**Then:**
- Both models use same total period rate
- Difference is only due to discrete vs continuous averaging
- Convergence as $n \to \infty$ is guaranteed

### Alternative: Different Benchmark Focus

Instead of forcing equivalence, benchmark should emphasize:

1. **Price Impact Analysis:**
   - Compare λ=0 vs λ>0 (within same model)
   - Quantify hedging cost

2. **Model Comparison:**
   - Acknowledge they're different models
   - Kemma-Vorst: Fast analytical approximation
   - Binomial: Exact for discrete averaging

3. **Convergence Study:**
   - Show binomial → Kemma-Vorst as n → ∞
   - Plot error vs n

---

## Mathematical Summary

### The Connection Formula:

$$\boxed{\lim_{n \to \infty} \frac{1}{r_{step}^n} \mathbb{E}^{p_n}\left[\max(G_n - K, 0)\right] = S_0 e^{d^*} N(d) - K N(d - \sigma_G)}$$

where:
- Left side: Binomial with $r_{step} = R^{1/n}$, $p_n = \frac{r_{step} - d_n}{u_n - d_n}$
- Right side: Kemma-Vorst with $r_{cont} = \log(R)$
- $u_n = e^{\sigma/\sqrt{n}}$, $d_n = e^{-\sigma/\sqrt{n}}$

**This is the fundamental convergence result.**

---

## References

1. **Cox, J.C., Ross, S.A., and Rubinstein, M. (1979).** "Option Pricing: A Simplified Approach." *Journal of Financial Economics*, 7(3), 229-263.
   - Original CRR convergence theorem

2. **Kemna, A.G.Z. and Vorst, A.C.F. (1990).** "A Pricing Method for Options Based on Average Asset Values." *Journal of Banking and Finance*, 14, 113-129.
   - Analytical formula for continuous geometric average

3. **Shreve, S.E. (2004).** *Stochastic Calculus for Finance II: Continuous-Time Models*. Springer.
   - Chapter on binomial-to-continuous convergence

---

**Date:** 2025-11-22
**Status:** Theoretical derivation complete
**Key Insight:** Models use different rate conventions - need to harmonize for proper comparison
