# whole-model resurgence: replicate simulations over two years in a
# population of 300, with immunity that does not wane and with immunity
# that wanes at 0.02 per day (faster than the default, so that a second
# wave can happen within the simulation)

source("reports/helpers.R")

rows <- list()
for (rate in c(0, 0.02)) {
  epidemics <- run_replicates(
    settings = list(population_size = 300, number_of_timesteps = 730),
    parameters = list(immunity_waning_rate = rate),
    replicates = 24, seed = 1
  )
  epidemics$immunity_waning_rate <- rate
  rows[[length(rows) + 1]] <- epidemics
}
write_draws(do.call(rbind, rows), "resurgence")
