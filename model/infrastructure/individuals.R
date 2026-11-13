# infrastructure, not part of the model: an individual with chosen
# characteristics, for tests and figures that look at one process at a
# time

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
