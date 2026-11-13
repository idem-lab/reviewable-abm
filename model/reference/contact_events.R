# the contact events in one timestep (maths.md: Contact events)

# all household and non-household contact events in a timestep, in random
# order
simulate_contact_events <- function(population, households) {

  contact_events <- c(household_contact_events(households),
                      simulate_non_household_contact_events(population))

  random_order(contact_events)

}

# one contact event for every pair of individuals in the same household
household_contact_events <- function(households) {

  household_contact_events <- list()
  for (h in seq_along(households)) {
    household <- households[[h]]
    household_contact_events <- c(household_contact_events,
                                  contact_events_in_household(household))
  }

  household_contact_events

}

# one contact event for every pair of members of a household
contact_events_in_household <- function(household) {

  load_parameters("household_contact_event_hours_per_day")
  load_settings("timestep_length")

  duration <- household_contact_event_hours_per_day * timestep_length

  contact_events_in_household <- list()
  for (i in household$member_indices) {
    for (j in household$member_indices) {
      if (i < j) {
        k <- length(contact_events_in_household) + 1
        contact_events_in_household[[k]] <- contact_event(
          individual_indices = c(i, j),
          in_household = TRUE,
          duration = duration
        )
      }
    }
  }

  contact_events_in_household

}

# a random number of contact events, each between a pair of individuals
# chosen at random from the whole population
simulate_non_household_contact_events <- function(population) {

  load_parameters("non_household_contact_events_per_person_per_day",
                  "non_household_contact_event_hours_per_day")
  load_settings("timestep_length")

  # each contact event counts for both individuals in it
  mean_number_of_non_household_contact_events <- length(population) *
    non_household_contact_events_per_person_per_day * timestep_length / 2
  number_of_non_household_contact_events <- random_poisson(
    mean_number_of_non_household_contact_events
  )

  duration <- non_household_contact_event_hours_per_day * timestep_length

  non_household_contact_events <- list()
  for (k in seq_len(number_of_non_household_contact_events)) {
    # who may live in the same household
    individual_indices <- random_individual_indices(population, 2)
    non_household_contact_events[[k]] <- contact_event(
      individual_indices = individual_indices,
      in_household = FALSE,
      duration = duration
    )
  }

  non_household_contact_events

}

# a contact event between a pair of individuals, given by their indices in
# the population; duration is in hours
contact_event <- function(individual_indices, in_household, duration) {

  list(
    individual_indices = individual_indices,
    in_household = in_household,
    duration = duration
  )

}
