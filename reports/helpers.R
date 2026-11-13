# helpers for the scripts in reports/draws/, which run the model and save
# the results that the scripts in reports/figures/ plot. Run every script
# from the root of the repository.

source("model/infrastructure/load_model.R")

# run the model for a number of replicates in parallel, with the default
# settings and parameters except those given, and return the epidemics
# stacked in one data frame with a replicate column. Each replicate has its
# own random number stream from the seed, so results do not depend on the
# number of cores.
run_replicates <- function(settings, parameters, replicates, seed) {
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  streams <- list()
  stream <- .Random.seed
  for (replicate in seq_len(replicates)) {
    streams[[replicate]] <- stream
    stream <- parallel::nextRNGStream(stream)
  }
  epidemics <- parallel::mclapply(seq_len(replicates), function(replicate) {
    # use this replicate's stream; .Random.seed is R's name, not ours
    assign(".Random.seed", streams[[replicate]], # nolint: object_name_linter.
           envir = globalenv())
    epidemic <- run_model(settings, parameters)$epidemic
    epidemic$replicate <- replicate
    epidemic
  }, mc.cores = parallel::detectCores())
  do.call(rbind, epidemics)
}

# save results for a figure as reports/draws/<name>.csv
write_draws <- function(draws, name) {
  write.csv(draws, file.path("reports", "draws", paste0(name, ".csv")),
            row.names = FALSE)
}
