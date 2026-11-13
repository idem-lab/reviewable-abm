# helpers for the scripts in reports/draws/, which run the model and save
# the results that the scripts in reports/figures/ plot. Run every script
# from the root of the repository.

source("model/infrastructure/load_model.R")

# apply a function to each of 1, ..., n in parallel, giving each its own
# random number stream from the seed, so results do not depend on the
# number of cores; returns a list of the results, and stops if any run
# failed. Runs in parallel only where R can fork processes (not Windows).
run_in_parallel <- function(n, simulate_one, seed) {
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  streams <- list()
  stream <- .Random.seed
  for (index in seq_len(n)) {
    streams[[index]] <- stream
    stream <- parallel::nextRNGStream(stream)
  }
  cores <- if (.Platform$OS.type == "windows") 1 else parallel::detectCores()
  results <- parallel::mclapply(seq_len(n), function(index) {
    # use this run's stream; .Random.seed is R's name, not ours
    assign(".Random.seed", streams[[index]], # nolint: object_name_linter.
           envir = globalenv())
    simulate_one(index)
  }, mc.cores = cores)
  # a run that fails returns its error rather than stopping
  for (result in results) {
    if (inherits(result, "try-error")) {
      stop("a simulation failed: ", result)
    }
  }
  results
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

# the 2.5%, 50% and 97.5% quantiles of the potential peak viral load at the
# default parameter values, used wherever a figure shows a few of them
typical_potential_peak_viral_loads <- function() {
  signif(qlnorm(c(0.025, 0.5, 0.975), meanlog = 0,
                sdlog = default_parameters$potential_peak_viral_load_sdlog), 2)
}

# save results for a figure as reports/draws/<name>.csv
write_draws <- function(draws, name) {
  write.csv(draws, file.path("reports", "draws", paste0(name, ".csv")),
            row.names = FALSE)
}
