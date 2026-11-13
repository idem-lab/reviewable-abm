# Expected: a larger household location score raises the hazard of household
# contact events, so household outbreaks are larger and the final attack
# rate rises, though by less as household outbreaks approach the size of the
# household. Spread between households depends on non-household contact
# events, so the day of peak prevalence changes little compared with the
# variation between replicates. (Revised after review: this expectation
# first said the peak would come earlier.) A wider viral load profile means
# more total viral load, and so more transmission, over each infection, so
# the final attack rate rises; it also spreads transmission over more days,
# which slows growth and can make the peak later. The correlation between
# potential peak viral load and boost size changes who is best protected
# afterwards, but over 150 days, mostly a single wave, it should have little
# effect. Replicates that die out early sit near zero.

source("reports/theme.R")

draws <- read_draws("sensitivity")
long <- rbind(
  data.frame(draws[, c("parameter", "value", "is_default")],
             outcome = "final attack rate",
             result = draws$final_attack_rate),
  data.frame(draws[, c("parameter", "value", "is_default")],
             outcome = "day of peak prevalence",
             result = draws$time_of_peak_prevalence)
)
long$parameter <- gsub("_", " ", long$parameter)

figure <- ggplot(long, aes(factor(value), result, colour = is_default)) +
  geom_jitter(width = 0.15, height = 0, size = 0.8, alpha = 0.6) +
  stat_summary(fun = median, geom = "crossbar", width = 0.5,
               colour = "black", linewidth = 0.3) +
  facet_grid(outcome ~ parameter, scales = "free", switch = "y") +
  scale_colour_manual(values = c(`TRUE` = "black",
                                 `FALSE` = "grey60"),
                      labels = c(`TRUE` = "default value",
                                 `FALSE` = "changed value")) +
  labs(x = "parameter value", y = NULL, colour = NULL,
       title = "Changing one parameter at a time",
       caption = paste("24 replicates per value, population 300,",
                       "150 days. Bars: medians."))

save_figure(figure, "sensitivity", width = 10, height = 6)
