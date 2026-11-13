# duration of infection: individuals are infected and advanced one timestep
# at a time with the model's functions until they recover, for a range of
# potential peak viral loads and immunity at infection, alongside the
# duration from the equation in maths.md

source("reports/helpers.R")

set_values(settings = list(timestep_length = 0.1), parameters = list())
potential_peak_viral_loads <- exp(seq(log(0.001), log(20), length.out = 40))
immunity_levels <- c(0, 2, 5, 10)

peak_time <- default_parameters$viral_load_peak_time
width <- default_parameters$viral_load_profile_width
effect <- default_parameters$viral_load_immunity_effect
threshold <- default_settings$recovery_viral_load_threshold

rows <- list()
for (immunity in immunity_levels) {
  for (level in potential_peak_viral_loads) {
    individual <- simulate_new_individual(1)
    individual$immunity_level <- immunity
    individual <- infection(individual, list(potential_peak_viral_load = level,
                                             boost_size = 1))
    individual <- advance_individuals_one_timestep(list(individual))[[1]]
    while (!ready_to_recover(individual)) {
      individual <- advance_individuals_one_timestep(list(individual))[[1]]
    }
    # the duration from the equation in maths.md (eq-duration)
    scale <- level * exp(-effect * immunity)
    equation <- peak_time
    if (scale > threshold) {
      equation <- peak_time * exp(width * sqrt(2 * log(scale / threshold)))
    }
    rows[[length(rows) + 1]] <- data.frame(
      immunity_at_infection = immunity,
      potential_peak_viral_load = level,
      simulated_duration = time_since_infection(individual),
      equation_duration = equation
    )
  }
}

write_draws(do.call(rbind, rows), "duration_of_infection")
