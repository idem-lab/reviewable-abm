# Expected: each infection adds its boost to the immunity that remains,
# and immunity then declines linearly at the waning rate until it reaches
# zero, so faster waning loses immunity sooner and boosts add up less. The
# relative hazard of infection, exp(-immunity), rises slowly at first and
# then quickly, reaching 1 abruptly when immunity is lost.

source("reports/theme.R")

draws <- read_draws("immunity")
draws$relative_hazard <- exp(-draws$immunity_level)
long <- rbind(
  data.frame(draws[, c("waning_rate", "day")], quantity = "immunity level",
             value = draws$immunity_level),
  data.frame(draws[, c("waning_rate", "day")],
             quantity = "relative hazard of infection",
             value = draws$relative_hazard)
)

figure <- ggplot(long, aes(day, value, colour = factor(waning_rate))) +
  geom_vline(xintercept = c(0, 120, 160), colour = "grey80") +
  geom_line() +
  facet_wrap(~ quantity, scales = "free_y", ncol = 1) +
  labs(x = "day", y = NULL, colour = "waning rate (per day)",
       title = "Immunity after infections on days 0, 120 and 160",
       caption = "Boost sizes 2, 1 and 1.5.")

save_figure(figure, "immunity", height = 6)
