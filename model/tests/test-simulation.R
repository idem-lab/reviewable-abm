# maths.md: Time, and running the whole model

test_that("a simulation records every timestep, from time 0", {
  use_values(settings = list(population_size = 60, number_of_timesteps = 5,
                             timestep_length = 0.5))
  set.seed(1)
  epidemic <- simulate_epidemic()
  expect_equal(epidemic$time, c(0, 0.5, 1, 1.5, 2))
})

test_that("new infections in the first timestep include the initial ones", {
  use_values(settings = list(population_size = 60, number_of_timesteps = 2,
                             initial_infections = 4))
  set.seed(1)
  epidemic <- simulate_epidemic()
  expect_gte(epidemic$new_infections[1], 4)
})

test_that("the same seed gives the same epidemic", {
  set.seed(3)
  first <- run_model(settings = list(population_size = 80,
                                     number_of_timesteps = 20),
                     parameters = list())
  set.seed(3)
  second <- run_model(settings = list(population_size = 80,
                                      number_of_timesteps = 20),
                      parameters = list())
  expect_identical(first, second)
})

test_that("a run uses the values given and returns them", {
  set.seed(1)
  result <- run_model(settings = list(population_size = 40,
                                      number_of_timesteps = 3),
                      parameters = list(immunity_waning_rate = 0.05))
  expect_equal(result$settings$population_size, 40)
  expect_equal(result$parameters$immunity_waning_rate, 0.05)
  expect_equal(result$parameters$viral_load_peak_time,
               default_parameters$viral_load_peak_time)
  expect_equal(nrow(result$epidemic), 3)
})

test_that("a change to a value does not carry over to the next run", {
  set.seed(1)
  run_model(settings = list(population_size = 40, number_of_timesteps = 2),
            parameters = list(immunity_waning_rate = 0.05))
  result <- run_model(settings = list(population_size = 40,
                                      number_of_timesteps = 2),
                      parameters = list())
  expect_equal(result$parameters$immunity_waning_rate,
               default_parameters$immunity_waning_rate)
})

test_that("a run stops if a value is misspelt", {
  expect_error(run_model(settings = list(),
                         parameters = list(immunity_waning_rat = 1)),
               "no parameter called immunity_waning_rat")
})
