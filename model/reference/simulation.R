# the main simulation loop (maths.md: Time)

# simulate the model for a number of timesteps, returning the number of new
# infections and the number infected in each timestep
random_simulation <- function(number_of_timesteps) {

  population <- random_initial_population()

  simulation <- data.frame(
    time = rep(NA, number_of_timesteps),
    new_infections = rep(NA, number_of_timesteps),
    infected = rep(NA, number_of_timesteps)
  )

  for (timestep in seq_len(number_of_timesteps)) {

    set_clock_to_timestep(timestep)

    # 1. contact events, which may transmit infection
    contact_events <- random_contact_events(population)
    population <- random_transmissions(population, contact_events)
    new_infections <- number_newly_infected(population)

    # 2. recovery
    population <- recover_individuals(population)

    # 3. ages, elapsed times and levels
    population <- advance_individuals_one_timestep(population)

    simulation$time[timestep] <- current_time()
    simulation$new_infections[timestep] <- new_infections
    simulation$infected[timestep] <- number_infected(population)

  }

  simulation

}

# number of individuals infected in the current timestep, whose time since
# infection has not yet advanced; in the first timestep this includes the
# initial infections
number_newly_infected <- function(population) {

  number_newly_infected <- 0
  for (i in seq_along(population)) {
    individual <- population[[i]]
    if (individual$infected && individual$time_since_infection == 0) {
      number_newly_infected <- number_newly_infected + 1
    }
  }

  number_newly_infected

}

# number of individuals currently infected
number_infected <- function(population) {

  number_infected <- 0
  for (i in seq_along(population)) {
    individual <- population[[i]]
    if (individual$infected) {
      number_infected <- number_infected + 1
    }
  }

  number_infected

}
