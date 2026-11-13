# whole-model extinction: the infections per person over a simulation, in
# replicate simulations across a range of baseline transmission hazards
# around the threshold for epidemics to take off, in a population of 300

source("reports/helpers.R")

hazards <- c(0.001, 0.002, 0.003, 0.004, 0.006, 0.008, 0.011, 0.015)
population_size <- 300

rows <- list()
for (h in seq_along(hazards)) {
  epidemics <- run_replicates(
    settings = list(population_size = population_size),
    parameters = list(baseline_transmission_hazard = hazards[h]),
    replicates = 64, seed = h
  )
  for (replicate in unique(epidemics$replicate)) {
    epidemic <- epidemics[epidemics$replicate == replicate, ]
    rows[[length(rows) + 1]] <- data.frame(
      baseline_transmission_hazard = hazards[h],
      replicate = replicate,
      infections_per_person = sum(epidemic$new_infections) / population_size
    )
  }
}

write_draws(do.call(rbind, rows), "extinction")
