# Expected: the probability of transmission in one contact event is
# 1 - exp(-hazard x duration). It rises almost linearly with duration while
# hazard x duration is small, then levels off towards 1; at the default
# hazards most contact events are in the near-linear range. Household
# contact events have exp(0.7), about 2 times, the hazard, so a household
# contact event at one viral load matches a non-household one at twice that
# viral load. Probability rises with infector viral load (nearly in
# proportion while small) and falls with infectee immunity (by about
# exp(-immunity) while small); child infectees have lower probability at
# every immunity level. Viral load and immunity act multiplicatively on the
# hazard, so in the bottom-right panel lines of equal probability are
# straight, with viral load needing to rise by a factor e for each unit of
# immunity.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("transmission_probability")
draws$location <- ifelse(draws$in_household, "household", "non-household")
adult_no_immunity <- draws[draws$age_group == "adult" &
                             draws$immunity_level == 0, ]
typical_duration <- ifelse(draws$in_household, draws$household_hours,
                           draws$non_household_hours)
typical <- draws[draws$duration == typical_duration, ]

# the 2.5%, 50% and 97.5% quantiles of the viral load level
shown_loads <- adult_no_immunity$typical_level
by_duration <- ggplot(adult_no_immunity[shown_loads, ],
                      aes(duration, probability,
                          colour = factor(signif(viral_load, 2)),
                          linetype = location)) +
  geom_line() +
  scale_colour_viral_load() +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "contact event duration (hours)", y = "probability",
       colour = "viral load", linetype = NULL,
       title = "By duration")

by_viral_load <- ggplot(typical[typical$age_group == "adult" &
                                  typical$immunity_level == 0 &
                                  typical$on_grid, ],
                        aes(viral_load, probability, colour = location)) +
  geom_line() +
  scale_colour_location() +
  scale_x_log10(labels = scales::label_number()) +
  labs(x = "infector viral load (log scale)", y = "probability",
       colour = NULL, title = "By viral load, for a day's contact")

by_immunity <- ggplot(typical[typical$in_household &
                                abs(typical$viral_load - 1) < 1e-9, ],
                      aes(immunity_level, probability,
                          colour = age_group)) +
  geom_line() +
  scale_colour_age_group() +
  labs(x = "infectee immunity level", y = "probability",
       colour = "infector and infectee",
       title = "By immunity, household, viral load 1")

by_viral_load_and_immunity <- ggplot(
  typical[typical$in_household & typical$age_group == "adult" &
            typical$on_grid, ],
  aes(viral_load, immunity_level, fill = probability)
) +
  geom_raster() +
  scale_x_log10(labels = scales::label_number()) +
  scale_fill_viridis_c(limits = c(0, 1)) +
  labs(x = "infector viral load (log scale)",
       y = "infectee immunity level", fill = "probability",
       title = "By viral load and immunity, household") +
  theme(legend.position = "right")

figure <- (by_duration + by_viral_load) /
  (by_immunity + by_viral_load_and_immunity) +
  plot_annotation(
    title = "Probability of transmission in one contact event",
    caption = paste(
      "Adults with no infectee immunity unless shown. A day's contact:",
      "6 hours in a household, 0.5 hours elsewhere.\nViral loads 0.14,",
      "1 and 7.1 are the 2.5%, 50% and 97.5% quantiles of the viral load",
      "level."
    )
  )
save_figure(figure, "transmission_probability", width = 10, height = 8)
