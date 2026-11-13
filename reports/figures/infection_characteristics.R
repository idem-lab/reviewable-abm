# Expected: on the scales where they act, the characteristics drawn at
# infection are skewed. Peak viral load with no immunity equals the viral
# load level, which is lognormal with median 1, so most infections peak
# near 1 and a few much higher. Relative susceptibility just after the
# boost, exp(-boost size), is mostly between about 0.05 and 0.4, because
# boost sizes have median 2 (exp(meanlog)); the days until a boost has
# waned (boost size / 0.01) are mostly 100 to 400. With a positive
# correlation, infections with higher peak viral load tend to leave lower
# susceptibility and longer protection.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("infection_characteristics")
draws$correlation <- paste("correlation", draws$correlation)

susceptibility_figure <- ggplot(draws,
                                aes(peak_viral_load,
                                    relative_susceptibility_after_boost)) +
  geom_point(size = 0.4, alpha = 0.3, colour = figure_colours[1]) +
  facet_wrap(~ correlation) +
  scale_x_log10(labels = scales::label_number()) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "peak viral load (log scale)",
       y = "relative susceptibility after boost",
       title = "Susceptibility left by an infection")

protection_figure <- ggplot(draws, aes(peak_viral_load, days_until_waned)) +
  geom_point(size = 0.4, alpha = 0.3, colour = figure_colours[2]) +
  facet_wrap(~ correlation) +
  scale_x_log10(labels = scales::label_number()) +
  labs(x = "peak viral load (log scale)",
       y = "days until boost has waned",
       title = "Duration of protection from an infection")

figure <- susceptibility_figure / protection_figure +
  plot_annotation(
    title = "Characteristics drawn at infection, on the scales they act on",
    caption = paste("2000 draws per correlation; an adult with no immunity",
                    "before infection; waning rate 0.01 per day.")
  )
save_figure(figure, "infection_characteristics", width = 9, height = 8)
