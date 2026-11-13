# the contact events in one timestep (maths.md: Contact events)

# all household and non-household contact events in a timestep, in random
# order
random_contact_events <- function(population) {

  contact_events <- c(household_contact_events(population),
                      random_non_household_contact_events(population))

  random_order(contact_events)

}

# one contact event for every pair of individuals in the same household
household_contact_events <- function(population) {

  households <- households(population)

  household_contact_events <- list()
  for (h in seq_along(households)) {
    household <- households[[h]]
    household_contact_events <- c(household_contact_events,
                                  contact_events_in_household(household))
  }

  household_contact_events

}

# the households, each listing the indices of its members in the
# population; an individual's household index is the index of their
# household in this list
households <- function(population) {

  number_of_households <- length(population) / setting("household_size")
  households <- list()
  for (h in seq_len(number_of_households)) {
    households[[h]] <- list(member_indices = c())
  }

  for (i in seq_along(population)) {
    individual <- population[[i]]
    h <- individual$household_index
    households[[h]]$member_indices <- c(households[[h]]$member_indices, i)
  }

  households

}

# one contact event for every pair of members of a household
contact_events_in_household <- function(household) {

  duration <- parameter("household_contact_event_hours_per_day") *
    setting("timestep_length")

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
random_non_household_contact_events <- function(population) {

  # each contact event counts for both individuals in it
  mean_number_of_non_household_contact_events <- length(population) *
    parameter("non_household_contact_events_per_person_per_day") *
    setting("timestep_length") / 2
  number_of_non_household_contact_events <- rpois(
    1, mean_number_of_non_household_contact_events
  )

  duration <- parameter("non_household_contact_event_hours_per_day") *
    setting("timestep_length")

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
