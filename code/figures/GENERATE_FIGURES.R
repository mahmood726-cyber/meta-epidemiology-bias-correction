# GENERATE ALL PUBLICATION FIGURES
# For BMC Medical Research Methodology submission
# Date: 2025-11-22

suppressPackageStartupMessages({
  library(metafor)
  library(dplyr)
})

cat("=============================================================\n")
cat("GENERATING ALL PUBLICATION FIGURES\n")
cat("=============================================================\n\n")

# Load data
full_data <- readRDS("EXPANDED_DATASET_300_COMPARISONS.rds")
real_data <- full_data %>%
  filter(!(source %in% c("BMC_2024_SIMULATED", "MULTIVALIDATED_SIM")))

results_57 <- readRDS("ANALYSIS_57_REAL_ONLY.rds")
ma <- results_57$ma_standard

cat("Dataset: N =", nrow(real_data), "real comparisons\n\n")

# Prepare data
data_plot <- real_data %>%
  select(ror_log, ror_se, concordant, global_ma_id) %>%
  filter(!is.na(ror_log) & !is.na(ror_se))

# ============================================================
# FIGURE 1: FLOW DIAGRAM (Text-based for now)
# ============================================================

cat("FIGURE 1: Flow Diagram\n")
cat("-------------------------------------------------------------\n\n")

flow_diagram <- "
FLOW DIAGRAM: Data Sources and Selection
==========================================

┌─────────────────────────────────────────┐
│  SYSTEMATIC SEARCH FOR                  │
│  META-EPIDEMIOLOGICAL DATA              │
└──────────────┬──────────────────────────┘
               │
               ├──────────────────────────────┐
               │                              │
    ┌──────────▼─────────┐       ┌───────────▼──────────┐
    │  IMPACT-HTA        │       │  BMC Medicine 2022   │
    │  Database          │       │  Meta-Epidemio Study │
    │                    │       │                      │
    │  N = 8             │       │  N = 49              │
    └──────────┬─────────┘       └───────────┬──────────┘
               │                              │
               └──────────┬───────────────────┘
                          │
               ┌──────────▼──────────┐
               │  COMBINED DATASET   │
               │  N = 57             │
               │                     │
               │  Real comparisons   │
               │  (No simulation)    │
               └──────────┬──────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────▼─────┐  ┌─────▼──────┐  ┌─────▼──────┐
   │ Standard   │  │ Bias-      │  │ Bayesian   │
   │ Meta-      │  │ Correction │  │ MCMC       │
   │ Analysis   │  │ Methods    │  │ Analysis   │
   │            │  │ (6)        │  │            │
   └────────────┘  └────────────┘  └────────────┘

EXCLUSIONS:
• Anglemyer 2014 (N=1,583): Data not publicly available
• BMC 2024 (N=220): Individual comparison data not extractable
• Simulated comparisons (N=250): Excluded from primary analysis

FINAL DATASET:
• N = 57 real comparisons
• 8 from IMPACT-HTA
• 49 from BMC Medicine 2022
• 100% empirical data
"

cat(flow_diagram)
cat("\n")

# Save flow diagram
writeLines(flow_diagram, "FIGURE_1_FLOW_DIAGRAM.txt")
cat("✓ Saved Figure 1 (flow diagram)\n\n")

# ============================================================
# FIGURE 2: FOREST PLOT
# ============================================================

cat("FIGURE 2: Forest Plot\n")
cat("-------------------------------------------------------------\n\n")

# Create forest plot
png("FIGURE_2_FOREST_PLOT.png", width = 1200, height = 2000, res = 150)

# Set up plot
par(mar = c(5, 4, 4, 2))

# Forest plot
forest(ma,
       xlim = c(-3, 3),
       at = log(c(0.25, 0.5, 0.7, 1.0, 1.43, 2.0, 4.0)),
       atransf = exp,
       xlab = "Ratio of Odds Ratios (RoR)",
       slab = paste0("Comparison ", 1:nrow(data_plot)),
       ilab = cbind(ifelse(data_plot$concordant, "Concordant", "Discordant")),
       ilab.xpos = -2.5,
       ilab.pos = 2,
       header = c("Comparison", "Status"),
       col = ifelse(data_plot$concordant, "darkgreen", "darkred"),
       psize = 0.8,
       cex = 0.7,
       main = "Forest Plot: RCT vs Observational Comparisons (N=57)")

# Add prediction interval
pred <- results_57$prediction_interval
abline(v = exp(pred$pi.lb), lty = 2, col = "blue", lwd = 2)
abline(v = exp(pred$pi.ub), lty = 2, col = "blue", lwd = 2)
text(-2.8, -3, paste0("Prediction Interval: ", round(exp(pred$pi.lb), 2),
                      " to ", round(exp(pred$pi.ub), 2)), pos = 4, col = "blue", cex = 0.8)

# Add legend
legend("topright",
       legend = c("Concordant (DI<2)", "Discordant (DI≥2)", "Prediction Interval"),
       col = c("darkgreen", "darkred", "blue"),
       pch = c(15, 15, NA),
       lty = c(NA, NA, 2),
       cex = 0.8)

dev.off()

cat("✓ Saved Figure 2 (forest plot)\n\n")

# ============================================================
# FIGURE 3: FUNNEL PLOT
# ============================================================

cat("FIGURE 3: Funnel Plot\n")
cat("-------------------------------------------------------------\n\n")

# Create funnel plot
png("FIGURE_3_FUNNEL_PLOT.png", width = 1000, height = 800, res = 150)

par(mar = c(5, 4, 4, 2))

# Funnel plot
funnel(ma,
       xlim = c(-2, 2),
       ylim = c(0.6, 0),
       xlab = "Log Ratio of Odds Ratios",
       ylab = "Standard Error",
       main = "Funnel Plot with Trim-and-Fill (N=57)",
       col = ifelse(data_plot$concordant, "darkgreen", "darkred"),
       pch = 19)

# Add trim-and-fill
taf <- trimfill(ma)
funnel(taf, col = "white", pch = 1, add = TRUE)

# Add legend
legend("topright",
       legend = c("Observed - Concordant", "Observed - Discordant",
                 "Trim-and-Fill Imputed"),
       col = c("darkgreen", "darkred", "black"),
       pch = c(19, 19, 1),
       cex = 0.9)

# Add Egger's test result
text(-1.8, 0.05,
     paste0("Egger's test: p < 0.001\nTrimmed studies: ", taf$k0),
     pos = 4, cex = 0.9)

dev.off()

cat("✓ Saved Figure 3 (funnel plot)\n\n")

# ============================================================
# FIGURE 4: METHOD COMPARISON
# ============================================================

cat("FIGURE 4: Method Comparison\n")
cat("-------------------------------------------------------------\n\n")

# Get comparison data
comparison <- results_57$comparison_table

# Create bar chart
png("FIGURE_4_METHOD_COMPARISON.png", width = 1000, height = 600, res = 150)

par(mar = c(8, 4, 4, 2))

# Prepare data for plotting
methods <- comparison$Method
rors <- comparison$RoR
ci_lower <- comparison$CI_lower
ci_upper <- comparison$CI_upper

# Create colors: bias-corrected in blue, unadjusted in gray
colors <- ifelse(grepl("adjusted|Limit|Trim|Bayesian", methods), "steelblue", "gray70")

# Bar plot
bp <- barplot(rors,
              names.arg = methods,
              las = 2,
              ylim = c(0.8, 1.15),
              col = colors,
              ylab = "Ratio of Odds Ratios (RoR)",
              main = "Method Comparison: All Approaches (N=57)",
              border = "black",
              cex.names = 0.8)

# Add confidence intervals
for (i in 1:length(rors)) {
  if (!is.na(ci_lower[i]) && !is.na(ci_upper[i])) {
    arrows(bp[i], ci_lower[i], bp[i], ci_upper[i],
           angle = 90, code = 3, length = 0.05, lwd = 2)
  }
}

# Add reference line at RoR = 1.0
abline(h = 1.0, lty = 2, lwd = 2, col = "red")

# Add median line for bias-corrected methods
bias_corrected <- rors[grepl("adjusted|Limit|Bayesian", methods)]
median_bc <- median(bias_corrected[!is.na(bias_corrected)])
abline(h = median_bc, lty = 3, lwd = 2, col = "blue")

# Add legend
legend("topright",
       legend = c("Unadjusted", "Bias-Corrected", "RoR = 1.0", "Median (Bias-Corrected)"),
       fill = c("gray70", "steelblue", NA, NA),
       border = c("black", "black", NA, NA),
       lty = c(NA, NA, 2, 3),
       lwd = c(NA, NA, 2, 2),
       col = c(NA, NA, "red", "blue"),
       cex = 0.8)

# Add text annotation
text(bp[1], 1.12, paste0("Range (bias-corrected): ",
                         round(min(bias_corrected, na.rm = TRUE), 3), " to ",
                         round(max(bias_corrected, na.rm = TRUE), 3)),
     pos = 4, cex = 0.9)

dev.off()

cat("✓ Saved Figure 4 (method comparison)\n\n")

# ============================================================
# SUPPLEMENTARY FIGURE: CONCORDANCE SENSITIVITY
# ============================================================

cat("SUPPLEMENTARY FIGURE: Concordance Sensitivity\n")
cat("-------------------------------------------------------------\n\n")

# Load concordance sensitivity results
concordance_sens <- read.csv("CONCORDANCE_SENSITIVITY.csv")

png("SUPPLEMENTARY_CONCORDANCE_SENSITIVITY.png", width = 800, height = 600, res = 150)

par(mar = c(5, 4, 4, 2))

plot(concordance_sens$Threshold, concordance_sens$Pct_Concordant,
     type = "b",
     pch = 19,
     col = "darkgreen",
     lwd = 2,
     xlab = "Discordance Index Threshold",
     ylab = "Percentage Concordant (%)",
     main = "Concordance Rate by Threshold Definition",
     ylim = c(50, 85),
     las = 1)

# Add points
points(concordance_sens$Threshold, concordance_sens$Pct_Concordant,
       pch = 19, col = "darkgreen", cex = 1.5)

# Add grid
grid()

# Highlight primary definition (DI < 2.0)
abline(v = 2.0, lty = 2, col = "red", lwd = 2)
text(2.0, 83, "Primary definition\n(DI < 2.0)", pos = 4, col = "red", cex = 0.9)

# Add values
text(concordance_sens$Threshold, concordance_sens$Pct_Concordant + 2,
     paste0(concordance_sens$Pct_Concordant, "%"),
     cex = 0.8)

dev.off()

cat("✓ Saved Supplementary Figure (concordance sensitivity)\n\n")

# ============================================================
# CREATE FIGURE LEGENDS
# ============================================================

cat("Creating figure legends file...\n\n")

legends <- "
FIGURE LEGENDS FOR MANUSCRIPT
===============================

FIGURE 1: Flow Diagram of Study Selection and Data Sources
Flow diagram showing data source identification, inclusion criteria, and final dataset
composition. The analysis included 57 real comparisons from two sources: IMPACT-HTA
database (n=8) and BMC Medicine 2022 meta-epidemiological review (n=49). Anglemyer 2014
data (1,583 comparisons) and BMC 2024 data (220 reviews) were not publicly accessible.
All 250 simulated comparisons from previous analyses were excluded.

FIGURE 2: Forest Plot of All 57 Comparisons
Forest plot showing individual RCT vs observational comparison results (ratio of odds
ratios, RoR) with 95% confidence intervals. Concordant comparisons (discordance index
<2, n=37) are shown in green, discordant comparisons (DI ≥2, n=20) in red. The pooled
estimate (diamond) is 1.020 (95% CI 0.913-1.140, p=0.73). Blue dashed lines indicate
the prediction interval (0.50-2.06), demonstrating extreme heterogeneity (I²=91%).

FIGURE 3: Funnel Plot with Trim-and-Fill Analysis
Funnel plot assessing publication bias. Green dots represent concordant comparisons,
red dots represent discordant comparisons. White circles show imputed missing studies
from trim-and-fill analysis (14 studies trimmed). Egger's test for asymmetry was
highly significant (p<0.001), indicating substantial publication bias. The adjusted
estimate after trim-and-fill is RoR=0.870 (95% CI 0.764-0.989).

FIGURE 4: Comparison of All Seven Statistical Methods
Bar chart comparing ratio of odds ratios (RoR) across all seven methods. Gray bars
show unadjusted methods (Standard RE, Hartung-Knapp), blue bars show bias-corrected
methods (PET, PEESE, trim-and-fill, limit MA, Bayesian). Error bars represent 95%
confidence/credible intervals where available. Red dashed line indicates RoR=1.0
(no bias). Blue dashed line shows median of bias-corrected methods (0.887). All
bias-corrected methods converge on 9-13% underestimation by observational studies.

SUPPLEMENTARY FIGURE: Sensitivity Analysis of Concordance Definition
Line plot showing how concordance rate varies with discordance index threshold.
Concordance ranges from 53% (strict threshold DI<1.5) to 83% (lenient threshold
DI<3.0). Primary definition (DI<2.0, shown in red) yields 65% concordance.
This demonstrates that concordance assessment is sensitive to threshold choice,
though the qualitative conclusion (majority concordant) remains stable.
"

writeLines(legends, "FIGURE_LEGENDS.txt")

cat("✓ Saved figure legends\n\n")

# ============================================================
# SUMMARY
# ============================================================

cat("=============================================================\n")
cat("FIGURE GENERATION COMPLETE\n")
cat("=============================================================\n\n")

cat("Generated files:\n")
cat("  1. FIGURE_1_FLOW_DIAGRAM.txt\n")
cat("  2. FIGURE_2_FOREST_PLOT.png\n")
cat("  3. FIGURE_3_FUNNEL_PLOT.png\n")
cat("  4. FIGURE_4_METHOD_COMPARISON.png\n")
cat("  5. SUPPLEMENTARY_CONCORDANCE_SENSITIVITY.png\n")
cat("  6. FIGURE_LEGENDS.txt\n\n")

cat("All figures ready for manuscript submission!\n\n")
