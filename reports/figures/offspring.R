# Expected: with constant contact and contacts who are never depleted, the
# number of secondary infections per infector (the offspring distribution)
# is overdispersed, with variance well above the mean, because the
# expected number for each infector is proportional to their lognormal
# viral load level (sdlog 1). The mean rises with profile width, because
# a wider profile means more total viral load over an infection; it
# depends little on timestep length. Within each condition, the number of
# secondary infections rises in proportion to viral load level.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("offspring")
draws$width <- paste("profile width", draws$profile_width)
draws$timestep <- paste("timestep", draws$timestep_length, "days")
summaries <- aggregate(secondary_infections ~ width + timestep, draws,
                       function(x) c(mean = mean(x), variance = var(x)))
summaries <- data.frame(summaries[, c("width", "timestep")],
                        summaries$secondary_infections)
summaries$label <- sprintf("mean %.2f\nvariance %.2f", summaries$mean,
                           summaries$variance)

distribution_figure <- ggplot(draws, aes(secondary_infections)) +
  geom_bar(fill = figure_colours[1]) +
  geom_text(data = summaries, aes(x = Inf, y = Inf, label = label),
            hjust = 1.1, vjust = 1.3, size = 3) +
  facet_grid(timestep ~ width) +
  coord_cartesian(xlim = c(0, 15)) +
  labs(x = "secondary infections", y = "infectors",
       title = "Offspring distribution")

by_level_figure <- ggplot(draws[draws$timestep_length == 0.1, ],
                          aes(viral_load_level, secondary_infections)) +
  geom_jitter(width = 0, height = 0.2, size = 0.3, alpha = 0.2,
              colour = figure_colours[1]) +
  geom_smooth(method = "loess", formula = y ~ x, colour = figure_colours[2],
              se = FALSE) +
  facet_wrap(~ width) +
  scale_x_log10(labels = scales::label_number()) +
  labs(x = "infector viral load level (log scale)",
       y = "secondary infections",
       title = "Secondary infections by viral load level, timestep 0.1 days")

figure <- distribution_figure / by_level_figure +
  plot_layout(heights = c(2, 1)) +
  plot_annotation(caption = paste(
    "6000 infectors per condition, adults with no immunity, meeting",
    "10 non-household contacts a day who are never depleted."
  ))
save_figure(figure, "offspring", width = 10, height = 9)
