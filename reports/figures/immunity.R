# Expected: after a boost, immunity declines linearly at the waning rate
# and reaches zero after boost size / waning rate days, so larger boosts
# and slower waning protect for longer. Relative susceptibility,
# exp(-immunity), therefore rises slowly at first and then quickly, and
# reaches 1 abruptly when immunity is lost. Each infection adds its boost
# to the immunity that remains, so repeated infections close together
# build up immunity, and faster waning lets less of it build up.

source("reports/theme.R")
library(patchwork)

over_time <- read_draws("immunity_over_time")
repeated <- read_draws("repeated_infections")
over_time$waning <- paste("waning rate", over_time$waning_rate)

immunity_figure <- ggplot(over_time, aes(time_since_boost, immunity_level,
                                         colour = factor(boost_size))) +
  geom_line() +
  scale_colour_boost_size() +
  facet_wrap(~ waning) +
  labs(x = "time since boost (days)", y = "immunity level",
       colour = "boost size", title = "Immunity after one boost")

susceptibility_figure <- ggplot(over_time,
                                aes(time_since_boost,
                                    relative_susceptibility,
                                    colour = factor(boost_size))) +
  geom_line() +
  scale_colour_boost_size() +
  facet_wrap(~ waning) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "time since boost (days)", y = "relative susceptibility",
       colour = "boost size", title = "Susceptibility after one boost")

repeated_figure <- ggplot(repeated, aes(day, immunity_level,
                                        colour = factor(waning_rate))) +
  geom_vline(xintercept = c(0, 120, 160), colour = "grey80") +
  geom_line() +
  scale_colour_waning_rate() +
  labs(x = "day", y = "immunity level", colour = "waning rate (per day)",
       title = "Infections on days 0, 120 and 160, boosts 2, 1 and 1.5")

figure <- immunity_figure / susceptibility_figure / repeated_figure +
  plot_annotation(caption = "An adult; relative to no immunity.")
save_figure(figure, "immunity", width = 9, height = 10)
