# transmission during contact events (maths.md: Transmission)

# resolve contact events one at a time, in the order given, so that
# individuals infected by earlier contact events can infect, and cannot be
# infected, in later ones
simulate_transmissions <- function(population, contact_events) {

  for (k in seq_along(contact_events)) {

    contact_event <- contact_events[[k]]
    i <- contact_event$individual_indices[1]
    j <- contact_event$individual_indices[2]
    infected <- c(population[[i]]$infected, population[[j]]$infected)
    one_infected <- any(infected) && !all(infected)

    # transmission is possible only if exactly one of the pair is infected
    if (one_infected) {

      # a is the infected individual and b the uninfected one
      if (population[[i]]$infected) {
        a <- i
        b <- j
      } else {
        a <- j
        b <- i
      }
      infector <- population[[a]]
      infectee <- population[[b]]

      transmission_probability <- transmission_probability(
        infector = infector,
        infectee = infectee,
        contact_event = contact_event
      )
      transmitted <- random_bernoulli(transmission_probability)

      if (transmitted) {
        infection_characteristics <- random_infection_characteristics()
        population[[b]] <- infection(infectee, infection_characteristics)
      }

    }

  }

  population

}

# probability of transmission during one contact event, from a constant
# hazard over the contact event's duration
transmission_probability <- function(infector, infectee, contact_event) {

  load_parameters("baseline_transmission_hazard")

  log_hazard <- log(baseline_transmission_hazard) +
    infectiousness_score(infector) +
    susceptibility_score(infectee) +
    location_score(contact_event)

  # per hour
  hazard <- exp(log_hazard)
  1 - exp(-hazard * contact_event$duration)

}

# log hazard ratio for the infected individual: zero viral load gives a
# score of minus infinity, and so no transmission
infectiousness_score <- function(individual) {

  log(individual$viral_load) + infectiousness_age_score(individual$age)

}

# log hazard ratio for the age of the infected individual; adults are the
# reference
infectiousness_age_score <- function(age) {

  load_parameters("child_infectiousness_score")

  child_infectiousness_score * is_child(age)

}

# log hazard ratio for the uninfected individual
susceptibility_score <- function(individual) {

  susceptibility_age_score(individual$age) - individual$immunity_level

}

# log hazard ratio for the age of the uninfected individual; adults are the
# reference
susceptibility_age_score <- function(age) {

  load_parameters("child_susceptibility_score")

  child_susceptibility_score * is_child(age)

}

# log hazard ratio for the location of a contact event
location_score <- function(contact_event) {

  load_parameters("household_location_score")

  household_location_score * contact_event$in_household

}
