# immunity over time for an individual infected three times, with the
# model's infection(), recovery() and advance_individuals_one_timestep(),
# for several waning rates

source("reports/helpers.R")

waning_rates <- c(0.005, 0.01, 0.02)
infection_days <- c(0, 120, 160)
boost_sizes <- c(2, 1, 1.5)

rows <- list()
for (rate in waning_rates) {
  set_values(settings = list(),
             parameters = list(immunity_waning_rate = rate))
  individual <- simulate_new_individual(household_index = 1)
  for (day in 0:400) {
    if (day %in% infection_days) {
      boost <- boost_sizes[match(day, infection_days)]
      individual <- recovery(individual)
      individual <- infection(individual, list(viral_load_level = 1,
                                               boost_size = boost))
    }
    rows[[length(rows) + 1]] <- data.frame(
      waning_rate = rate, day = day,
      immunity_level = individual$immunity_level
    )
    individual <- advance_individuals_one_timestep(list(individual))[[1]]
  }
}

write_draws(do.call(rbind, rows), "immunity")
