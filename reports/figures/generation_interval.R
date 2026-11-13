# Expected: the viral load profile, scaled to integrate to 1, is the same
# curve as a lognormal density with meanlog log(peak time) + width^2 and
# sdlog equal to the width (maths.md, eq-generation-interval), so the two
# lines overlap exactly. Because the density is proportional to viral load,
# the intrinsic generation interval peaks at the viral load peak time
# (4 days), and its right tail lengthens as the width increases.

source("reports/theme.R")

draws <- read_draws("generation_interval")

figure <- ggplot(draws, aes(time_since_infection)) +
  geom_line(aes(y = from_profile, colour = "viral load profile, scaled"),
            linewidth = 1.6, alpha = 0.5) +
  geom_line(aes(y = lognormal, colour = "lognormal density"),
            linetype = "dashed") +
  facet_wrap(~ paste("profile width", profile_width)) +
  labs(x = "time since infection (days)", y = "density", colour = NULL,
       title = "The intrinsic generation interval is lognormal")

save_figure(figure, "generation_interval")
