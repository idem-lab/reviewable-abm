# lint the model and its tests against the rules in DESIGN.md. From the root
# of the repository, run `source("lint/lint_model.R")` and then
# `lint_model()`.

source("lint/model_linters.R")

# lintr's default style linters, except those that conflict with the design:
# long descriptive names are intended (object_length_linter), and variables
# made by load_parameters() and functions defined in other files are not
# undefined (object_usage_linter)
style_linters <- function() {
  linters_with_defaults(
    object_length_linter = NULL,
    object_usage_linter = NULL
  )
}

# linters for the reference implementation, model/reference/: the style
# linters, lintr linters for the rules in DESIGN.md Section 4, and this
# procedure's own linters
reference_linters <- function() {
  c(
    style_linters(),
    list(
      # language rules 2, 3 and 9, and naming rule 2
      undesirable_function_linter(c(
        assign = "use only in model/infrastructure/",
        get = "use only in model/infrastructure/",
        new.env = "use only in model/infrastructure/",
        environment = "use only in model/infrastructure/",
        with = "non-standard evaluation is not allowed",
        within = "non-standard evaluation is not allowed",
        subset = "non-standard evaluation is not allowed",
        transform = "non-standard evaluation is not allowed",
        attach = "non-standard evaluation is not allowed",
        library = "only base R is allowed; call MASS with ::",
        require = "only base R is allowed; call MASS with ::",
        sample = "use sample.int(), inside a random_ function",
        setClass = "classes are not allowed",
        setRefClass = "classes are not allowed",
        R6Class = "classes are not allowed",
        structure = "classes are not allowed",
        sapply = "use a for loop",
        lapply = "use a for loop",
        vapply = "use a for loop",
        mapply = "use a for loop",
        Map = "use a for loop",
        ifelse = "use if and else on single values"
      )),
      undesirable_operator_linter(),
      sample_int_linter(),
      implicit_assignment_linter(),
      for_loop_index_linter(),
      redundant_equals_linter(),
      comparison_negation_linter(),
      outer_negation_linter(),
      unreachable_code_linter(),
      missing_argument_linter(),
      duplicate_argument_linter(),
      numeric_leading_zero_linter(),
      length_test_linter(),
      # this procedure's own rules
      random_prefix_linter(),
      random_calls_no_simulate_linter(),
      r_random_only_in_random_linter(),
      loaded_values_linter(),
      no_default_arguments_linter(),
      nesting_depth_linter(),
      function_length_linter(maximum_lines = 40)
    )
  )
}

# lint the reference implementation with all the rules, and the
# infrastructure, tests and linters with the style linters only; prints the
# lints for each folder and returns the number found
lint_model <- function() {
  folders <- list(
    "model/reference" = reference_linters(),
    "model/infrastructure" = style_linters(),
    "model/tests" = style_linters(),
    "lint" = style_linters()
  )
  number_of_lints <- 0
  for (folder in names(folders)) {
    lints <- lint_dir(folder, linters = folders[[folder]])
    if (length(lints) > 0) {
      print(lints)
    }
    number_of_lints <- number_of_lints + length(lints)
  }
  number_of_lints
}
