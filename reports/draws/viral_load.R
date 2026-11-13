# viral load from the model's viral_load(), over time since infection (in
# timesteps of 0.1 days), potential peak viral load, profile width and
# immunity at infection

source("reports/helpers.R")

rows <- list()
for (width in c(0.3, 0.4, 0.55)) {
  set_values(settings = list(timestep_length = 0.1),
             parameters = list(viral_load_profile_width = width))
  for (level in typical_potential_peak_viral_loads()) {
    for (immunity in c(0, 2, 4)) {
      individual <- infection(individual_with(immunity_level = immunity),
                              list(potential_peak_viral_load = level,
                                   boost_size = 1))
      for (timesteps in seq_len(400)) {
        individual$timesteps_since_infection <- timesteps
        rows[[length(rows) + 1]] <- data.frame(
          profile_width = width, potential_peak_viral_load = level,
          immunity_at_infection = immunity,
          time_since_infection = time_since_infection(individual),
          viral_load = viral_load(individual)
        )
      }
    }
  }
}
draws <- do.call(rbind, rows)
draws$recovery_threshold <- default_settings$recovery_viral_load_threshold
draws$peak_time <- default_parameters$viral_load_peak_time
draws$default_width <- default_parameters$viral_load_profile_width
write_draws(draws, "viral_load")

# peak viral load over potential peak viral load and immunity at infection
set_values(settings = list(), parameters = list())
peaks <- list()
for (level in 10 ^ seq(-1, 1, by = 0.025)) {
  for (immunity in seq(0, 8, by = 0.1)) {
    individual <- infection(individual_with(immunity_level = immunity),
                            list(potential_peak_viral_load = level,
                                 boost_size = 1))
    peaks[[length(peaks) + 1]] <- data.frame(
      potential_peak_viral_load = level, immunity_at_infection = immunity,
      peak_viral_load = peak_viral_load(individual)
    )
  }
}
write_draws(do.call(rbind, peaks), "peak_viral_load")
