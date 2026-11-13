# relative infectiousness and relative susceptibility (the hazard ratios
# exp(infectiousness score) and exp(susceptibility score)), from the
# model's infectiousness_score() and susceptibility_score(), over viral
# load, age and immunity level

source("reports/helpers.R")

set_values(settings = list(), parameters = list())

infectiousness <- list()
for (viral_load in 10 ^ seq(-3, 1, by = 0.05)) {
  for (age in seq(0, 80, by = 1)) {
    individual <- individual_with(age = age, infected = TRUE,
                                  viral_load = viral_load)
    infectiousness[[length(infectiousness) + 1]] <- data.frame(
      viral_load = viral_load, age = age,
      relative_infectiousness = exp(infectiousness_score(individual))
    )
  }
}
write_draws(do.call(rbind, infectiousness), "infectiousness")

susceptibility <- list()
for (immunity_level in seq(0, 4, by = 0.05)) {
  for (age in seq(0, 80, by = 1)) {
    individual <- individual_with(age = age, immunity_level = immunity_level)
    susceptibility[[length(susceptibility) + 1]] <- data.frame(
      immunity_level = immunity_level, age = age,
      relative_susceptibility = exp(susceptibility_score(individual))
    )
  }
}
write_draws(do.call(rbind, susceptibility), "susceptibility")
