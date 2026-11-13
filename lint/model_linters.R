# linters for the rules in DESIGN.md Section 4 that are specific to this
# procedure, written with lintr's Linter() on the parse tree of each file.
# lint_model.R combines them with lintr's own linters.

library(lintr)
library(xml2)

# R functions that draw random numbers
r_random_functions <- c("runif", "rpois", "rbinom", "rnorm", "rlnorm",
                        "rgamma", "rexp", "rbeta", "rmultinom", "sample",
                        "sample.int", "mvrnorm")

# the function definitions (name <- function(...) ...) in a file's parse tree
function_definitions <- function(xml) {
  xml_find_all(xml, "//expr[LEFT_ASSIGN and expr[FUNCTION]]")
}

# the name of a function definition
definition_name <- function(definition) {
  xml_text(xml_find_first(definition, "./expr[1]/SYMBOL"))
}

# the names of the functions called inside a function definition
called_functions <- function(definition) {
  xml_text(xml_find_all(definition, ".//SYMBOL_FUNCTION_CALL"))
}

# the statements of a function's body, if it is in braces
body_statements <- function(definition) {
  xml_find_all(definition, "./expr[FUNCTION]/expr[OP-LEFT-BRACE]/expr")
}

# whether a statement is a call to load_settings() or load_parameters()
is_load_statement <- function(statement) {
  called <- xml_text(xml_find_first(statement, "./expr/SYMBOL_FUNCTION_CALL"))
  !is.na(called) && called %in% c("load_settings", "load_parameters")
}

# the names given to load_settings() and load_parameters() in a function
loaded_names <- function(definition) {
  names <- c()
  for (statement in body_statements(definition)) {
    if (is_load_statement(statement)) {
      strings <- xml_text(xml_find_all(statement, "./expr/STR_CONST"))
      names <- c(names, gsub("^[\"']|[\"']$", "", strings))
    }
  }
  names
}

# a lintr linter, with the given name, that runs on whole files
file_linter <- function(name, check) {
  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "file")) {
      return(list())
    }
    check(source_expression)
  }, name = name, linter_level = "file")
}

# add one lint, for one node of the parse tree, to a list of lints
add_lint <- function(lints, node, source_expression, message) {
  c(lints, list(xml_nodes_to_lints(node, source_expression, message,
                                   type = "warning")))
}

# DESIGN.md naming rule 2: a function that uses random numbers, directly or
# through a random_ or simulate_ function, has one of those prefixes, and a
# function that does not has neither
random_prefix_linter <- function() {
  file_linter("random_prefix_linter", function(source_expression) {
    lints <- list()
    for (definition in function_definitions(
      source_expression$full_xml_parsed_content
    )) {
      name <- definition_name(definition)
      called <- called_functions(definition)
      uses_random <- any(called %in% r_random_functions) ||
        any(grepl("^(random|simulate)_", called))
      prefixed <- grepl("^(random|simulate)_", name)
      if (uses_random && !prefixed) {
        lints <- add_lint(
          lints, definition, source_expression,
          paste0(name, "() uses random numbers, so needs a random_ or ",
                 "simulate_ prefix")
        )
      }
      if (prefixed && !uses_random) {
        lints <- add_lint(
          lints, definition, source_expression,
          paste0(name, "() uses no random numbers, so should not have a ",
                 "random_ or simulate_ prefix")
        )
      }
    }
    lints
  })
}

# DESIGN.md naming rule 2: random_ functions only draw, and never call a
# simulate_ function
random_calls_no_simulate_linter <- function() {
  file_linter("random_calls_no_simulate_linter", function(source_expression) {
    lints <- list()
    for (definition in function_definitions(
      source_expression$full_xml_parsed_content
    )) {
      name <- definition_name(definition)
      calls_simulate <- any(grepl("^simulate_", called_functions(definition)))
      if (grepl("^random_", name) && calls_simulate) {
        lints <- add_lint(
          lints, definition, source_expression,
          paste0(name, "() is a random_ function, so must not call a ",
                 "simulate_ function")
        )
      }
    }
    lints
  })
}

# DESIGN.md language rule 9: R's random number functions are called only
# inside random_ functions
r_random_only_in_random_linter <- function() {
  file_linter("r_random_only_in_random_linter", function(source_expression) {
    lints <- list()
    for (definition in function_definitions(
      source_expression$full_xml_parsed_content
    )) {
      name <- definition_name(definition)
      if (!grepl("^random_", name)) {
        calls <- xml_find_all(definition, ".//SYMBOL_FUNCTION_CALL")
        for (call in calls) {
          if (xml_text(call) %in% r_random_functions) {
            lints <- add_lint(
              lints, call, source_expression,
              paste0(xml_text(call), "() may only be called inside a ",
                     "random_ function")
            )
          }
        }
      }
    }
    lints
  })
}

# DESIGN.md language rule 5: load_settings() and load_parameters() come
# before any other code in a function, their names do not clash with the
# function's arguments, and the loaded variables are never assigned to
loaded_values_linter <- function() {
  file_linter("loaded_values_linter", function(source_expression) {
    lints <- list()
    for (definition in function_definitions(
      source_expression$full_xml_parsed_content
    )) {
      name <- definition_name(definition)
      statements <- body_statements(definition)
      is_load <- vapply(statements, is_load_statement, logical(1))
      # the load calls should be the first statements, in a block
      load_positions <- which(is_load)
      if (!identical(load_positions, seq_along(load_positions))) {
        lints <- add_lint(
          lints, statements[[load_positions[1]]], source_expression,
          paste0("in ", name, "(), load_settings() and load_parameters() ",
                 "must come before any other code")
        )
      }
      loaded <- loaded_names(definition)
      arguments <- xml_text(xml_find_all(definition,
                                         "./expr/SYMBOL_FORMALS"))
      for (clash in intersect(loaded, arguments)) {
        lints <- add_lint(
          lints, definition, source_expression,
          paste0("in ", name, "(), the loaded name ", clash,
                 " is also an argument")
        )
      }
      assignments <- xml_find_all(
        definition, ".//expr[LEFT_ASSIGN or EQ_ASSIGN]/expr[1]/SYMBOL"
      )
      for (assignment in assignments) {
        if (xml_text(assignment) %in% loaded) {
          lints <- add_lint(
            lints, assignment, source_expression,
            paste0("in ", name, "(), the loaded value ", xml_text(assignment),
                   " must not be assigned to")
          )
        }
      }
    }
    lints
  })
}

# DESIGN.md language rule 4: no default argument values
no_default_arguments_linter <- function() {
  file_linter("no_default_arguments_linter", function(source_expression) {
    defaults <- xml_find_all(
      source_expression$full_xml_parsed_content,
      "//expr[FUNCTION]/EQ_FORMALS"
    )
    xml_nodes_to_lints(defaults, source_expression,
                       "arguments must not have default values",
                       type = "warning")
  })
}

# DESIGN.md "When to write a function": no more than two levels of nested
# loops and ifs
nesting_depth_linter <- function() {
  file_linter("nesting_depth_linter", function(source_expression) {
    too_deep <- xml_find_all(
      source_expression$full_xml_parsed_content,
      paste0("//expr[(FOR or WHILE or IF) and ",
             "count(ancestor::expr[FOR or WHILE or IF]) >= 2]")
    )
    xml_nodes_to_lints(too_deep, source_expression,
                       paste0("more than two levels of nested loops and ",
                              "ifs; write a separate function"),
                       type = "warning")
  })
}

# DESIGN.md "When to write a function": keep functions under about 40 lines
function_length_linter <- function(maximum_lines) {
  file_linter("function_length_linter", function(source_expression) {
    lints <- list()
    for (definition in function_definitions(
      source_expression$full_xml_parsed_content
    )) {
      lines <- as.integer(xml_attr(definition, "line2")) -
        as.integer(xml_attr(definition, "line1")) + 1
      if (lines > maximum_lines) {
        lints <- add_lint(
          lints, definition, source_expression,
          paste0(definition_name(definition), "() is ", lines,
                 " lines; keep functions under about ", maximum_lines)
        )
      }
    }
    lints
  })
}
