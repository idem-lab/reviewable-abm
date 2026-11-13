# whole-model epidemics: replicate simulations at the default parameter
# values, in a population of 300

source("reports/helpers.R")

draws <- run_replicates(settings = list(population_size = 300),
                        parameters = list(), replicates = 32, seed = 1)
write_draws(draws, "epidemics")
