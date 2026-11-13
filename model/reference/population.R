# the population at the start of the simulation (maths.md: Population)

# individuals in households of random sizes, with random ages, some of
# whom are infected at random
simulate_initial_population <- function() {

  population_size <- setting("population_size")
  household_indices <- simulate_household_indices(population_size)

  population <- list()
  for (i in seq_len(population_size)) {
    population[[i]] <- simulate_new_individual(household_indices[i])
  }

  initially_infected_indices <- random_individual_indices(
    population, setting("initial_infections")
  )
  for (i in initially_infected_indices) {
    individual <- population[[i]]
    infection_characteristics <- random_infection_characteristics()
    population[[i]] <- infection(individual, infection_characteristics)
  }

  population

}

# the household index of each individual: households of random sizes are
# filled in turn until everyone has a household, and the last household is
# cut short to fit the population
simulate_household_indices <- function(population_size) {

  household_indices <- c()
  h <- 0
  while (length(household_indices) < population_size) {
    h <- h + 1
    # every household has at least one member
    household_size <- 1 + random_poisson(setting("average_household_size") - 1)
    household_indices <- c(household_indices, rep(h, household_size))
  }

  household_indices <- household_indices[seq_len(population_size)]

  household_indices

}

# a new individual with a random age, who has never been infected and has no
# immunity; the quantities describing infections and boosts are undefined
# (NA) until the first infection
simulate_new_individual <- function(household_index) {

  new_individual <- list(
    household_index = household_index,
    age = random_uniform(0, setting("maximum_initial_age")), # years
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

  new_individual

}

# whether an individual is a child
is_child <- function(individual) {

  individual$age < setting("adult_age")

}
