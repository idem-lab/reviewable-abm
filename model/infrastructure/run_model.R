# infrastructure, not part of the model: running the model with chosen
# values

# run the model once, with the default settings and parameters except those
# given by name in the lists settings and parameters (use list() for none).
# Returns the epidemic, with the full settings and parameters used.
run_model <- function(settings, parameters) {

  # also clears the clock
  set_values(settings, parameters)

  epidemic <- simulate_epidemic()

  c(list(epidemic = epidemic), current_values())

}
