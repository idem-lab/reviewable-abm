# the households and individuals at the start of the simulation (maths.md:
# Population)

# households of random sizes, filled in turn with consecutive individuals
# until everyone has a household; the last household is cut short to fit the
# population
simulate_households <- function() {

  load_settings("population_size", "average_household_size")

  households <- list()
  number_assigned <- 0
  while (number_assigned < population_size) {
    # every household has at least one member
    household_size <- 1 + random_poisson(average_household_size - 1)
    # the indices of the next household_size individuals, cut short if they
    # would overfill the population
    first_index <- number_assigned + 1
    last_index <- min(number_assigned + household_size, population_size)
    h <- length(households) + 1
    households[[h]] <- list(member_indices = seq(first_index, last_index))
    number_assigned <- last_index
  }

  households

}

# the individuals at the start of the simulation, in their households, with
# random ages, some of whom are infected at random
simulate_initial_population <- function(households) {

  load_settings("initial_infections")

  # each individual and their household record each other's indices
  population <- list()
  for (h in seq_along(households)) {
    household <- households[[h]]
    for (i in household$member_indices) {
      population[[i]] <- simulate_new_individual(household_index = h)
    }
  }

  initially_infected_indices <- random_individual_indices(population,
                                                          initial_infections)
  for (i in initially_infected_indices) {
    individual <- population[[i]]
    infection_characteristics <- random_infection_characteristics()
    population[[i]] <- infection(individual, infection_characteristics)
  }

  population

}

# a new individual with a random age, who has never been infected and has no
# immunity; the quantities describing infections and boosts are undefined
# (NA) until the first infection
simulate_new_individual <- function(household_index) {

  load_settings("maximum_initial_age")

  list(
    household_index = household_index,
    age = random_uniform(0, maximum_initial_age), # years
    infected = FALSE,
    timesteps_since_infection = NA,
    timesteps_since_boost = NA,
    potential_peak_viral_load = NA,
    viral_load = 0,
    immunity_level = 0,
    immunity_after_boost = NA,
    immunity_at_infection = NA,
    boost_size = NA
  )

}

# whether an individual of this age, in years, is a child
is_child <- function(age) {

  load_settings("adult_age")

  age < adult_age

}
