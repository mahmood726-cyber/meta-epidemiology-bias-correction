# Minimal smoke test for the meta-epidemiology bias-correction analysis.
#
# Run from the repository root:
#   Rscript tests/smoke_test.R
#
# It loads the shipped dataset, reproduces the core N=57 random-effects
# pooling on the log ratio-of-ratios, and asserts the result is finite and
# in a sane range. It does NOT pin exact numeric values (those live in the
# manuscript / results/), only that the engine runs and returns valid output.

suppressPackageStartupMessages({
  library(metafor)
  library(dplyr)
})

# Locate the dataset whether the script is run from the repo root, the tests/
# directory, or data/processed/ (where the analysis scripts set their wd).
candidate_paths <- c(
  file.path("data", "processed", "EXPANDED_DATASET_300_COMPARISONS.rds"),
  file.path("..", "data", "processed", "EXPANDED_DATASET_300_COMPARISONS.rds"),
  "EXPANDED_DATASET_300_COMPARISONS.rds"
)
data_path <- candidate_paths[file.exists(candidate_paths)][1]
stopifnot("dataset not found - run from repo root" =
            !is.na(data_path) && length(data_path) == 1)

full_data <- readRDS(data_path)
stopifnot("dataset is empty" = nrow(full_data) > 0)

# Real comparisons only (exclude simulated sources), matching the primary analysis.
real_data <- full_data %>%
  filter(!(source %in% c("BMC_2024_SIMULATED", "MULTIVALIDATED_SIM")))

data_sel <- real_data %>%
  select(ror_log, ror_se) %>%
  filter(!is.na(ror_log) & !is.na(ror_se) & is.finite(ror_log) & is.finite(ror_se))

stopifnot("expected the 57 real comparisons" = nrow(data_sel) == 57)
stopifnot("no zero or negative standard errors allowed" = all(data_sel$ror_se > 0))

ma <- rma(yi = ror_log, sei = ror_se, method = "REML", data = data_sel)

ror <- exp(coef(ma))
stopifnot("pooled estimate must be finite" = is.finite(ror))
stopifnot("pooled RoR out of sane range" = ror > 0.1 && ror < 10)
stopifnot("I-squared must be a valid percentage" = is.finite(ma$I2) && ma$I2 >= 0 && ma$I2 <= 100)

# PET small-study-effect regression must also fit.
pet <- rma(yi = ror_log, sei = ror_se, mods = ~ ror_se, method = "FE", data = data_sel)
stopifnot("PET intercept must be finite" = is.finite(coef(pet)[1]))

cat("SMOKE TEST PASSED\n")
cat(sprintf("  n = %d, pooled RoR = %.3f, I2 = %.1f%%\n",
            nrow(data_sel), ror, ma$I2))
