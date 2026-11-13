# settings and parameters of the model, with illustrative values (not
# calibrated to any pathogen); see the notation tables in maths.md. They are
# held in locked environments so that nothing can change them while the
# model runs, and model functions read them only with load_settings() and
# load_parameters().

settings <- list2env(
  list(
    population_size = 500,
    average_household_size = 4,
    initial_infections = 5,
    timestep_length = 1, # days
    number_of_timesteps = 150,
    maximum_initial_age = 80, # years
    adult_age = 18, # years
    recovery_viral_load_threshold = 0.001 # fraction of a typical peak
  )
)
lockEnvironment(settings, bindings = TRUE)

parameters <- list2env(
  list(
    baseline_transmission_hazard = 0.015, # per hour
    child_infectiousness_score = -0.2,
    child_susceptibility_score = -0.4,
    household_location_score = 0.7,
    household_contact_event_hours_per_day = 6,
    non_household_contact_event_hours_per_day = 0.5,
    non_household_contact_events_per_person_per_day = 10,
    viral_load_level_sdlog = 1,
    viral_load_peak_time = 4, # days
    viral_load_profile_width = 0.4,
    viral_load_immunity_effect = 0.5,
    immunity_boost_meanlog = log(2),
    immunity_boost_sdlog = 0.5,
    viral_load_boost_correlation = 0.5,
    immunity_waning_rate = 0.01 # log hazard ratio per day
  )
)
lockEnvironment(parameters, bindings = TRUE)

# make the named settings available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a function
load_settings <- function(...) {

  names <- c(...)
  caller <- parent.frame()

  for (name in names) {
    if (!exists(name, envir = settings, inherits = FALSE)) {
      stop("no setting called ", name)
    }
    assign(name, get(name, envir = settings), envir = caller)
  }

  invisible(names)

}

# make the named parameters available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a function
load_parameters <- function(...) {

  names <- c(...)
  caller <- parent.frame()

  for (name in names) {
    if (!exists(name, envir = parameters, inherits = FALSE)) {
      stop("no parameter called ", name)
    }
    assign(name, get(name, envir = parameters), envir = caller)
  }

  invisible(names)

}
