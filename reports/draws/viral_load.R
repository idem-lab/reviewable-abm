# viral load over time since infection, from the model's viral_load(), for
# several profile widths and viral load levels, with no immunity

source("reports/helpers.R")

profile_widths <- c(0.3, 0.4, 0.55)
viral_load_levels <- c(0.5, 1, 2)
times_since_infection <- seq(0, 40, by = 0.1)

rows <- list()
for (width in profile_widths) {
  set_values(settings = list(),
             parameters = list(viral_load_profile_width = width))
  for (level in viral_load_levels) {
    individual <- infection(simulate_new_individual(household_index = 1),
                            list(viral_load_level = level, boost_size = 1))
    for (time in times_since_infection) {
      individual$time_since_infection <- time
      rows[[length(rows) + 1]] <- data.frame(
        profile_width = width,
        viral_load_level = level,
        time_since_infection = time,
        viral_load = viral_load(individual)
      )
    }
  }
}

draws <- do.call(rbind, rows)
draws$recovery_threshold <- default_settings$recovery_viral_load_threshold
draws$peak_time <- default_parameters$viral_load_peak_time
write_draws(draws, "viral_load")
