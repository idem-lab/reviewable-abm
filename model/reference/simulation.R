# the main simulation loop (maths.md: Time)

# simulate the model for the set number of timesteps, returning the number
# of new infections and the number infected in each timestep
simulate_epidemic <- function() {

  load_settings("number_of_timesteps")

  households <- simulate_households()
  population <- simulate_initial_population(households)

  epidemic <- data.frame(
    time = rep(NA, number_of_timesteps),
    new_infections = rep(NA, number_of_timesteps),
    infected = rep(NA, number_of_timesteps)
  )

  for (timestep in seq_len(number_of_timesteps)) {

    set_clock_to_timestep(timestep)

    # 1. contact events, which may transmit infection
    contact_events <- simulate_contact_events(population, households)
    population <- simulate_transmissions(population, contact_events)

    # 2. recovery
    population <- recover_individuals(population)

    # record this timestep, before elapsed times advance
    epidemic$time[timestep] <- current_time()
    epidemic$new_infections[timestep] <- number_newly_infected(population)
    epidemic$infected[timestep] <- number_infected(population)

    # 3. ages, elapsed times and levels
    population <- advance_individuals_one_timestep(population)

  }

  epidemic

}

# number of individuals infected in the current timestep, whose time since
# infection has not yet advanced; in the first timestep this includes the
# initial infections
number_newly_infected <- function(population) {

  number_newly_infected <- 0
  for (i in seq_along(population)) {
    individual <- population[[i]]
    if (individual$infected && individual$timesteps_since_infection == 0) {
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
