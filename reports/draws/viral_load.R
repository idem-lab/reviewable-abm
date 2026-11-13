# viral load from the model's viral_load(), over time since infection,
# viral load level, profile width and immunity at infection

source("reports/helpers.R")

rows <- list()
for (width in c(0.3, 0.4, 0.55)) {
  set_values(settings = list(),
             parameters = list(viral_load_profile_width = width))
  for (level in c(0.5, 1, 2)) {
    for (immunity in c(0, 2, 4)) {
      individual <- infection(individual_with(immunity_level = immunity),
                              list(viral_load_level = level,
                                   boost_size = 1))
      for (time in seq(0.1, 40, by = 0.1)) {
        individual$time_since_infection <- time
        rows[[length(rows) + 1]] <- data.frame(
          profile_width = width, viral_load_level = level,
          immunity_at_infection = immunity, time_since_infection = time,
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

# peak viral load over viral load level and immunity at infection
set_values(settings = list(), parameters = list())
peaks <- list()
for (level in 10 ^ seq(-2, 1.3, by = 0.05)) {
  for (immunity in seq(0, 8, by = 0.1)) {
    individual <- infection(individual_with(immunity_level = immunity),
                            list(viral_load_level = level, boost_size = 1))
    individual$time_since_infection <-
      default_parameters$viral_load_peak_time
    peaks[[length(peaks) + 1]] <- data.frame(
      viral_load_level = level, immunity_at_infection = immunity,
      peak_viral_load = viral_load(individual)
    )
  }
}
write_draws(do.call(rbind, peaks), "peak_viral_load")
