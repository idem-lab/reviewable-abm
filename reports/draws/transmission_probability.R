# transmission probability from the model's transmission_probability(),
# against contact event duration, for several infector viral loads, in and
# out of the household, between two adults with no immunity

source("reports/helpers.R")

set_values(settings = list(), parameters = list())
viral_loads <- c(0.1, 0.5, 1)
durations <- seq(0, 24, by = 0.25)

rows <- list()
for (load in viral_loads) {
  infector <- simulate_new_individual(1)
  infector$age <- 30
  infector$infected <- TRUE
  infector$viral_load <- load
  infectee <- simulate_new_individual(1)
  infectee$age <- 30
  for (in_household in c(TRUE, FALSE)) {
    for (duration in durations) {
      event <- contact_event(c(1, 2), in_household, duration)
      rows[[length(rows) + 1]] <- data.frame(
        viral_load = load, in_household = in_household,
        duration = duration,
        probability = transmission_probability(infector, infectee, event)
      )
    }
  }
}

write_draws(do.call(rbind, rows), "transmission_probability")
