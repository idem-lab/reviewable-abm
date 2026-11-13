# maths.md: Contact events

test_that("a household has one contact event for each pair of members", {
  use_values()
  household <- list(member_indices = c(4, 5, 6, 7))
  contact_events <- contact_events_in_household(household)
  pairs <- t(vapply(contact_events, `[[`, numeric(2), "individual_indices"))
  expect_equal(nrow(pairs), 6)
  expect_true(all(pairs[, 1] < pairs[, 2]))
  expect_equal(nrow(unique(pairs)), 6)
})

test_that("a household of one member has no contact events", {
  use_values()
  household <- list(member_indices = 9)
  expect_length(contact_events_in_household(household), 0)
})

test_that("household contact events last daily hours times the timestep", {
  use_values(settings = list(timestep_length = 0.5),
             parameters = list(household_contact_event_hours_per_day = 6))
  household <- list(member_indices = c(1, 2))
  contact_event <- contact_events_in_household(household)[[1]]
  expect_true(contact_event$in_household)
  expect_equal(contact_event$duration, 3)
})

test_that("household contact events cover every household", {
  use_values()
  households <- list(list(member_indices = c(1, 2, 3)),
                     list(member_indices = 4),
                     list(member_indices = c(5, 6)))
  expect_length(household_contact_events(households), 3 + 0 + 1)
})

test_that("non-household contact events are between two different people", {
  use_values()
  set.seed(1)
  population <- simulate_initial_population(simulate_households())
  contact_events <- simulate_non_household_contact_events(population)
  for (contact_event in contact_events) {
    indices <- contact_event$individual_indices
    expect_length(indices, 2)
    expect_true(indices[1] != indices[2])
    expect_false(contact_event$in_household)
  }
})

test_that("non-household contact events last daily hours times the timestep", {
  use_values(settings = list(timestep_length = 2),
             parameters = list(non_household_contact_event_hours_per_day = 0.5))
  set.seed(1)
  population <- simulate_initial_population(simulate_households())
  contact_event <- simulate_non_household_contact_events(population)[[1]]
  expect_equal(contact_event$duration, 1)
})

test_that("the mean number of non-household contact events is N c dt / 2", {
  use_values(settings = list(population_size = 100, timestep_length = 0.5),
             parameters = list(
               non_household_contact_events_per_person_per_day = 4
             ))
  set.seed(1)
  population <- simulate_initial_population(simulate_households())
  counts <- replicate(2000, {
    length(simulate_non_household_contact_events(population))
  })
  # Poisson with mean 100; the standard error of the mean is about 0.22
  expect_equal(mean(counts), 100, tolerance = 0.01)
})

test_that("a timestep's contact events include all household contact events", {
  use_values(settings = list(population_size = 50))
  set.seed(1)
  households <- simulate_households()
  population <- simulate_initial_population(households)
  contact_events <- simulate_contact_events(population, households)
  in_household <- vapply(contact_events, `[[`, logical(1), "in_household")
  expect_equal(sum(in_household), length(household_contact_events(households)))
})
