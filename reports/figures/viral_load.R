# Expected: viral load is zero at infection, peaks at the peak time
# (4 days) at a height set by the viral load level, and declines
# symmetrically in log time. Wider profiles rise earlier and last longer.
# Infections end when viral load falls below the recovery threshold after
# the peak, so higher viral load levels and wider profiles give longer
# infections.

source("reports/theme.R")

draws <- read_draws("viral_load")
draws <- draws[draws$viral_load > 0, ]

figure <- ggplot(draws, aes(time_since_infection, viral_load,
                            colour = factor(viral_load_level))) +
  geom_hline(aes(yintercept = recovery_threshold), linetype = "dashed",
             colour = "grey50") +
  geom_vline(aes(xintercept = peak_time), linetype = "dotted",
             colour = "grey50") +
  geom_line() +
  facet_wrap(~ paste("profile width", profile_width)) +
  scale_y_log10(limits = c(1e-4, 3), labels = scales::label_number()) +
  labs(x = "time since infection (days)", y = "viral load (log scale)",
       colour = "viral load level",
       title = "Viral load over an infection, with no immunity",
       caption = paste("Dashed: recovery threshold.",
                       "Dotted: peak time."))

save_figure(figure, "viral_load")
