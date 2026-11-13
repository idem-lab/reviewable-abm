# Expected: faster waning gives more infections per person, because
# immunity is lost sooner and people are reinfected. A larger household
# location score gives more infections. A wider viral load profile spreads
# transmission over more days and gives longer infections. The correlation
# between viral load level and boost size has little effect on infections
# over 150 days. Replicates that die out early sit near zero throughout.

source("reports/theme.R")

draws <- read_draws("sensitivity")
long <- rbind(
  data.frame(draws[, c("parameter", "value", "is_default")],
             outcome = "infections per person",
             result = draws$infections_per_person),
  data.frame(draws[, c("parameter", "value", "is_default")],
             outcome = "day of peak number infected",
             result = draws$peak_time)
)
long$parameter <- gsub("_", " ", long$parameter)

figure <- ggplot(long, aes(factor(value), result, colour = is_default)) +
  geom_jitter(width = 0.15, height = 0, size = 0.8, alpha = 0.6) +
  stat_summary(fun = median, geom = "crossbar", width = 0.5,
               colour = "black", linewidth = 0.3) +
  facet_grid(outcome ~ parameter, scales = "free", switch = "y") +
  scale_colour_manual(values = c(`TRUE` = figure_colours[2],
                                 `FALSE` = figure_colours[1]),
                      labels = c(`TRUE` = "default value",
                                 `FALSE` = "changed value")) +
  labs(x = "parameter value", y = NULL, colour = NULL,
       title = "Changing one parameter at a time",
       caption = paste("24 replicates per value, population 300,",
                       "150 days. Bars: medians."))

save_figure(figure, "sensitivity", width = 10, height = 6)
