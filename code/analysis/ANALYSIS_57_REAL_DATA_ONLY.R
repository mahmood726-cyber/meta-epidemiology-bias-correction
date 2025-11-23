# ANALYSIS OF 57 REAL COMPARISONS ONLY
# Excluding all simulated data to assess robustness
# Date: 2025-11-21

suppressPackageStartupMessages({
  library(metafor)
  library(dplyr)
})

cat("=============================================================\n")
cat("ANALYSIS OF 57 REAL COMPARISONS ONLY\n")
cat("=============================================================\n\n")

# Load full dataset
full_data <- readRDS("EXPANDED_DATASET_300_COMPARISONS.rds")

# Filter for REAL data only (exclude all simulated)
real_data <- full_data %>%
  filter(!(source %in% c("BMC_2024_SIMULATED", "MULTIVALIDATED_SIM")))

cat("Dataset filtering:\n")
cat("  Total in full dataset:", nrow(full_data), "\n")
cat("  Real data only:", nrow(real_data), "\n")
cat("  Excluded (simulated):", nrow(full_data) - nrow(real_data), "\n\n")

cat("Real data sources:\n")
print(table(real_data$source))
cat("\n")

# Prepare data
data_sel <- real_data %>%
  select(ror_log, ror_se) %>%
  filter(!is.na(ror_log) & !is.na(ror_se) & is.finite(ror_log) & is.finite(ror_se))

cat("Clean real data: n =", nrow(data_sel), "\n\n")

cat("Descriptive statistics:\n")
cat("  Mean log RoR:", round(mean(data_sel$ror_log), 3), "\n")
cat("  SD log RoR:", round(sd(data_sel$ror_log), 3), "\n")
cat("  Mean SE:", round(mean(data_sel$ror_se), 3), "\n")
cat("  Concordant:", sum(real_data$concordant), "(",
    round(mean(real_data$concordant)*100, 1), "%)\n\n")

# ============================================================
# PART 1: STANDARD RANDOM-EFFECTS
# ============================================================

cat("PART 1: Standard Random-Effects Meta-Analysis\n")
cat("=============================================================\n\n")

ma_standard <- rma(yi = ror_log, sei = ror_se, method = "REML", data = data_sel)

cat("Standard RE results:\n")
cat("  Pooled RoR:", round(exp(coef(ma_standard)), 3), "\n")
cat("  95% CI:", round(exp(ma_standard$ci.lb), 3), "to",
    round(exp(ma_standard$ci.ub), 3), "\n")
cat("  P-value:", format.pval(ma_standard$pval, digits = 4), "\n")
cat("  I²:", round(ma_standard$I2, 1), "%\n")
cat("  Tau²:", round(ma_standard$tau2, 4), "\n\n")

# Prediction interval
pred <- predict(ma_standard)
cat("Prediction interval (95%):\n")
cat("  ", round(exp(pred$pi.lb), 2), "to", round(exp(pred$pi.ub), 2), "\n\n")

if (ma_standard$pval < 0.05) {
  if (exp(coef(ma_standard)) < 1.0) {
    cat("** SIGNIFICANT UNDERESTIMATION by observational studies **\n\n")
  } else {
    cat("** SIGNIFICANT OVERESTIMATION by observational studies **\n\n")
  }
} else {
  cat("No significant overall bias (p > 0.05)\n\n")
}

# ============================================================
# PART 2: HARTUNG-KNAPP
# ============================================================

cat("PART 2: Hartung-Knapp Robust Variance\n")
cat("=============================================================\n\n")

ma_hk <- rma(yi = ror_log, sei = ror_se, method = "REML",
             test = "knha", data = data_sel)

cat("Hartung-Knapp results:\n")
cat("  Pooled RoR:", round(exp(coef(ma_hk)), 3), "\n")
cat("  95% CI:", round(exp(ma_hk$ci.lb), 3), "to",
    round(exp(ma_hk$ci.ub), 3), "\n")
cat("  P-value:", format.pval(ma_hk$pval, digits = 4), "\n")
cat("  t-statistic:", round(ma_hk$zval, 3), "(df =", ma_hk$dfs, ")\n\n")

# ============================================================
# PART 3: PUBLICATION BIAS ASSESSMENT
# ============================================================

cat("PART 3: Publication Bias Assessment\n")
cat("=============================================================\n\n")

# Egger's test / PET
pet_model <- rma(yi = ror_log, sei = ror_se, mods = ~ ror_se, method = "FE", data = data_sel)

cat("PET (Precision-Effect Test):\n")
cat("  Bias-adjusted RoR:", round(exp(coef(pet_model)[1]), 3), "\n")
cat("  P-value:", format.pval(pet_model$pval[1], digits = 4), "\n\n")

cat("Egger's test for small-study effects:\n")
cat("  Test statistic:", round(pet_model$zval[2], 3), "\n")
cat("  P-value:", format.pval(pet_model$pval[2], digits = 4), "\n")

if (pet_model$pval[2] < 0.10) {
  cat("  ** Evidence of publication bias **\n\n")

  # PEESE
  data_sel$ror_var <- data_sel$ror_se^2
  peese_model <- rma(yi = ror_log, sei = ror_se, mods = ~ ror_var, method = "FE", data = data_sel)

  cat("PEESE (recommended when bias detected):\n")
  cat("  Bias-adjusted RoR:", round(exp(coef(peese_model)[1]), 3), "\n")
  cat("  P-value:", format.pval(peese_model$pval[1], digits = 4), "\n\n")
} else {
  cat("  No strong evidence of publication bias\n\n")
  peese_model <- NULL
}

# ============================================================
# PART 4: LIMIT META-ANALYSIS
# ============================================================

cat("PART 4: Limit Meta-Analysis\n")
cat("=============================================================\n\n")

data_sel$inv_var <- 1 / data_sel$ror_se^2
lim_model <- lm(ror_log ~ ror_se, data = data_sel, weights = inv_var)

cat("Limit meta-analysis (extrapolation to SE=0):\n")
cat("  Intercept (RoR at infinite precision):", round(exp(coef(lim_model)[1]), 3), "\n")
cat("  95% CI:", round(exp(confint(lim_model)[1,]), 3), "\n")
cat("  Slope (small-study effect):", round(coef(lim_model)[2], 3), "\n")
cat("  P-value (slope):", format.pval(summary(lim_model)$coefficients[2,4], digits = 4), "\n\n")

# ============================================================
# PART 5: SIMPLIFIED BAYESIAN
# ============================================================

cat("PART 5: Bayesian Random-Effects (Conjugate Approximation)\n")
cat("=============================================================\n\n")

set.seed(42)

# Weighted mean as posterior mean approximation
posterior_mean <- sum(data_sel$ror_log / data_sel$ror_se^2) /
                  sum(1 / data_sel$ror_se^2)
posterior_se <- sqrt(1 / sum(1 / data_sel$ror_se^2))

# Prior: mean=0, sd=0.5 (weakly informative)
prior_mean <- 0
prior_sd <- 0.5

# Posterior combining data and prior
post_precision <- 1/posterior_se^2 + 1/prior_sd^2
post_mean_bayes <- (posterior_mean/posterior_se^2 + prior_mean/prior_sd^2) / post_precision
post_se_bayes <- sqrt(1/post_precision)

cat("Bayesian posterior:\n")
cat("  Posterior mean (log):", round(post_mean_bayes, 3), "\n")
cat("  Posterior RoR:", round(exp(post_mean_bayes), 3), "\n")
cat("  95% Credible Interval:",
    round(exp(post_mean_bayes - 1.96*post_se_bayes), 3), "to",
    round(exp(post_mean_bayes + 1.96*post_se_bayes), 3), "\n\n")

prob_underestimate <- pnorm(0, mean = post_mean_bayes, sd = post_se_bayes,
                             lower.tail = TRUE)
cat("  P(observational underestimate):", round(prob_underestimate*100, 1), "%\n")
cat("  P(observational overestimate):", round((1-prob_underestimate)*100, 1), "%\n\n")

# ============================================================
# COMPREHENSIVE COMPARISON
# ============================================================

cat("COMPREHENSIVE METHOD COMPARISON (N=57 REAL DATA)\n")
cat("=============================================================\n\n")

comparison_table <- data.frame(
  Method = c("Standard RE", "Hartung-Knapp", "PET-adjusted",
             ifelse(!is.null(peese_model), "PEESE-adjusted", NA),
             "Limit meta-analysis", "Bayesian"),
  RoR = c(
    round(exp(coef(ma_standard)), 3),
    round(exp(coef(ma_hk)), 3),
    round(exp(coef(pet_model)[1]), 3),
    ifelse(!is.null(peese_model), round(exp(coef(peese_model)[1]), 3), NA),
    round(exp(coef(lim_model)[1]), 3),
    round(exp(post_mean_bayes), 3)
  ),
  CI_lower = c(
    round(exp(ma_standard$ci.lb), 3),
    round(exp(ma_hk$ci.lb), 3),
    NA,
    NA,
    round(exp(confint(lim_model)[1,1]), 3),
    round(exp(post_mean_bayes - 1.96*post_se_bayes), 3)
  ),
  CI_upper = c(
    round(exp(ma_standard$ci.ub), 3),
    round(exp(ma_hk$ci.ub), 3),
    NA,
    NA,
    round(exp(confint(lim_model)[1,2]), 3),
    round(exp(post_mean_bayes + 1.96*post_se_bayes), 3)
  ),
  P_value = c(
    round(ma_standard$pval, 4),
    round(ma_hk$pval, 4),
    round(pet_model$pval[1], 4),
    ifelse(!is.null(peese_model), round(peese_model$pval[1], 4), NA),
    round(summary(lim_model)$coefficients[1,4], 4),
    NA
  ),
  stringsAsFactors = FALSE
)

# Remove NA row if PEESE wasn't run
comparison_table <- comparison_table[!is.na(comparison_table$Method), ]

print(comparison_table, row.names = FALSE)
cat("\n")

# Calculate range and median (excluding NAs)
valid_ror <- comparison_table$RoR[!is.na(comparison_table$RoR)]
estimate_range <- range(valid_ror)
median_estimate <- median(valid_ror)

cat("Range of RoR:", round(estimate_range[1], 3), "to", round(estimate_range[2], 3), "\n")
cat("Variability:", round(estimate_range[2] - estimate_range[1], 3), "\n")
cat("Median RoR:", round(median_estimate, 3), "\n\n")

# ============================================================
# SAVE RESULTS
# ============================================================

saveRDS(list(
  ma_standard = ma_standard,
  ma_hartung_knapp = ma_hk,
  pet_model = pet_model,
  peese_model = peese_model,
  limit_model = lim_model,
  bayesian_posterior = list(mean = post_mean_bayes, sd = post_se_bayes),
  prediction_interval = pred,
  comparison_table = comparison_table,
  n = nrow(data_sel)
), "ANALYSIS_57_REAL_ONLY.rds")

write.csv(comparison_table, "COMPARISON_57_REAL_ONLY.csv", row.names = FALSE)

cat("✓ Saved analysis results for N=57 real data\n\n")

# ============================================================
# COMPARISON TO N=307 RESULTS
# ============================================================

cat("=============================================================\n")
cat("COMPARISON: N=57 REAL vs N=307 WITH SIMULATION\n")
cat("=============================================================\n\n")

cat("Standard Random-Effects:\n")
cat("  N=57 real:  RoR =", round(exp(coef(ma_standard)), 3),
    ", p =", round(ma_standard$pval, 3), ", I² =", round(ma_standard$I2, 1), "%\n")
cat("  N=307 full: RoR = 0.990, p = 0.599, I² = 67.1%\n\n")

cat("Publication bias (Egger's test):\n")
cat("  N=57 real:  p =", round(pet_model$pval[2], 4), "\n")
cat("  N=307 full: p = 0.002\n\n")

if (!is.null(peese_model)) {
  cat("PEESE-adjusted:\n")
  cat("  N=57 real:  RoR =", round(exp(coef(peese_model)[1]), 3), "\n")
  cat("  N=307 full: RoR = 0.950\n\n")
}

cat("Median across all methods:\n")
cat("  N=57 real:  RoR =", round(median_estimate, 3), "\n")
cat("  N=307 full: RoR = 0.958\n\n")

# ============================================================
# FINAL CONCLUSIONS
# ============================================================

cat("=============================================================\n")
cat("CONCLUSIONS: N=57 REAL DATA ANALYSIS\n")
cat("=============================================================\n\n")

cat("PRIMARY FINDING:\n")
if (ma_standard$pval < 0.05) {
  if (exp(coef(ma_standard)) < 1.0) {
    cat("  Observational studies UNDERESTIMATE effects\n")
    cat("  Magnitude:", round((1 - exp(coef(ma_standard)))*100, 1), "%\n")
  } else {
    cat("  Observational studies OVERESTIMATE effects\n")
    cat("  Magnitude:", round((exp(coef(ma_standard)) - 1)*100, 1), "%\n")
  }
} else {
  cat("  NO SIGNIFICANT OVERALL BIAS (p =", round(ma_standard$pval, 2), ")\n")
}

cat("\nHETEROGENEITY:\n")
cat("  I² =", round(ma_standard$I2, 1), "%\n")
cat("  Prediction interval:", round(exp(pred$pi.lb), 2), "to",
    round(exp(pred$pi.ub), 2), "\n")

if (pet_model$pval[2] < 0.10 && !is.null(peese_model)) {
  cat("\nPUBLICATION BIAS:\n")
  cat("  Detected (p =", round(pet_model$pval[2], 3), ")\n")
  cat("  PEESE-adjusted RoR:", round(exp(coef(peese_model)[1]), 3), "\n")
}

cat("\nROBUSTNESS:\n")
cat("  Range across methods:", round(estimate_range[1], 3), "to",
    round(estimate_range[2], 3), "\n")
cat("  Median:", round(median_estimate, 3), "\n")

cat("\n=============================================================\n")
cat("ANALYSIS OF 57 REAL COMPARISONS COMPLETE\n")
cat("=============================================================\n")
