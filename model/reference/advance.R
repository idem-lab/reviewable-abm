# advancing individuals by one timestep (maths.md: Advancing individuals)

# add one timestep to every individual's age and elapsed times, then
# recalculate their viral load and immunity level from these times
advance_individuals_one_timestep <- function(population) {

  load_settings("timestep_length")

  for (i in seq_along(population)) {

    individual <- population[[i]]

    individual$age <- individual$age + timestep_length / 365.25
    if (individual$infected) {
      individual$timesteps_since_infection <-
        individual$timesteps_since_infection + 1
    }
    if (!is.na(individual$timesteps_since_boost)) {
      individual$timesteps_since_boost <-
        individual$timesteps_since_boost + 1
    }

    individual$immunity_level <- immunity_level(individual)
    individual$viral_load <- viral_load(individual)

    population[[i]] <- individual

  }

  population

}

# time since the individual's most recent infection, in days; NA if never
# infected. Elapsed times are counted in whole timesteps and converted to
# days here, so that they are exact multiples of the timestep length:
# adding the timestep length repeatedly would accumulate rounding error,
# so that, for example, 50 timesteps of 0.1 days would come to slightly
# less than 5 days.
time_since_infection <- function(individual) {

  load_settings("timestep_length")

  individual$timesteps_since_infection * timestep_length

}

# time since the individual's most recent immunity boost, in days; NA if
# never boosted. Counted in whole timesteps, as for time_since_infection().
time_since_boost <- function(individual) {

  load_settings("timestep_length")

  individual$timesteps_since_boost * timestep_length

}
