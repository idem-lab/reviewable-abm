# immunity level and relative susceptibility, from the model's
# infection(), immunity_level() and susceptibility_score(), over time since
# a boost, for several boost sizes and waning rates, and for an individual
# infected three times

source("reports/helpers.R")

rows <- list()
for (rate in c(0.005, 0.01, 0.02)) {
  set_values(settings = list(),
             parameters = list(immunity_waning_rate = rate))
  for (boost in c(0.5, 1, 2, 4)) {
    individual <- infection(individual_with(age = 30),
                            list(potential_peak_viral_load = 1,
                                 boost_size = boost))
    for (day in 0:600) {
      # timesteps of 1 day
      individual$timesteps_since_boost <- day
      individual$immunity_level <- immunity_level(individual)
      rows[[length(rows) + 1]] <- data.frame(
        waning_rate = rate, boost_size = boost, time_since_boost = day,
        immunity_level = individual$immunity_level,
        relative_susceptibility = exp(susceptibility_score(individual))
      )
    }
  }
}
write_draws(do.call(rbind, rows), "immunity_over_time")

# one individual infected on days 0, 120 and 160, advanced a day at a time
infection_days <- c(0, 120, 160)
boost_sizes <- c(2, 1, 1.5)
repeated <- list()
for (rate in c(0.005, 0.01, 0.02)) {
  set_values(settings = list(),
             parameters = list(immunity_waning_rate = rate))
  individual <- individual_with(age = 30)
  for (day in 0:400) {
    if (day %in% infection_days) {
      boost <- boost_sizes[match(day, infection_days)]
      individual <- infection(recovery(individual),
                              list(potential_peak_viral_load = 1,
                                   boost_size = boost))
    }
    repeated[[length(repeated) + 1]] <- data.frame(
      waning_rate = rate, day = day,
      immunity_level = individual$immunity_level
    )
    individual <- advance_individuals_one_timestep(list(individual))[[1]]
  }
}
write_draws(do.call(rbind, repeated), "repeated_infections")
