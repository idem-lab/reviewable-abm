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
  paired_member_indices <- paired_member_indices(household)

  contact_events_in_household <- list()
  for (k in seq_along(paired_member_indices)) {
    contact_events_in_household[[k]] <- contact_event(
      individual_indices = paired_member_indices[[k]],
      in_household = TRUE,
      duration = duration
    )
  }

  contact_events_in_household

}

# every pair of members of a household, once each, as the indices (i, j) of
# the two members, with i < j
paired_member_indices <- function(household) {

  member_indices <- household$member_indices

  paired_member_indices <- list()
  for (i in member_indices) {
    # only the members after i, so that each pair appears once
    later_member_indices <- member_indices[member_indices > i]
    for (j in later_member_indices) {
      paired_member_indices[[length(paired_member_indices) + 1]] <- c(i, j)
    }
  }

  paired_member_indices

}

# a random number of contact events, each between a pair of individuals
# chosen at random from the whole population
simulate_non_household_contact_events <- function(population) {

  load_parameters("non_household_contact_events_per_person_per_day",
                  "non_household_contact_event_hours")
  load_settings("timestep_length")

  # each contact event counts for both individuals in it
  mean_number_of_non_household_contact_events <- length(population) *
    non_household_contact_events_per_person_per_day * timestep_length / 2
  number_of_non_household_contact_events <- random_poisson(
    mean_number_of_non_household_contact_events
  )

  # each is a single encounter, so its duration does not depend on the
  # timestep length
  duration <- non_household_contact_event_hours

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
