# linters for the rules in DESIGN.md Section 4 that are specific to this
# procedure, written with lintr's Linter() on the parse tree of each file.
# lint_model.R combines them with lintr's own linters, and
# model/tests/test-linters.R checks that each catches what it should.

library(lintr)
library(xml2)

# R functions that draw random numbers: every r<name> in stats that has a
# matching density d<name> (rnorm, rpois, rnbinom, rweibull, ...), plus the
# rest of base R's random number functions and MASS::mvrnorm
r_random_functions <- function() {
  stats_functions <- ls("package:stats")
  distributions <- sub("^d", "", grep("^d[a-z]+$", stats_functions,
                                      value = TRUE))
  random <- intersect(paste0("r", distributions), stats_functions)
  c(random, "rWishart", "r2dtable", "sample", "sample.int", "mvrnorm")
}

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

# the calls to load_settings() or load_parameters() anywhere in a function
load_calls <- function(definition) {
  xml_find_all(definition, paste0(
    ".//expr[expr/SYMBOL_FUNCTION_CALL[text() = 'load_settings' or ",
    "text() = 'load_parameters']]"
  ))
}

# whether a statement is itself a call to one of the load functions
is_load_statement <- function(statement) {
  load_call <- paste0(
    "self::expr[expr/SYMBOL_FUNCTION_CALL[text() = 'load_settings' or ",
    "text() = 'load_parameters']]"
  )
  length(xml_find_all(statement, load_call)) > 0
}

# the names given to the load calls in a function
loaded_names <- function(definition) {
  strings <- xml_text(xml_find_all(load_calls(definition), "./expr/STR_CONST"))
  gsub("^[\"']|[\"']$", "", strings)
}

# a lintr linter, with the given name, that runs once on each whole file
file_linter <- function(name, check) {
  Linter(function(source_expression) {
    check(source_expression$full_xml_parsed_content, source_expression)
  }, name = name, linter_level = "file")
}

# lints for a set of nodes of the parse tree, each with the same message
lints_for <- function(nodes, source_expression, message) {
  xml_nodes_to_lints(nodes, source_expression, message, type = "warning")
}

# add one lint, for one node of the parse tree, to a list of lints
add_lint <- function(lints, node, source_expression, message) {
  c(lints, list(lints_for(node, source_expression, message)))
}

# DESIGN.md naming rule 2: a function that uses random numbers, directly or
# through a random_ or simulate_ function, has one of those prefixes, and a
# function that does not has neither; a random_ function never calls a
# simulate_ function
random_prefix_linter <- function() {
  random_functions <- r_random_functions()
  check <- function(xml, source_expression) {
    lints <- list()
    for (definition in function_definitions(xml)) {
      name <- definition_name(definition)
      called <- called_functions(definition)
      uses_random <- any(called %in% random_functions) ||
        any(grepl("^(random|simulate)_", called))
      prefixed <- grepl("^(random|simulate)_", name)
      if (uses_random && !prefixed) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          name, "() uses random numbers, so needs a random_ or simulate_ ",
          "prefix"
        ))
      }
      if (prefixed && !uses_random) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          name, "() uses no random numbers, so should not have a random_ ",
          "or simulate_ prefix"
        ))
      }
      if (grepl("^random_", name) && any(grepl("^simulate_", called))) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          name, "() is a random_ function, so must not call a simulate_ ",
          "function"
        ))
      }
    }
    lints
  }
  file_linter("random_prefix_linter", check)
}

# DESIGN.md language rule 9: R's random number functions are called only
# inside random_ functions
r_random_only_in_random_linter <- function() {
  random_functions <- r_random_functions()
  check <- function(xml, source_expression) {
    lints <- list()
    for (definition in function_definitions(xml)) {
      if (!grepl("^random_", definition_name(definition))) {
        calls <- xml_find_all(definition, ".//SYMBOL_FUNCTION_CALL")
        calls <- calls[xml_text(calls) %in% random_functions]
        lints <- c(lints, list(lints_for(
          calls, source_expression,
          "R's random functions may only be called in a random_ function"
        )))
      }
    }
    lints
  }
  file_linter("r_random_only_in_random_linter", check)
}

# DESIGN.md language rule 5: load_settings() and load_parameters() are the
# first statements of a function, their names do not clash with the
# function's arguments, and the loaded variables are never assigned to, in
# any form
loaded_values_linter <- function() {
  check <- function(xml, source_expression) {
    lints <- list()
    for (definition in function_definitions(xml)) {
      name <- definition_name(definition)
      statements <- body_statements(definition)
      is_load <- vapply(statements, is_load_statement, logical(1))
      load_positions <- which(is_load)
      # every load call must be a whole statement, and those statements
      # must come first, in a block
      out_of_place <- length(load_calls(definition)) >
        length(load_positions) ||
        !identical(load_positions, seq_along(load_positions))
      if (out_of_place) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          "in ", name, "(), load_settings() and load_parameters() must be ",
          "the first statements of the function"
        ))
      }
      loaded <- loaded_names(definition)
      arguments <- xml_text(xml_find_all(definition, "./expr/SYMBOL_FORMALS"))
      for (clash in intersect(loaded, arguments)) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          "in ", name, "(), the loaded name ", clash, " is also an argument"
        ))
      }
      # the variables changed by any assignment: the first symbol on the
      # left of <- or =, or on the right of ->, and loop variables
      targets <- xml_find_all(definition, paste0(
        ".//expr[LEFT_ASSIGN or EQ_ASSIGN]/expr[1]/descendant::SYMBOL[1] | ",
        ".//expr[RIGHT_ASSIGN]/expr[2]/descendant::SYMBOL[1] | ",
        ".//forcond/SYMBOL"
      ))
      targets <- targets[xml_text(targets) %in% loaded]
      lints <- c(lints, list(lints_for(
        targets, source_expression,
        paste0("in ", name, "(), loaded values must not be assigned to")
      )))
    }
    lints
  }
  file_linter("loaded_values_linter", check)
}

# DESIGN.md language rule 4: no default argument values
no_default_arguments_linter <- function() {
  check <- function(xml, source_expression) {
    lints_for(xml_find_all(xml, "//expr[FUNCTION]/EQ_FORMALS"),
              source_expression,
              "arguments must not have default values")
  }
  file_linter("no_default_arguments_linter", check)
}

# DESIGN.md language rule 8: seq_len(n) rather than 1:n, whatever n is
# (lintr's seq_linter only catches forms such as 1:length(x))
one_to_n_linter <- function() {
  check <- function(xml, source_expression) {
    lints_for(
      xml_find_all(xml, paste0(
        "//expr[OP-COLON and expr[1]/NUM_CONST[text() = '1'] and ",
        "not(expr[2]/NUM_CONST)]"
      )),
      source_expression,
      "use seq_len(n) or seq_along(x), not 1:n, which counts down when n is 0"
    )
  }
  file_linter("one_to_n_linter", check)
}

# DESIGN.md language rule 1: no packages, except a distribution called
# with MASS::
package_call_linter <- function() {
  check <- function(xml, source_expression) {
    packages <- xml_find_all(xml, "//SYMBOL_PACKAGE[text() != 'MASS']")
    lints_for(packages, source_expression,
              "only base R is allowed, apart from a distribution from MASS")
  }
  file_linter("package_call_linter", check)
}

# DESIGN.md language rule 11: combine single TRUE/FALSE values with && and
# ||, never & and |
vector_logic_anywhere_linter <- function() {
  check <- function(xml, source_expression) {
    lints_for(xml_find_all(xml, "//AND | //OR"),
              source_expression,
              "combine single TRUE/FALSE values with && and ||")
  }
  file_linter("vector_logic_anywhere_linter", check)
}

# DESIGN.md language rule 5: model code does not set values or the clock,
# apart from simulate_epidemic() setting the clock
infrastructure_call_linter <- function() {
  check <- function(xml, source_expression) {
    lints <- list()
    for (definition in function_definitions(xml)) {
      calls <- xml_find_all(definition, ".//SYMBOL_FUNCTION_CALL")
      forbidden <- c("set_values", "reset_clock", "run_model")
      if (definition_name(definition) != "simulate_epidemic") {
        forbidden <- c(forbidden, "set_clock_to_timestep")
      }
      lints <- c(lints, list(lints_for(
        calls[xml_text(calls) %in% forbidden], source_expression,
        "model code must not set values or the clock"
      )))
    }
    lints
  }
  file_linter("infrastructure_call_linter", check)
}

# DESIGN.md "When to write a function": no more than two levels of nested
# loops and ifs; an else if continues its if, so is not a level of its own
nesting_depth_linter <- function() {
  level <- "(FOR or WHILE or (IF and not(preceding-sibling::ELSE)))"
  check <- function(xml, source_expression) {
    too_deep <- xml_find_all(xml, paste0(
      "//expr[", level, " and count(ancestor::expr[", level, "]) >= 2]"
    ))
    lints_for(too_deep, source_expression, paste0(
      "more than two levels of nested loops and ifs; write a separate ",
      "function"
    ))
  }
  file_linter("nesting_depth_linter", check)
}

# DESIGN.md "When to write a function": keep functions under about 40 lines
function_length_linter <- function(maximum_lines) {
  check <- function(xml, source_expression) {
    lints <- list()
    for (definition in function_definitions(xml)) {
      lines <- as.integer(xml_attr(definition, "line2")) -
        as.integer(xml_attr(definition, "line1")) + 1
      if (lines > maximum_lines) {
        lints <- add_lint(lints, definition, source_expression, paste0(
          definition_name(definition), "() is ", lines,
          " lines; keep functions under about ", maximum_lines
        ))
      }
    }
    lints
  }
  file_linter("function_length_linter", check)
}
