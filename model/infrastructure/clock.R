# infrastructure, not part of the model: the simulation clock, holding the
# time at the start of the current timestep, in days. It is the only value
# that changes during a simulation without being passed as an argument. Only
# the main simulation loop sets it, with set_clock_to_timestep(), and model
# functions read it with current_time().

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

  load_settings("timestep_length")

  time <- (timestep - 1) * timestep_length
  simulation_clock$time <- time

  time

}

# clear the simulation clock before a run, so that a run cannot read the
# time left by the previous one
reset_clock <- function() {

  simulation_clock$time <- NULL

  invisible(NULL)

}
