# Expected: infections last longer with higher potential peak viral loads and
# shorter with more immunity at infection, and the durations found by
# running the model's functions match the equation in maths.md
# (eq-duration) to within one timestep (0.1 days here). Infections whose
# viral load never reaches the recovery threshold end at the peak time
# (4 days).

source("reports/theme.R")

draws <- read_draws("duration_of_infection")

figure <- ggplot(draws, aes(potential_peak_viral_load,
                            colour = factor(immunity_at_infection))) +
  geom_line(aes(y = equation_duration)) +
  geom_point(aes(y = simulated_duration), size = 1.2) +
  scale_colour_immunity() +
  scale_x_log10(labels = scales::label_number()) +
  labs(x = "potential peak viral load (log scale)",
       y = "duration of infection (days)",
       colour = "immunity at infection",
       title = "Duration of infection",
       caption = paste("Points: model functions, in timesteps of 0.1 days.",
                       "Lines: maths.md, eq-duration."))

save_figure(figure, "duration_of_infection")
