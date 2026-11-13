# whole-model sensitivity: infections per person and the time of the peak
# number infected, in replicate simulations as one parameter at a time
# changes from its default, in a population of 300

source("reports/helpers.R")

changes <- list(
  immunity_waning_rate = c(0.005, 0.01, 0.02, 0.04),
  household_location_score = c(0, 0.7, 1.4),
  viral_load_profile_width = c(0.3, 0.4, 0.55),
  viral_load_boost_correlation = c(0, 0.5, 0.9)
)
population_size <- 300

rows <- list()
seed <- 0
for (parameter_name in names(changes)) {
  for (value in changes[[parameter_name]]) {
    seed <- seed + 1
    parameters <- list()
    parameters[[parameter_name]] <- value
    epidemics <- run_replicates(
      settings = list(population_size = population_size),
      parameters = parameters, replicates = 24, seed = seed
    )
    for (replicate in unique(epidemics$replicate)) {
      epidemic <- epidemics[epidemics$replicate == replicate, ]
      rows[[length(rows) + 1]] <- data.frame(
        parameter = parameter_name,
        value = value,
        is_default = value == default_parameters[[parameter_name]],
        replicate = replicate,
        infections_per_person =
          sum(epidemic$new_infections) / population_size,
        peak_time = epidemic$time[which.max(epidemic$infected)]
      )
    }
  }
}

write_draws(do.call(rbind, rows), "sensitivity")
