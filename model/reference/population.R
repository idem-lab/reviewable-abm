# the population at the start of the simulation (maths.md: Population)

# individuals in households of equal size, with random ages, some of whom
# are infected at random
random_initial_population <- function() {

  population_size <- setting("population_size")
  stopifnot(population_size %% setting("household_size") == 0)

  population <- list()
  for (i in seq_len(population_size)) {
    population[[i]] <- random_uninfected_individual(i)
  }

  initially_infected_indices <- random_individual_indices(
    population, setting("initial_infections")
  )
  for (i in initially_infected_indices) {
    individual <- population[[i]]
    population[[i]] <- random_infection(individual)
  }

  population

}

# a new individual with a random age, who has never been infected
random_uninfected_individual <- function(individual_index) {

  age <- runif(1, min = 0, max = setting("maximum_initial_age"))
  uninfected_individual(individual_index, age)

}

# a new individual who has never been infected and has no immunity; the
# quantities describing infections and boosts are undefined (NA) until the
# first infection
uninfected_individual <- function(individual_index, age) {

  list(
    household_index = household_index(individual_index),
    age = age, # years
    infected = FALSE,
    time_since_infection = NA, # days
    time_since_boost = NA, # days
    viral_load_level = NA,
    viral_load = 0,
    immunity_level = 0,
    immunity_after_boost = NA,
    immunity_at_infection = NA,
    boost_size = NA
  )

}

# index of the household of an individual: households are made of
# consecutive individuals
household_index <- function(individual_index) {

  ceiling(individual_index / setting("household_size"))

}

# whether an individual is a child
is_child <- function(individual) {

  individual$age < setting("adult_age")

}
