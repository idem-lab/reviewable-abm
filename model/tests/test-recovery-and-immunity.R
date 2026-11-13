# maths.md: Recovery and immunity, and Advancing individuals

description <- paste("an infection never ends before its peak, however low its",
                     "viral load")
test_that(description, {
  use_values(parameters = list(viral_load_peak_time = 4))
  individual <- make_infected_individual(potential_peak_viral_load = 1e-6)
  individual$timesteps_since_infection <- 3
  individual$viral_load <- 1e-9
  expect_false(ready_to_recover(individual))
})

description <- paste("an infection ends after its peak once viral load is",
                     "below the threshold")
test_that(description, {
  use_values(settings = list(recovery_viral_load_threshold = 0.001),
             parameters = list(viral_load_peak_time = 4))
  individual <- make_infected_individual()
  individual$timesteps_since_infection <- 10
  individual$viral_load <- 0.0009
  expect_true(ready_to_recover(individual))
  individual$viral_load <- 0.0011
  expect_false(ready_to_recover(individual))
})

test_that("an individual who has never been infected is not ready to recover", {
  use_values()
  expect_false(ready_to_recover(make_individual()))
})

test_that("recovery ends infection and leaves immunity unchanged", {
  use_values()
  individual <- make_infected_individual(boost_size = 2)
  recovered <- recovery(individual)
  expect_false(recovered$infected)
  expect_equal(recovered$immunity_level, individual$immunity_level)
  expect_equal(recovered$immunity_after_boost,
               individual$immunity_after_boost)
})

test_that("immunity is zero before the first boost", {
  use_values()
  expect_equal(immunity_level(make_individual()), 0)
})

test_that("immunity declines linearly at the waning rate", {
  use_values(parameters = list(immunity_waning_rate = 0.01))
  individual <- make_infected_individual(boost_size = 2)
  individual$timesteps_since_boost <- 50
  expect_equal(immunity_level(individual), 2 - 0.5)
})

test_that("immunity is lost, not negative, once it has waned", {
  use_values(parameters = list(immunity_waning_rate = 0.01))
  individual <- make_infected_individual(boost_size = 2)
  individual$timesteps_since_boost <- 500
  expect_equal(immunity_level(individual), 0)
})

test_that("a boost adds to the immunity that remains", {
  use_values()
  individual <- make_individual(immunity_level = 1.2)
  boosted <- infection(individual, list(potential_peak_viral_load = 1,
                                        boost_size = 0.1))
  expect_gt(boosted$immunity_level, individual$immunity_level)
})

test_that("advancing a timestep ages everyone and advances elapsed times", {
  use_values(settings = list(timestep_length = 0.5))
  population <- list(make_infected_individual(), make_individual(age = 40))
  after <- advance_individuals_one_timestep(population)
  expect_equal(after[[1]]$age, population[[1]]$age + 0.5 / 365.25)
  expect_equal(after[[2]]$age, 40 + 0.5 / 365.25)
  expect_equal(time_since_infection(after[[1]]), 0.5)
  expect_equal(time_since_boost(after[[1]]), 0.5)
})

test_that("elapsed times are exact multiples of the timestep length", {
  use_values(settings = list(timestep_length = 0.1))
  population <- list(make_infected_individual())
  for (step in seq_len(50)) {
    population <- advance_individuals_one_timestep(population)
  }
  # exactly 5, where adding 0.1 fifty times gives slightly less
  expect_identical(time_since_infection(population[[1]]), 50 * 0.1)
  expect_true(time_since_infection(population[[1]]) >= 5)
})

test_that("advancing a timestep leaves undefined elapsed times undefined", {
  use_values()
  after <- advance_individuals_one_timestep(list(make_individual()))
  expect_true(is.na(time_since_infection(after[[1]])))
  expect_true(is.na(time_since_boost(after[[1]])))
  expect_equal(after[[1]]$immunity_level, 0)
})

test_that("time since infection stops advancing after recovery", {
  use_values()
  individual <- recovery(make_infected_individual())
  individual$timesteps_since_infection <- 12
  after <- advance_individuals_one_timestep(list(individual))
  expect_equal(after[[1]]$timesteps_since_infection, 12)
  expect_equal(after[[1]]$viral_load, 0)
})

test_that("advancing a timestep recalculates viral load and immunity", {
  use_values(parameters = list(viral_load_peak_time = 1))
  population <- list(make_infected_individual())
  after <- advance_individuals_one_timestep(population)
  expect_equal(after[[1]]$viral_load, viral_load(after[[1]]))
  expect_equal(after[[1]]$immunity_level, immunity_level(after[[1]]))
  expect_gt(after[[1]]$viral_load, 0)
})
