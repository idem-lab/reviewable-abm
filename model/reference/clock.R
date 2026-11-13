# the simulation clock: the time at the start of the current timestep, in
# days. It is the only value that changes during a simulation without being
# passed as an argument, and only simulate_epidemic() sets it, with
# set_clock_to_timestep().

simulation_clock <- new.env()

# the time at the start of the current timestep, in days
current_time <- function() {

  if (is.null(simulation_clock$time)) {
    stop("the simulation clock has not been set")
  }

  simulation_clock$time

}

# set the simulation clock to the start of a timestep, counting from 1;
# used only by the main simulation loop, and by tests
set_clock_to_timestep <- function(timestep) {

  time <- (timestep - 1) * setting("timestep_length")
  simulation_clock$time <- time

  time

}
