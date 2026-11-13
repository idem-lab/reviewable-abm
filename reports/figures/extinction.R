# Expected: at low baseline transmission hazards almost every replicate
# dies out with few infections. Above a threshold, a growing proportion of
# replicates have a large epidemic, so the infections per person form two
# groups, near zero and large, and the proportion with a large epidemic
# rises with the hazard. It stays below 1 because epidemics started by 5
# infections can still die out by chance.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("extinction")
# a large epidemic infects more than one person in ten
draws$large <- draws$infections_per_person > 0.1
proportions <- aggregate(large ~ baseline_transmission_hazard, draws, mean)
proportions$replicates <- as.vector(table(draws$baseline_transmission_hazard))
proportions$lower <- qbeta(0.025, proportions$large * proportions$replicates +
                             0.5,
                           (1 - proportions$large) * proportions$replicates +
                             0.5)
proportions$upper <- qbeta(0.975, proportions$large * proportions$replicates +
                             0.5,
                           (1 - proportions$large) * proportions$replicates +
                             0.5)

sizes_figure <- ggplot(draws, aes(factor(baseline_transmission_hazard),
                                  infections_per_person)) +
  geom_jitter(width = 0.2, height = 0, size = 0.8, alpha = 0.5,
              colour = figure_colours[1]) +
  geom_hline(yintercept = 0.1, linetype = "dashed", colour = "grey50") +
  labs(x = "baseline transmission hazard (per hour)",
       y = "infections per person",
       title = "Size of each replicate epidemic")

proportions_figure <- ggplot(proportions,
                             aes(baseline_transmission_hazard, large)) +
  geom_pointrange(aes(ymin = lower, ymax = upper),
                  colour = figure_colours[2]) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "baseline transmission hazard (per hour)",
       y = "proportion with a large epidemic",
       title = "Probability of a large epidemic")

caption <- paste0(
  "Large: more than 0.1 infections per person (dashed line).",
  "\n64 replicates per hazard, population 300; intervals are ",
  "95% Jeffreys intervals."
)
save_figure(sizes_figure / proportions_figure +
              plot_annotation(caption = caption),
            "extinction", height = 7)
