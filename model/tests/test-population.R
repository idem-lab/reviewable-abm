# maths.md: Population

test_that("every individual belongs to exactly one household", {
  use_values(settings = list(population_size = 300))
  set.seed(1)
  households <- simulate_households()
  member_indices <- unlist(lapply(households, `[[`, "member_indices"))
  expect_equal(sort(member_indices), seq_len(300))
})

test_that("every household has at least one member", {
  use_values(settings = list(population_size = 300,
                             average_household_size = 1.2))
  set.seed(1)
  households <- simulate_households()
  sizes <- vapply(households, function(household) {
    length(household$member_indices)
  }, numeric(1))
  expect_true(all(sizes >= 1))
})

test_that("households are filled with consecutive individuals", {
  use_values(settings = list(population_size = 300))
  set.seed(1)
  households <- simulate_households()
  for (household in households) {
    expect_equal(diff(household$member_indices),
                 rep(1, length(household$member_indices) - 1))
  }
})

test_that("household sizes average the set average household size", {
  use_values(settings = list(population_size = 20000,
                             average_household_size = 3.5))
  set.seed(1)
  households <- simulate_households()
  sizes <- vapply(households, function(household) {
    length(household$member_indices)
  }, numeric(1))
  # the last household may be cut short, which barely affects the mean
  expect_equal(mean(sizes), 3.5, tolerance = 0.03)
})

test_that("each individual's household lists them as a member", {
  use_values(settings = list(population_size = 200))
  set.seed(1)
  households <- simulate_households()
  population <- simulate_initial_population(households)
  for (i in seq_along(population)) {
    household <- households[[population[[i]]$household_index]]
    expect_true(i %in% household$member_indices)
  }
})

test_that("the set number of individuals are infected at the start", {
  use_values(settings = list(population_size = 200, initial_infections = 7))
  set.seed(1)
  population <- simulate_initial_population(simulate_households())
  infected <- vapply(population, `[[`, logical(1), "infected")
  expect_equal(sum(infected), 7)
})

test_that("initial ages lie between 0 and the maximum initial age", {
  use_values(settings = list(population_size = 500))
  set.seed(1)
  population <- simulate_initial_population(simulate_households())
  ages <- vapply(population, `[[`, numeric(1), "age")
  expect_true(all(ages >= 0 & ages < default_settings$maximum_initial_age))
})

test_that("a new individual is uninfected, with no immunity or viral load", {
  use_values()
  individual <- simulate_new_individual(household_index = 3)
  expect_false(individual$infected)
  expect_equal(individual$immunity_level, 0)
  expect_equal(individual$viral_load, 0)
  expect_equal(individual$household_index, 3)
})

test_that("a new individual's infection and boost quantities are undefined", {
  use_values()
  individual <- simulate_new_individual(household_index = 1)
  undefined <- c("time_since_infection", "time_since_boost",
                 "potential_peak_viral_load", "boost_size",
                 "immunity_at_infection", "immunity_after_boost")
  for (name in undefined) {
    expect_true(is.na(individual[[name]]), label = name)
  }
})

test_that("individuals younger than the adult age are children", {
  use_values(settings = list(adult_age = 18))
  expect_true(is_child(17.9))
  expect_false(is_child(18))
  expect_false(is_child(40))
})
