Mahmood Ahmad
Tahir Heart Institute
author@example.com

Bias-Correction Methods Reveal Underestimation by Observational Studies

Do standard random-effects meta-analyses mask systematic publication bias in meta-epidemiological comparisons of randomized and observational studies? We assembled 57 ratio-of-ratios comparisons from the IMPACT-HTA database and a BMC Medicine 2022 review covering cardiovascular, oncology, and infectious disease domains. Seven correction methods including REML, Hartung-Knapp, PET-PEESE, trim-and-fill, limit meta-analysis, selection models, and Bayesian MCMC were applied to each comparison against the standard uncorrected estimate. The standard estimate showed no significant bias, but after correction all convergent methods indicated 9 to 13 percent underestimation by observational studies, with median corrected RR 0.887 (95% CI 0.764 to 0.989). Selection models failed for all three specifications due to insufficient sample size, while extreme heterogeneity at I-squared 91.2 percent was driven by 35 percent discordant comparisons. Stratification by a novel discordance index revealed that 64.9 percent of comparisons show agreement below the two-fold divergence threshold. However, a limitation is that the 57-comparison sample restricts statistical power for subgroup-specific bias correction estimates.

Outside Notes

Type: meta-epidemiology
Primary estimand: Ratio of ratios
App: Meta-Epidemiology Bias Correction v1.0
Data: 57 RoR comparisons from IMPACT-HTA and BMC Medicine 2022
Code: https://github.com/mahmood789/meta-epidemiology-bias-correction
Version: 1.0
Validation: DRAFT

References

1. Roever C. Bayesian random-effects meta-analysis using the bayesmeta R package. J Stat Softw. 2020;93(6):1-51.
2. Higgins JPT, Thompson SG, Spiegelhalter DJ. A re-evaluation of random-effects meta-analysis. J R Stat Soc Ser A. 2009;172(1):137-159.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.

AI Disclosure

This work represents a compiler-generated evidence micro-publication (i.e., a structured, pipeline-based synthesis output). AI (Claude, Anthropic) was used as a constrained synthesis engine operating on structured inputs and predefined rules for infrastructure generation, not as an autonomous author. The 156-word body was written and verified by the author, who takes full responsibility for the content. This disclosure follows ICMJE recommendations (2023) that AI tools do not meet authorship criteria, COPE guidance on transparency in AI-assisted research, and WAME recommendations requiring disclosure of AI use. All analysis code, data, and versioned evidence capsules (TruthCert) are archived for independent verification.
