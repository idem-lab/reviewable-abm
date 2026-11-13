# viral load levels and immunity boost sizes drawn with the model's
# random_infection_characteristics(), for several correlations, with the
# quantities they set: the peak viral load of an infection with no
# immunity, the relative susceptibility just after the boost, and the days
# until the boost has waned (boost size / waning rate, from eq-immunity)

source("reports/helpers.R")

set.seed(1)
rows <- list()
for (correlation in c(0, 0.5, 0.9)) {
  set_values(settings = list(),
             parameters = list(viral_load_boost_correlation = correlation))
  for (draw in seq_len(2000)) {
    characteristics <- random_infection_characteristics()
    individual <- infection(individual_with(age = 30), characteristics)
    individual$time_since_infection <-
      default_parameters$viral_load_peak_time
    rows[[length(rows) + 1]] <- data.frame(
      correlation = correlation,
      viral_load_level = characteristics$viral_load_level,
      boost_size = characteristics$boost_size,
      peak_viral_load = viral_load(individual),
      relative_susceptibility_after_boost = exp(
        susceptibility_score(individual)
      ),
      days_until_waned = characteristics$boost_size /
        default_parameters$immunity_waning_rate
    )
  }
}
write_draws(do.call(rbind, rows), "infection_characteristics")
