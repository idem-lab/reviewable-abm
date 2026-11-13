# model/infrastructure/ and model/reference/random_draws.R

test_that("loading an unknown parameter stops with an error", {
  use_values()
  f <- function() {
    load_parameters("viral_load_peak_tim")
  }
  expect_error(f(), "no parameter called viral_load_peak_tim")
})

test_that("loading a parameter makes it a variable in the calling function", {
  use_values(parameters = list(viral_load_peak_time = 7))
  f <- function() {
    load_parameters("viral_load_peak_time")
    viral_load_peak_time
  }
  expect_equal(f(), 7)
})

test_that("the values of a run cannot be changed while it runs", {
  use_values()
  expect_error(assign("viral_load_peak_time", 1, envir = values$parameters),
               "locked")
})

test_that("the clock gives the start of the timestep", {
  use_values(settings = list(timestep_length = 0.5))
  set_clock_to_timestep(1)
  expect_equal(current_time(), 0)
  set_clock_to_timestep(3)
  expect_equal(current_time(), 1)
})

test_that("reading the clock before it is set stops with an error", {
  reset_clock()
  expect_error(current_time(), "not been set")
})

test_that("random_order returns the same elements in some order", {
  set.seed(1)
  elements <- as.list(letters[1:6])
  ordered <- random_order(elements)
  expect_setequal(unlist(ordered), letters[1:6])
  expect_length(ordered, 6)
})

test_that("random_individual_indices chooses different individuals", {
  set.seed(1)
  population <- vector("list", 10)
  indices <- random_individual_indices(population, 10)
  expect_equal(sort(indices), 1:10)
})

test_that("random_bernoulli is always FALSE at probability 0 and TRUE at 1", {
  set.seed(1)
  expect_false(any(replicate(100, random_bernoulli(0))))
  expect_true(all(replicate(100, random_bernoulli(1))))
})

test_that("each random draw function returns a single value", {
  set.seed(1)
  expect_length(random_bernoulli(0.5), 1)
  expect_length(random_uniform(0, 1), 1)
  expect_length(random_poisson(3), 1)
})
