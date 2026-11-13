# transmission during contact events (maths.md: Transmission)

# resolve contact events one at a time, in the order given, so that
# individuals infected by earlier contact events can infect, and cannot be
# infected, in later ones
random_transmissions <- function(population, contact_events) {

  for (k in seq_along(contact_events)) {

    contact_event <- contact_events[[k]]
    pair <- contact_event$pair
    infected <- c(population[[pair[1]]]$infected,
                  population[[pair[2]]]$infected)
    one_infected <- any(infected) && !all(infected)

    # transmission is possible only if exactly one of the pair is infected
    if (one_infected) {

      # a is the infected individual and b the uninfected one
      a <- pair[infected]
      b <- pair[!infected]
      infector <- population[[a]]
      infectee <- population[[b]]

      transmitted <- random_transmission_outcome(
        infector = infector,
        infectee = infectee,
        contact_event = contact_event
      )

      if (transmitted) {
        population[[b]] <- random_infection(infectee)
      }

    }

  }

  population

}

# whether a contact event transmits infection
random_transmission_outcome <- function(infector, infectee, contact_event) {

  transmission_probability <- transmission_probability(
    infector = infector,
    infectee = infectee,
    contact_event = contact_event
  )

  runif(1) < transmission_probability

}

# probability of transmission during one contact event, from a constant
# hazard over the contact event's duration
transmission_probability <- function(infector, infectee, contact_event) {

  log_hazard <- log(parameter("baseline_transmission_hazard")) +
    infectiousness_score(infector) +
    susceptibility_score(infectee) +
    location_score(contact_event)

  # per hour
  hazard <- exp(log_hazard)
  transmission_probability <- 1 - exp(-hazard * contact_event$duration)

  transmission_probability

}

# log hazard ratio for the infected individual: zero viral load gives a
# score of minus infinity, and so no transmission
infectiousness_score <- function(individual) {

  log(individual$viral_load) +
    parameter("child_infectiousness_score") * is_child(individual)

}

# log hazard ratio for the uninfected individual
susceptibility_score <- function(individual) {

  parameter("child_susceptibility_score") * is_child(individual) -
    individual$immunity_level

}

# log hazard ratio for the location of a contact event
location_score <- function(contact_event) {

  parameter("household_location_score") * contact_event$in_household

}
