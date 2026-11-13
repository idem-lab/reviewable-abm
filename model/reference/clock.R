# the simulation clock: the time at the start of the current timestep, in
# days. It is the only value that changes during a simulation without being
# passed as an argument, and only random_simulation() sets it.

simulation_clock <- new.env()

# the time at the start of the current timestep, in days
current_time <- function() {

  if (is.null(simulation_clock$time)) {
    stop("the simulation clock has not been set")
  }

  simulation_clock$time

}

# set the simulation clock; used only by the main simulation loop, and by
# tests
set_current_time <- function(time) {

  simulation_clock$time <- time

  time

}
