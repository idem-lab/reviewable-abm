# Expected: viral load is zero at infection, peaks at the peak time
# (4 days), and declines symmetrically in log time. The potential peak
# viral load multiplies the whole curve, and immunity at infection divides
# it by exp(0.5 x immunity), so on a log scale both shift the curve up or
# down without changing its shape; the profile width alone changes its
# shape, with wider profiles rising earlier and lasting longer. Infections
# end when viral load falls below the recovery threshold after the peak, so
# higher potential peaks and wider profiles give longer infections, and
# immunity shortens them. Peak viral load equals the potential peak times
# exp(-0.5 x immunity), so its contours over potential peak and immunity
# are straight lines on a log scale of potential peak.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("viral_load")
peaks <- read_draws("peak_viral_load")

by_level_and_width <- ggplot(draws[draws$immunity_at_infection == 0, ],
                             aes(time_since_infection, viral_load,
                                 colour = factor(potential_peak_viral_load))) +
  geom_hline(aes(yintercept = recovery_threshold), linetype = "dashed",
             colour = "grey50") +
  geom_line() +
  scale_colour_viral_load() +
  facet_wrap(~ paste("profile width", profile_width)) +
  scale_y_log10(limits = c(1e-4, 10), labels = scales::label_number()) +
  labs(x = "time since infection (days)", y = "viral load (log scale)",
       colour = "potential peak viral load",
       title = paste("By potential peak viral load and profile width,",
                     "with no immunity"))

by_immunity <- ggplot(draws[draws$potential_peak_viral_load == 1 &
                              draws$profile_width == draws$default_width, ],
                      aes(time_since_infection, viral_load,
                          colour = factor(immunity_at_infection))) +
  geom_hline(aes(yintercept = recovery_threshold), linetype = "dashed",
             colour = "grey50") +
  geom_line() +
  scale_colour_immunity() +
  scale_y_log10(limits = c(1e-4, 10), labels = scales::label_number()) +
  labs(x = "time since infection (days)", y = "viral load (log scale)",
       colour = "immunity at infection",
       title = "By immunity at infection, potential peak 1")

peak_by_level_and_immunity <- ggplot(peaks,
                                     aes(potential_peak_viral_load,
                                         immunity_at_infection,
                                         fill = log10(peak_viral_load))) +
  geom_raster() +
  scale_x_log10(labels = scales::label_number()) +
  scale_fill_viral_load() +
  labs(x = "potential peak viral load (log scale)", y = "immunity at infection",
       fill = "peak viral\nload (log10)",
       title = "Peak viral load by potential peak and immunity") +
  theme(legend.position = "right")

figure <- by_level_and_width / (by_immunity + peak_by_level_and_immunity) +
  plot_annotation(title = "Viral load",
                  caption = paste(
                    "Dashed: recovery threshold. Potential peak viral loads",
                    "0.14, 1 and 7.1 are the 2.5%, 50% and 97.5% quantiles",
                    "of their distribution."
                  ))
save_figure(figure, "viral_load", width = 10, height = 8)
