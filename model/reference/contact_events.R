# the contact events in one timestep (maths.md: Contact events)

# all household and non-household contact events in a timestep, in random
# order
random_contact_events <- function(population) {

  contact_events <- c(household_contact_events(population),
                      random_non_household_contact_events(population))

  contact_events[sample.int(length(contact_events))]

}

# one contact event for every pair of individuals in the same household
household_contact_events <- function(population) {

  duration <- parameter("household_contact_event_hours_per_day") *
    setting("timestep_length")

  contact_events <- list()
  for (i in seq_along(population)) {
    for (j in seq_along(population)) {
      if (i < j && population[[i]]$household == population[[j]]$household) {
        contact_events[[length(contact_events) + 1]] <- contact_event(
          individual_a = i,
          individual_b = j,
          in_household = TRUE,
          duration = duration
        )
      }
    }
  }

  contact_events

}

# a random number of contact events, each between a pair of individuals
# chosen at random from the whole population
random_non_household_contact_events <- function(population) {

  # each contact event counts for both individuals in it
  mean_number <- length(population) *
    parameter("non_household_contact_events_per_person_per_day") *
    setting("timestep_length") / 2
  number_of_non_household_contact_events <- rpois(1, mean_number)

  duration <- parameter("non_household_contact_event_hours_per_day") *
    setting("timestep_length")

  contact_events <- list()
  for (k in seq_len(number_of_non_household_contact_events)) {
    # two different individuals, who may live in the same household
    pair <- sample.int(length(population), 2)
    contact_events[[k]] <- contact_event(
      individual_a = pair[1],
      individual_b = pair[2],
      in_household = FALSE,
      duration = duration
    )
  }

  contact_events

}

# a contact event between two individuals, identified by their positions in
# the population; duration is in hours
contact_event <- function(individual_a, individual_b, in_household,
                          duration) {

  list(
    individual_a = individual_a,
    individual_b = individual_b,
    in_household = in_household,
    duration = duration
  )

}
