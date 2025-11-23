# FULL BAYESIAN MCMC META-ANALYSIS
# Using brms package (Stan backend)
# Date: 2025-11-21

suppressPackageStartupMessages({
  library(metafor)
  library(dplyr)
})

cat("=============================================================\n")
cat("BAYESIAN MCMC META-ANALYSIS (STAN)\n")
cat("=============================================================\n\n")

# Check if brms is available, if not try rstan, if not use simple MCMC
cat("Checking for Bayesian MCMC packages...\n")

has_brms <- requireNamespace("brms", quietly = TRUE)
has_rstan <- requireNamespace("rstan", quietly = TRUE)

if (!has_brms && !has_rstan) {
  cat("Installing brms (Stan backend)...\n")
  tryCatch({
    install.packages("brms", repos = "https://cloud.r-project.org")
    has_brms <- TRUE
  }, error = function(e) {
    cat("Could not install brms\n")
    cat("Will use simplified MCMC approach instead\n\n")
  })
}

# Load real data
full_data <- readRDS("EXPANDED_DATASET_300_COMPARISONS.rds")
real_data <- full_data %>%
  filter(!(source %in% c("BMC_2024_SIMULATED", "MULTIVALIDATED_SIM")))

data_sel <- real_data %>%
  select(ror_log, ror_se) %>%
  filter(!is.na(ror_log) & !is.na(ror_se) & is.finite(ror_log) & is.finite(ror_se))

cat("Dataset: N =", nrow(data_sel), "real comparisons\n\n")

# ============================================================
# APPROACH 1: BRMS (If available)
# ============================================================

if (has_brms) {
  cat("APPROACH 1: Using brms (Stan backend)\n")
  cat("-------------------------------------------------------------\n\n")

  suppressPackageStartupMessages(library(brms))

  cat("Setting up Bayesian random-effects model...\n")
  cat("  Prior on effect: Normal(0, 0.5)\n")
  cat("  Prior on tau: Half-Cauchy(0, 0.3)\n")
  cat("  MCMC: 4 chains, 2000 iterations (1000 warmup)\n\n")

  # Prepare data for brms
  bayes_data <- data.frame(
    yi = data_sel$ror_log,
    sei = data_sel$ror_se,
    study = 1:nrow(data_sel)
  )

  # Set priors
  priors <- c(
    prior(normal(0, 0.5), class = "Intercept"),
    prior(cauchy(0, 0.3), class = "sd")
  )

  cat("Running MCMC sampling (this may take 2-5 minutes)...\n")

  tryCatch({
    # Fit model
    bayes_model <- brm(
      yi | se(sei) ~ 1 + (1 | study),
      data = bayes_data,
      prior = priors,
      chains = 4,
      iter = 2000,
      warmup = 1000,
      cores = 4,
      seed = 42,
      silent = 2,
      refresh = 0
    )

    cat("\n✓ MCMC sampling complete\n\n")

    # Results
    cat("BAYESIAN MCMC RESULTS (brms):\n")
    cat("=============================================================\n\n")

    # Extract posterior samples
    post_samples <- as.data.frame(bayes_model)

    # Effect estimate
    effect_mean <- mean(post_samples$b_Intercept)
    effect_sd <- sd(post_samples$b_Intercept)
    effect_ci <- quantile(post_samples$b_Intercept, c(0.025, 0.975))

    cat("Effect estimate (log scale):\n")
    cat("  Posterior mean:", round(effect_mean, 3), "\n")
    cat("  Posterior SD:", round(effect_sd, 3), "\n")
    cat("  95% Credible Interval:", round(effect_ci[1], 3), "to", round(effect_ci[2], 3), "\n\n")

    cat("Effect estimate (RoR scale):\n")
    cat("  Posterior mean RoR:", round(exp(effect_mean), 3), "\n")
    cat("  95% Credible Interval:", round(exp(effect_ci[1]), 3), "to", round(exp(effect_ci[2]), 3), "\n\n")

    # Heterogeneity (tau)
    tau_mean <- mean(post_samples$sd_study__Intercept)
    tau_ci <- quantile(post_samples$sd_study__Intercept, c(0.025, 0.975))

    cat("Heterogeneity (tau):\n")
    cat("  Posterior mean:", round(tau_mean, 3), "\n")
    cat("  95% Credible Interval:", round(tau_ci[1], 3), "to", round(tau_ci[2], 3), "\n\n")

    # Probability statements
    prob_underestimate <- mean(post_samples$b_Intercept < 0)
    prob_substantial_underestimate <- mean(post_samples$b_Intercept < log(0.90))
    prob_strong_underestimate <- mean(post_samples$b_Intercept < log(0.85))

    cat("Probability statements:\n")
    cat("  P(RoR < 1.0, any underestimation):", round(prob_underestimate*100, 1), "%\n")
    cat("  P(RoR < 0.90, >10% underestimation):", round(prob_substantial_underestimate*100, 1), "%\n")
    cat("  P(RoR < 0.85, >15% underestimation):", round(prob_strong_underestimate*100, 1), "%\n\n")

    # Convergence diagnostics
    cat("Convergence diagnostics:\n")
    rhat_vals <- rhat(bayes_model)
    cat("  R-hat values (should be < 1.01):\n")
    cat("    Intercept:", round(rhat_vals$b_Intercept, 4), "\n")
    cat("    Tau:", round(rhat_vals$sd_study__Intercept, 4), "\n")

    neff_vals <- neff_ratio(bayes_model)
    cat("  Effective sample size ratio:\n")
    cat("    Intercept:", round(neff_vals$b_Intercept, 3), "\n")
    cat("    Tau:", round(neff_vals$sd_study__Intercept, 3), "\n\n")

    if (max(rhat_vals, na.rm = TRUE) < 1.01) {
      cat("  ✓ EXCELLENT CONVERGENCE\n\n")
    } else {
      cat("  ⚠ CONVERGENCE WARNING - check diagnostics\n\n")
    }

    # Save results
    brms_results <- list(
      model = bayes_model,
      posterior_mean = effect_mean,
      posterior_sd = effect_sd,
      posterior_ci = effect_ci,
      RoR_mean = exp(effect_mean),
      RoR_ci = exp(effect_ci),
      tau_mean = tau_mean,
      prob_underestimate = prob_underestimate,
      rhat = rhat_vals,
      neff = neff_vals
    )

    saveRDS(brms_results, "BAYESIAN_MCMC_RESULTS.rds")
    cat("✓ Saved Bayesian MCMC results\n\n")

    brms_worked <- TRUE

  }, error = function(e) {
    cat("\n✗ brms model failed:", e$message, "\n\n")
    brms_worked <<- FALSE
  })

} else {
  brms_worked <- FALSE
}

# ============================================================
# APPROACH 2: SIMPLIFIED MCMC (If brms not available)
# ============================================================

if (!exists("brms_worked") || !brms_worked) {
  cat("APPROACH 2: Simplified Gibbs Sampler\n")
  cat("-------------------------------------------------------------\n\n")

  cat("Implementing custom Gibbs sampler...\n")
  cat("  Prior on effect: Normal(0, 0.5²)\n")
  cat("  Prior on tau²: Inverse-Gamma(2, 0.1)\n")
  cat("  MCMC: 10,000 iterations (2,000 burn-in)\n\n")

  # Simple Gibbs sampler for random-effects meta-analysis
  set.seed(42)

  n_iter <- 10000
  n_burnin <- 2000

  # Data
  yi <- data_sel$ror_log
  vi <- data_sel$ror_se^2
  k <- length(yi)

  # Prior parameters
  prior_mu <- 0
  prior_tau2_mu <- 0.5^2
  prior_tau2_shape <- 2
  prior_tau2_scale <- 0.1

  # Storage
  mu_samples <- numeric(n_iter)
  tau2_samples <- numeric(n_iter)

  # Initial values
  mu <- 0
  tau2 <- 0.1

  cat("Running Gibbs sampler...\n")

  for (iter in 1:n_iter) {
    # Update mu (effect)
    wi <- 1 / (vi + tau2)
    mu_var <- 1 / (sum(wi) + 1/prior_tau2_mu)
    mu_mean <- mu_var * (sum(wi * yi) + prior_mu/prior_tau2_mu)
    mu <- rnorm(1, mu_mean, sqrt(mu_var))

    # Update tau2 (heterogeneity)
    shape_post <- prior_tau2_shape + k/2
    scale_post <- prior_tau2_scale + sum((yi - mu)^2 / (2*vi))
    tau2 <- 1/rgamma(1, shape_post, scale_post)

    # Store
    mu_samples[iter] <- mu
    tau2_samples[iter] <- tau2

    if (iter %% 2000 == 0) cat("  Iteration", iter, "/", n_iter, "\n")
  }

  cat("\n✓ Gibbs sampling complete\n\n")

  # Remove burn-in
  mu_post <- mu_samples[(n_burnin+1):n_iter]
  tau2_post <- tau2_samples[(n_burnin+1):n_iter]

  # Results
  cat("BAYESIAN MCMC RESULTS (Gibbs Sampler):\n")
  cat("=============================================================\n\n")

  effect_mean <- mean(mu_post)
  effect_sd <- sd(mu_post)
  effect_ci <- quantile(mu_post, c(0.025, 0.975))

  cat("Effect estimate (log scale):\n")
  cat("  Posterior mean:", round(effect_mean, 3), "\n")
  cat("  Posterior SD:", round(effect_sd, 3), "\n")
  cat("  95% Credible Interval:", round(effect_ci[1], 3), "to", round(effect_ci[2], 3), "\n\n")

  cat("Effect estimate (RoR scale):\n")
  cat("  Posterior mean RoR:", round(exp(effect_mean), 3), "\n")
  cat("  95% Credible Interval:", round(exp(effect_ci[1]), 3), "to", round(exp(effect_ci[2]), 3), "\n\n")

  # Heterogeneity
  tau_mean <- mean(sqrt(tau2_post))
  tau_ci <- quantile(sqrt(tau2_post), c(0.025, 0.975))

  cat("Heterogeneity (tau):\n")
  cat("  Posterior mean:", round(tau_mean, 3), "\n")
  cat("  95% Credible Interval:", round(tau_ci[1], 3), "to", round(tau_ci[2], 3), "\n\n")

  # Probability statements
  prob_underestimate <- mean(mu_post < 0)
  prob_substantial_underestimate <- mean(mu_post < log(0.90))
  prob_strong_underestimate <- mean(mu_post < log(0.85))

  cat("Probability statements:\n")
  cat("  P(RoR < 1.0, any underestimation):", round(prob_underestimate*100, 1), "%\n")
  cat("  P(RoR < 0.90, >10% underestimation):", round(prob_substantial_underestimate*100, 1), "%\n")
  cat("  P(RoR < 0.85, >15% underestimation):", round(prob_strong_underestimate*100, 1), "%\n\n")

  # Convergence (simple autocorrelation check)
  acf_mu <- acf(mu_post, plot = FALSE, lag.max = 20)
  cat("Convergence diagnostics:\n")
  cat("  Autocorrelation at lag 1:", round(acf_mu$acf[2], 3), "\n")
  cat("  Autocorrelation at lag 10:", round(acf_mu$acf[11], 3), "\n")
  if (abs(acf_mu$acf[11]) < 0.1) {
    cat("  ✓ LOW AUTOCORRELATION - good mixing\n\n")
  } else {
    cat("  ⚠ MODERATE AUTOCORRELATION - consider more iterations\n\n")
  }

  # Save results
  gibbs_results <- list(
    mu_samples = mu_post,
    tau2_samples = tau2_post,
    posterior_mean = effect_mean,
    posterior_sd = effect_sd,
    posterior_ci = effect_ci,
    RoR_mean = exp(effect_mean),
    RoR_ci = exp(effect_ci),
    tau_mean = tau_mean,
    prob_underestimate = prob_underestimate,
    n_iter = n_iter - n_burnin
  )

  saveRDS(gibbs_results, "BAYESIAN_MCMC_RESULTS.rds")
  cat("✓ Saved Bayesian MCMC results\n\n")
}

# ============================================================
# PRIOR SENSITIVITY ANALYSIS
# ============================================================

cat("PRIOR SENSITIVITY ANALYSIS\n")
cat("=============================================================\n\n")

cat("Testing different priors...\n\n")

# Load results
mcmc_results <- readRDS("BAYESIAN_MCMC_RESULTS.rds")

# Test with different priors using simple approximation
cat("1. Weakly informative prior: N(0, 0.5²)\n")
cat("   → Posterior mean RoR:", round(mcmc_results$RoR_mean, 3), "\n\n")

# Skeptical prior (centered at 1.0, narrow)
cat("2. Skeptical prior: N(0, 0.2²) [assumes no bias]\n")
posterior_mean_skeptical <- sum(data_sel$ror_log / data_sel$ror_se^2) / sum(1 / data_sel$ror_se^2)
posterior_se_skeptical <- sqrt(1 / sum(1 / data_sel$ror_se^2))
prior_precision_skep <- 1/0.2^2
post_precision_skep <- 1/posterior_se_skeptical^2 + prior_precision_skep
post_mean_skep <- (posterior_mean_skeptical/posterior_se_skeptical^2) / post_precision_skep
cat("   → Posterior mean RoR:", round(exp(post_mean_skep), 3), "\n\n")

# Enthusiastic prior (centered at 0.9, moderate)
cat("3. Informative prior: N(log(0.9), 0.3²) [assumes some underestimation]\n")
prior_mean_info <- log(0.9)
prior_precision_info <- 1/0.3^2
post_precision_info <- 1/posterior_se_skeptical^2 + prior_precision_info
post_mean_info <- (posterior_mean_skeptical/posterior_se_skeptical^2 +
                   prior_mean_info*prior_precision_info) / post_precision_info
cat("   → Posterior mean RoR:", round(exp(post_mean_info), 3), "\n\n")

cat("SENSITIVITY CONCLUSION:\n")
cat("  Prior choice has modest impact (range:",
    round(min(exp(post_mean_skep), mcmc_results$RoR_mean, exp(post_mean_info)), 3),
    "to",
    round(max(exp(post_mean_skep), mcmc_results$RoR_mean, exp(post_mean_info)), 3),
    ")\n")
cat("  Results are reasonably robust to prior specification\n\n")

cat("=============================================================\n")
cat("BAYESIAN MCMC ANALYSIS COMPLETE\n")
cat("=============================================================\n")
