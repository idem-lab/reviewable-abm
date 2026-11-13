# the procedure's own linters (lint/model_linters.R): each flags code that
# breaks its rule and leaves valid code alone

local({
  old <- setwd(repository_root)
  on.exit(setwd(old))
  source("lint/model_linters.R", local = FALSE)
})

# code made of the given lines, as a file's contents
code <- function(...) {
  paste0(paste(c(...), collapse = "\n"), "\n")
}

test_that("the list of R's random functions covers all distributions", {
  random_functions <- r_random_functions()
  expected <- c("rnorm", "rpois", "rnbinom", "rweibull", "rmultinom",
                "sample.int", "mvrnorm")
  expect_true(all(expected %in% random_functions))
  expect_false(any(c("residuals", "reorder", "relevel") %in%
                     random_functions))
})

test_that("random_prefix_linter flags missing and unneeded prefixes", {
  linter <- random_prefix_linter()
  expect_lint(code("draw <- function(m) {", "  rnbinom(1, 2, mu = m)", "}"),
              "needs a random_ or simulate_ prefix", linter)
  expect_lint(code("random_one <- function() {", "  1", "}"),
              "should not have a random_ or simulate_ prefix", linter)
  expect_lint(code("random_draw <- function() {", "  simulate_x()", "}"),
              "must not call a simulate_ function", linter)
  expect_lint(code("random_delay <- function(s) {", "  rweibull(1, s)", "}"),
              NULL, linter)
})

test_that("r_random_only_in_random_linter flags random calls elsewhere", {
  linter <- r_random_only_in_random_linter()
  expect_lint(code("simulate_x <- function() {", "  runif(1)", "}"),
              "only be called in a random_ function", linter)
  expect_lint(code("random_x <- function() {", "  runif(1)", "}"),
              NULL, linter)
})

test_that("loaded_values_linter flags misplaced loads and assignments", {
  linter <- loaded_values_linter()
  expect_lint(code("f <- function() {", "  x <- 1",
                   "  load_parameters(\"rate\")", "  x * rate", "}"),
              "must be the first statements", linter)
  expect_lint(code("f <- function(y) {", "  if (y) {",
                   "    load_parameters(\"rate\")", "  }", "  y", "}"),
              "must be the first statements", linter)
  expect_lint(code("f <- function(rate) {", "  load_parameters(\"rate\")",
                   "  rate", "}"),
              "is also an argument", linter)
  for (assignment in c("  rate <- 2", "  rate[1] <- 2", "  2 -> rate",
                       "  names(rate) <- \"a\"", "  for (rate in 1) rate")) {
    expect_lint(code("f <- function() {", "  load_parameters(\"rate\")",
                     assignment, "  rate", "}"),
                "must not be assigned to", linter)
  }
  expect_lint(code("f <- function(y) {", "  load_parameters(\"rate\")",
                   "  load_settings(\"step\")", "  y * rate * step", "}"),
              NULL, linter)
})

test_that("no_default_arguments_linter flags default values", {
  linter <- no_default_arguments_linter()
  expect_lint(code("f <- function(x = 1) {", "  x", "}"),
              "must not have default values", linter)
  expect_lint(code("f <- function(x) {", "  x", "}"), NULL, linter)
})

test_that("one_to_n_linter flags 1:n but not 1 to a number", {
  linter <- one_to_n_linter()
  expect_lint(code("for (i in 1:n) i"), "seq_len", linter)
  expect_lint(code("for (i in 1:length(x)) i"), "seq_len", linter)
  expect_lint(code("x <- 1:3", "for (i in seq_len(n)) i"), NULL, linter)
})

test_that("package_call_linter flags packages other than MASS", {
  linter <- package_call_linter()
  expect_lint(code("dplyr::filter(x)"), "only base R", linter)
  expect_lint(code("MASS::mvrnorm(1, mu, sigma)"), NULL, linter)
})

test_that("vector_logic_anywhere_linter flags & and | anywhere", {
  linter <- vector_logic_anywhere_linter()
  expect_lint(code("x <- a & b"), "&& and \\|\\|", linter)
  expect_lint(code("x <- a | b"), "&& and \\|\\|", linter)
  expect_lint(code("x <- a && b || c"), NULL, linter)
})

test_that("infrastructure_call_linter flags model code setting values", {
  linter <- infrastructure_call_linter()
  expect_lint(code("f <- function() {", "  set_values(list(), list())", "}"),
              "must not set values or the clock", linter)
  expect_lint(code("f <- function() {", "  set_clock_to_timestep(1)", "}"),
              "must not set values or the clock", linter)
  expect_lint(code("simulate_epidemic <- function() {",
                   "  set_clock_to_timestep(1)", "}"),
              NULL, linter)
})

test_that("nesting_depth_linter counts loops and ifs but not else if", {
  linter <- nesting_depth_linter()
  expect_lint(code("for (i in x) {", "  for (j in y) {",
                   "    if (i < j) i", "  }", "}"),
              "more than two levels", linter)
  expect_lint(code("for (i in x) {", "  if (a) {", "    1",
                   "  } else if (b) {", "    2", "  } else {", "    3",
                   "  }", "}"),
              NULL, linter)
})

test_that("function_length_linter flags long functions", {
  linter <- function_length_linter(maximum_lines = 5)
  expect_lint(code("f <- function() {", rep("  1", 5), "}"),
              "keep functions under about 5", linter)
  expect_lint(code("f <- function() {", "  1", "}"), NULL, linter)
})
