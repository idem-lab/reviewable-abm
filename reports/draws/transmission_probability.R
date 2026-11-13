# the probability of transmission during one contact event, from the
# model's transmission_probability(), over contact event duration and
# location, infector viral load and age, and infectee immunity and age

source("reports/helpers.R")

set_values(settings = list(), parameters = list())

# a grid of viral loads from 0.1 to 10, plus the typical viral load levels
viral_load_grid <- 10 ^ seq(-1, 1, by = 0.1)
viral_loads <- unique(c(viral_load_grid, typical_viral_load_levels()))

rows <- list()
for (in_household in c(TRUE, FALSE)) {
  for (duration in seq(0, 24, by = 0.5)) {
    for (viral_load in viral_loads) {
      for (immunity_level in seq(0, 4, by = 0.25)) {
        for (age_group in c("adult", "child")) {
          age <- if (age_group == "adult") 30 else 10
          infector <- individual_with(age = age, infected = TRUE,
                                      viral_load = viral_load)
          infectee <- individual_with(age = age,
                                      immunity_level = immunity_level)
          event <- contact_event(c(1, 2), in_household, duration)
          rows[[length(rows) + 1]] <- data.frame(
            in_household = in_household, duration = duration,
            viral_load = viral_load, immunity_level = immunity_level,
            age_group = age_group,
            probability = transmission_probability(infector, infectee,
                                                   event)
          )
        }
      }
    }
  }
}

draws <- do.call(rbind, rows)
draws$household_hours <-
  default_parameters$household_contact_event_hours_per_day
draws$non_household_hours <-
  default_parameters$non_household_contact_event_hours_per_day
draws$typical_level <- draws$viral_load %in% typical_viral_load_levels()
draws$on_grid <- draws$viral_load %in% viral_load_grid
write_draws(draws, "transmission_probability")
