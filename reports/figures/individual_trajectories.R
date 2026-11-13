# Expected: each person's first infection peaks at their drawn viral load
# level on day 4, with no immunity, and leaves immunity equal to their
# boost size, which then declines linearly. People with higher viral load
# tend to have larger boosts (correlation 0.5), but not always. The
# reinfection on day 120 has lower viral load the more immunity remains,
# by exp(-0.5 x immunity), and adds its boost to that remaining immunity.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("individual_trajectories")
draws$person <- factor(draws$person)
# draw each infection as its own line, so lines do not join across the
# time between infections
draws$infection <- ifelse(draws$day < 120, "first", "second")

viral_load_figure <- ggplot(draws[draws$infected & draws$viral_load > 0, ],
                            aes(day, viral_load, colour = person,
                                group = interaction(person, infection))) +
  geom_line() +
  scale_y_log10(labels = scales::label_number()) +
  coord_cartesian(xlim = c(0, 300)) +
  labs(x = "day", y = "viral load (log scale)", title = "Viral load")

immunity_figure <- ggplot(draws, aes(day, immunity_level,
                                     colour = person)) +
  geom_line() +
  coord_cartesian(xlim = c(0, 300)) +
  labs(x = "day", y = "immunity level", title = "Immunity")

figure <- viral_load_figure / immunity_figure +
  plot_annotation(
    title = "Eight people, infected on day 0 and again on day 120",
    caption = paste("Characteristics drawn at each infection; colours",
                    "match each person across panels.")
  ) +
  plot_layout(guides = "collect")
save_figure(figure, "individual_trajectories", width = 9, height = 7)
