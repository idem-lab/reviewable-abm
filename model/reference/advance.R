# advancing individuals by one timestep (maths.md: Advancing individuals)

# add one timestep to every individual's age and elapsed times, then
# recalculate their viral load and immunity level from these times
advance_individuals_one_timestep <- function(population) {

  timestep_length <- setting("timestep_length") # days

  for (i in seq_along(population)) {

    individual <- population[[i]]

    individual$age <- individual$age + timestep_length / 365.25
    if (individual$infected) {
      individual$time_since_infection <-
        individual$time_since_infection + timestep_length
    }
    if (!is.na(individual$time_since_boost)) {
      individual$time_since_boost <- individual$time_since_boost +
        timestep_length
    }

    individual$immunity_level <- immunity_level(individual)
    individual$viral_load <- viral_load(individual)

    population[[i]] <- individual

  }

  population

}
