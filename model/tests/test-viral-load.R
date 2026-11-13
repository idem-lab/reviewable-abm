# maths.md: Viral load

test_that("infection records immunity before boosting it", {
  use_values()
  individual <- make_individual(immunity_level = 0.8)
  infected <- infection(individual, list(viral_load_level = 2,
                                         boost_size = 0.5))
  expect_equal(infected$immunity_at_infection, 0.8)
  expect_equal(infected$immunity_after_boost, 1.3)
  expect_equal(infected$immunity_level, 1.3)
})

test_that("infection starts both elapsed times at zero", {
  use_values()
  infected <- make_infected_individual()
  expect_true(infected$infected)
  expect_equal(infected$time_since_infection, 0)
  expect_equal(infected$time_since_boost, 0)
})

test_that("viral load is zero at infection", {
  use_values()
  expect_equal(make_infected_individual(viral_load_level = 5)$viral_load, 0)
})

test_that("the viral load profile is zero at infection and peaks at 1", {
  use_values(parameters = list(viral_load_peak_time = 4))
  expect_equal(viral_load_profile(0), 0)
  expect_equal(viral_load_profile(4), 1)
  expect_lt(viral_load_profile(3.9), 1)
  expect_lt(viral_load_profile(4.1), 1)
})

test_that("the viral load profile is symmetric in log time about its peak", {
  use_values(parameters = list(viral_load_peak_time = 4,
                               viral_load_profile_width = 0.4))
  expect_equal(viral_load_profile(4 * 1.7), viral_load_profile(4 / 1.7))
})

test_that("a typical infection with no immunity peaks at a viral load of 1", {
  use_values(parameters = list(viral_load_peak_time = 4))
  individual <- make_infected_individual(viral_load_level = 1)
  individual$time_since_infection <- 4
  expect_equal(viral_load(individual), 1)
})

test_that("viral load scales with the viral load level", {
  use_values()
  low <- make_infected_individual(viral_load_level = 1)
  high <- make_infected_individual(viral_load_level = 3)
  low$time_since_infection <- 2
  high$time_since_infection <- 2
  expect_equal(viral_load(high), 3 * viral_load(low))
})

test_that("immunity at infection reduces viral load by exp(-kappa z)", {
  use_values(parameters = list(viral_load_immunity_effect = 0.5))
  expect_equal(viral_load_immunity_multiplier(0), 1)
  expect_equal(viral_load_immunity_multiplier(2), exp(-1))
})

test_that("an uninfected individual has zero viral load", {
  use_values()
  individual <- make_infected_individual()
  individual$time_since_infection <- 4
  individual$infected <- FALSE
  expect_equal(viral_load(individual), 0)
})

test_that("viral load levels and boost sizes have the set lognormal distributions", {
  use_values(parameters = list(viral_load_level_sdlog = 0.8,
                               immunity_boost_meanlog = 0.3,
                               immunity_boost_sdlog = 0.5,
                               viral_load_boost_correlation = 0.6))
  set.seed(1)
  draws <- replicate(5000, unlist(random_infection_characteristics()))
  log_levels <- log(draws["viral_load_level", ])
  log_boosts <- log(draws["boost_size", ])
  expect_equal(mean(log_levels), 0, tolerance = 0.05)
  expect_equal(sd(log_levels), 0.8, tolerance = 0.05)
  expect_equal(mean(log_boosts), 0.3, tolerance = 0.05)
  expect_equal(sd(log_boosts), 0.5, tolerance = 0.05)
  expect_equal(cor(log_levels, log_boosts), 0.6, tolerance = 0.05)
})
