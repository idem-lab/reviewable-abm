# whole-model resurgence: replicate simulations over two years in a
# population of 2000, with transmission lowered from the defaults (8
# non-household contact events per person per day and 3 hours of household
# contact per day) so that the first wave leaves enough people uninfected
# for infection to persist, comparing immunity that does not wane with
# immunity that wanes at 0.04 per day (faster than the default, so that a
# second wave can happen within the simulation)

source("reports/helpers.R")

rows <- list()
for (rate in c(0, 0.04)) {
  epidemics <- run_replicates(
    settings = list(population_size = 2000, number_of_timesteps = 730,
                    initial_infections = 20),
    parameters = list(
      immunity_waning_rate = rate,
      non_household_contact_events_per_person_per_day = 8,
      household_contact_event_hours_per_day = 3
    ),
    replicates = 16, seed = 1
  )
  epidemics$immunity_waning_rate <- rate
  rows[[length(rows) + 1]] <- epidemics
}
write_draws(do.call(rbind, rows), "resurgence")
