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

  viral_load_peak_time <- parameter("viral_load_peak_time")
  recovery_viral_load_threshold <- setting("recovery_viral_load_threshold")

  individual$infected &&
    individual$time_since_infection >= viral_load_peak_time &&
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

  immunity_waning_rate <- parameter("immunity_waning_rate")

  immunity_level <- 0

  if (!is.na(individual$time_since_boost)) {
    waned <- immunity_waning_rate * individual$time_since_boost
    immunity_level <- max(0, individual$immunity_after_boost - waned)
  }

  immunity_level

}
