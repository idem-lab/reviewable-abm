# recovery and immunity (maths.md: Recovery and immunity)

# end the infections of all individuals who meet the conditions for
# recovery
recover_individuals <- function(population) {

  for (i in seq_along(population)) {
    individual <- population[[i]]
    if (ready_to_recover(individual)) {
      population[[i]] <- recovery(individual)
    }
  }

  population

}

# whether an infected individual's viral load has passed its peak and is
# below the recovery threshold
ready_to_recover <- function(individual) {

  load_parameters("viral_load_peak_time")
  load_settings("recovery_viral_load_threshold")

  individual$infected &&
    time_since_infection(individual) >= viral_load_peak_time &&
    individual$viral_load < recovery_viral_load_threshold

}

# an individual who has just recovered; immunity is unchanged
recovery <- function(individual) {

  individual$infected <- FALSE

  individual

}

# immunity level of an individual: the reduction in their log hazard of
# infection, which declines at a constant rate after a boost until it is
# lost; zero if never boosted
immunity_level <- function(individual) {

  load_parameters("immunity_waning_rate")

  immunity_level <- 0

  if (!is.na(individual$timesteps_since_boost)) {
    waned <- immunity_waning_rate * time_since_boost(individual)
    immunity_level <- max(0, individual$immunity_after_boost - waned)
  }

  immunity_level

}
