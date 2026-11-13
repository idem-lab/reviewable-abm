# helpers for the scripts in reports/draws/, which run the model and save
# the results that the scripts in reports/figures/ plot. Run every script
# from the root of the repository.

source("model/infrastructure/load_model.R")

# apply a function to each of 1, ..., n in parallel, giving each its own
# random number stream from the seed, so results do not depend on the
# number of cores; returns a list of the results
run_in_parallel <- function(n, simulate_one, seed) {
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  streams <- list()
  stream <- .Random.seed
  for (index in seq_len(n)) {
    streams[[index]] <- stream
    stream <- parallel::nextRNGStream(stream)
  }
  parallel::mclapply(seq_len(n), function(index) {
    # use this run's stream; .Random.seed is R's name, not ours
    assign(".Random.seed", streams[[index]], # nolint: object_name_linter.
           envir = globalenv())
    simulate_one(index)
  }, mc.cores = parallel::detectCores())
}

# run the model for a number of replicates in parallel, with the default
# settings and parameters except those given, and return the epidemics
# stacked in one data frame with a replicate column, and prevalence as the
# proportion of the population infected
run_replicates <- function(settings, parameters, replicates, seed) {
  epidemics <- run_in_parallel(replicates, function(replicate) {
    result <- run_model(settings, parameters)
    epidemic <- result$epidemic
    epidemic$prevalence <- epidemic$infected / result$settings$population_size
    epidemic$replicate <- replicate
    epidemic
  }, seed = seed)
  do.call(rbind, epidemics)
}

# an individual with the given characteristics, starting from a new
# individual who has never been infected
individual_with <- function(...) {
  individual <- simulate_new_individual(household_index = 1)
  changes <- list(...)
  for (name in names(changes)) {
    individual[[name]] <- changes[[name]]
  }
  individual
}

# the 2.5%, 50% and 97.5% quantiles of the viral load level at the default
# parameter values, used wherever a figure shows a few viral load levels
typical_viral_load_levels <- function() {
  signif(qlnorm(c(0.025, 0.5, 0.975), meanlog = 0,
                sdlog = default_parameters$viral_load_level_sdlog), 2)
}

# save results for a figure as reports/draws/<name>.csv
write_draws <- function(draws, name) {
  write.csv(draws, file.path("reports", "draws", paste0(name, ".csv")),
            row.names = FALSE)
}
