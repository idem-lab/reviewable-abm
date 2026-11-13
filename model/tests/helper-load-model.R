# load the reference implementation and its infrastructure, from the root of
# the repository, and provide helpers for setting up tests

repository_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
local({
  old <- setwd(repository_root)
  on.exit(setwd(old))
  source("model/infrastructure/load_model.R", local = FALSE)
})

# use the default settings and parameters, except those given
use_values <- function(settings = list(), parameters = list()) {
  set_values(settings, parameters)
}

# an individual with the given characteristics, starting from a new
# individual who has never been infected
make_individual <- function(...) {
  individual <- simulate_new_individual(household_index = 1)
  changes <- list(...)
  for (name in names(changes)) {
    individual[[name]] <- changes[[name]]
  }
  individual
}

# an individual infected now, with the given characteristics of the
# infection and immunity beforehand
make_infected_individual <- function(viral_load_level = 1, boost_size = 1,
                                     immunity_level = 0, age = 30) {
  individual <- make_individual(age = age, immunity_level = immunity_level)
  infection(individual, list(viral_load_level = viral_load_level,
                             boost_size = boost_size))
}

# a contact event between individuals 1 and 2
make_contact_event <- function(in_household = FALSE, duration = 1) {
  contact_event(individual_indices = c(1, 2), in_household = in_household,
                duration = duration)
}
