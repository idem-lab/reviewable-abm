# viral load levels and immunity boost sizes drawn with the model's
# random_infection_characteristics(), for several correlations

source("reports/helpers.R")

correlations <- c(0, 0.5, 0.9)
set.seed(1)

rows <- list()
for (correlation in correlations) {
  set_values(settings = list(),
             parameters = list(viral_load_boost_correlation = correlation))
  for (draw in seq_len(2000)) {
    characteristics <- random_infection_characteristics()
    rows[[length(rows) + 1]] <- data.frame(
      correlation = correlation,
      viral_load_level = characteristics$viral_load_level,
      boost_size = characteristics$boost_size
    )
  }
}

write_draws(do.call(rbind, rows), "infection_characteristics")
