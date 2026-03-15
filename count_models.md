# Count Model Comparison for NAG Variables (nags_support_count, nags_training, etc.)
**Context:** Data has extreme zero-inflation (~99.5% zeros, mean ≈ 0.0037). 

Committee member recommends Quasi-Poisson (based on Wooldridge). 

Previously used Negative Binomial.

`fepoisson` (fixest) was suggested. 

Below is a direct pros/cons comparison tailored to dyad-year panel, clustered SE needs, and one-model-at-a-time rule.

### Quick Comparison Table

| Aspect                  | **fepoisson (fixest)**                              | **Quasi-Poisson**                                   | **Negative Binomial (NB)**                          |
|-------------------------|-----------------------------------------------------|-----------------------------------------------------|-----------------------------------------------------|
| **Assumption**          | Mean = Variance (equidispersion)                    | Mean free; variance = φ × mean (overdispersion OK) | Mean free; extra dispersion parameter (γ)           |
| **Speed with FE**       | Extremely fast (high-dim FE)                        | Fast (glm or fixest)                                | Slower than Poisson (but fixest `fenegbin` is OK)   |
| **Likelihood**          | Yes (but assumes equidispersion)                    | No (quasi-likelihood)                               | Full likelihood (best for AIC/BIC)                  |
| **Overdispersion**      | Biased SEs unless you use robust/clustered SE       | Handles automatically (dispersion φ)                | Handles automatically (NB2 or NB1)                  |
| **Zero-Inflation**      | Poor (massive zeros → biased)                       | Poor (same as Poisson)                              | Better than Poisson, but still poor with 99.5% zeros|
| **Clustered SE**        | Built-in (`cluster=~dyad`)                          | Easy (`sandwich` or fixest)                         | Easy (`sandwich` or fixest)                         |
| **Fixest support**      | Native `fepoisson()`                                | Yes via `feglm(..., family=quasipoisson)`           | Native `fenegbin()`                                 |
| **When to use**         | Quick baseline when no overdispersion               | Committee recommendation; overdispersion present    | Your previous choice; want full likelihood          |
| **Downsides**           | Fails badly with overdispersion/zeros               | No AIC/BIC; not true ML                             | Slower; still needs hurdle/ZINB for extreme zeros   |

### Recommended Workflow (add to every count-model script)
1. **Test overdispersion** (after running Poisson):
   ```r
   library(AER)
   dispersiontest(poisson_model)   # H0: φ=1; p<0.05 → overdispersed
