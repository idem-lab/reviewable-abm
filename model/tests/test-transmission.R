# maths.md: Transmission

test_that("the transmission probability follows from a constant hazard", {
  use_values()
  infector <- make_individual(age = 30, infected = TRUE, viral_load = 0.5)
  infectee <- make_individual(age = 10, immunity_level = 0.3)
  contact_event <- make_contact_event(in_household = TRUE, duration = 2)
  parameters <- default_parameters
  log_hazard <- log(parameters$baseline_transmission_hazard) +
    log(0.5) +
    parameters$child_susceptibility_score - 0.3 +
    parameters$household_location_score
  expected <- 1 - exp(-exp(log_hazard) * 2)
  expect_equal(transmission_probability(infector, infectee, contact_event),
               expected)
})

test_that("an infector with zero viral load cannot transmit", {
  use_values()
  infector <- make_individual(infected = TRUE, viral_load = 0)
  infectee <- make_individual()
  expect_equal(
    transmission_probability(infector, infectee, make_contact_event()), 0
  )
})

test_that("longer contact events are more likely to transmit", {
  use_values()
  infector <- make_individual(infected = TRUE, viral_load = 1)
  infectee <- make_individual()
  short <- transmission_probability(infector, infectee,
                                    make_contact_event(duration = 1))
  long <- transmission_probability(infector, infectee,
                                   make_contact_event(duration = 5))
  expect_gt(long, short)
})

test_that("the infectiousness score adds the child score only for children", {
  use_values(parameters = list(child_infectiousness_score = -0.2))
  adult <- make_individual(age = 30, viral_load = 2)
  child <- make_individual(age = 5, viral_load = 2)
  expect_equal(infectiousness_score(adult), log(2))
  expect_equal(infectiousness_score(child), log(2) - 0.2)
})

test_that("the susceptibility score subtracts the immunity level", {
  use_values(parameters = list(child_susceptibility_score = -0.4))
  adult <- make_individual(age = 30, immunity_level = 1.5)
  child <- make_individual(age = 5, immunity_level = 1.5)
  expect_equal(susceptibility_score(adult), -1.5)
  expect_equal(susceptibility_score(child), -0.4 - 1.5)
})

test_that("only household contact events have a location score", {
  use_values(parameters = list(household_location_score = 0.7))
  expect_equal(location_score(make_contact_event(in_household = TRUE)), 0.7)
  expect_equal(location_score(make_contact_event(in_household = FALSE)), 0)
})

test_that("a contact event between two infected people transmits nothing", {
  use_values(parameters = list(baseline_transmission_hazard = 1e6))
  population <- list(make_infected_individual(), make_infected_individual())
  population[[1]]$viral_load <- 1
  after <- simulate_transmissions(population, list(make_contact_event()))
  expect_identical(after, population)
})

test_that("a contact event between two uninfected people transmits nothing", {
  use_values(parameters = list(baseline_transmission_hazard = 1e6))
  population <- list(make_individual(), make_individual())
  after <- simulate_transmissions(population, list(make_contact_event()))
  expect_identical(after, population)
})

description <- paste("a certain transmission infects the uninfected",
                     "individual, whichever is listed first")
test_that(description, {
  use_values(parameters = list(baseline_transmission_hazard = 1e6))
  for (infected_first in c(TRUE, FALSE)) {
    infector <- make_individual(infected = TRUE, viral_load = 1)
    infectee <- make_individual()
    if (infected_first) {
      population <- list(infector, infectee)
    } else {
      population <- list(infectee, infector)
    }
    after <- simulate_transmissions(population, list(make_contact_event()))
    expect_true(after[[1]]$infected && after[[2]]$infected)
  }
})

test_that("an individual infected in a timestep cannot infect others in it", {
  use_values(parameters = list(baseline_transmission_hazard = 1e6))
  population <- list(make_individual(infected = TRUE, viral_load = 1),
                     make_individual(),
                     make_individual())
  contact_events <- list(
    contact_event(c(1, 2), in_household = FALSE, duration = 1),
    contact_event(c(2, 3), in_household = FALSE, duration = 1)
  )
  after <- simulate_transmissions(population, contact_events)
  expect_true(after[[2]]$infected)
  expect_false(after[[3]]$infected)
})
