# Expected: viral load levels and boost sizes are each lognormal, with
# median viral load level 1 and median boost size exp(immunity boost
# meanlog), and their logs have the set correlation, so the points lie
# along a tighter upward band as the correlation increases.

source("reports/theme.R")

draws <- read_draws("infection_characteristics")

figure <- ggplot(draws, aes(viral_load_level, boost_size)) +
  geom_point(size = 0.4, alpha = 0.3, colour = figure_colours[1]) +
  facet_wrap(~ paste("correlation", correlation)) +
  scale_x_log10(labels = scales::label_number()) +
  scale_y_log10(labels = scales::label_number()) +
  labs(x = "viral load level (log scale)",
       y = "immunity boost size (log scale)",
       title = "Characteristics drawn at infection")

save_figure(figure, "infection_characteristics")
