# checks of the rules in DESIGN.md Section 4 that can be made automatically,
# and of the links file, model/mapping.yaml

# the names of the functions defined in a folder of R files
functions_defined_in <- function(folder) {
  files <- list.files(file.path(repository_root, folder), pattern = "\\.R$",
                      full.names = TRUE)
  names <- c()
  for (file in files) {
    for (expression in parse(file)) {
      if (is.call(expression) && identical(expression[[1]], as.name("<-")) &&
          is.call(expression[[3]]) &&
          identical(expression[[3]][[1]], as.name("function"))) {
        names <- c(names, as.character(expression[[2]]))
      }
    }
  }
  names
}

# the statements in the body of a function
statements_of <- function(name) {
  body <- body(get(name))
  as.list(body)[-1]
}

# the names of variables assigned to with <- anywhere in an expression
assigned_names <- function(expression) {
  names <- c()
  if (is.call(expression)) {
    if (identical(expression[[1]], as.name("<-")) &&
        is.name(expression[[2]])) {
      names <- as.character(expression[[2]])
    }
    for (part in as.list(expression)[-1]) {
      names <- c(names, assigned_names(part))
    }
  }
  names
}

# whether a statement is a call to load_settings() or load_parameters()
is_load_call <- function(statement) {
  is.call(statement) &&
    as.character(statement[[1]])[1] %in% c("load_settings", "load_parameters")
}

model_functions <- functions_defined_in("model/reference")

r_random_functions <- c("runif", "rpois", "rbinom", "rnorm", "rlnorm",
                        "rgamma", "rexp", "sample", "sample.int", "mvrnorm")

test_that("every function that uses random numbers has a random_ or simulate_ prefix", {
  prefixed <- grep("^(random|simulate)_", model_functions, value = TRUE)
  for (name in model_functions) {
    called <- all.names(body(get(name)))
    uses_random <- any(called %in% c(r_random_functions, prefixed))
    if (uses_random) {
      expect_match(name, "^(random|simulate)_", label = name)
    }
  }
})

test_that("functions without a prefix do not use random numbers", {
  prefixed <- grep("^(random|simulate)_", model_functions, value = TRUE)
  for (name in setdiff(model_functions, prefixed)) {
    called <- all.names(body(get(name)))
    expect_false(any(called %in% c(r_random_functions, prefixed)),
                 label = name)
  }
})

test_that("random_ functions never call simulate_ functions", {
  simulators <- grep("^simulate_", model_functions, value = TRUE)
  for (name in grep("^random_", model_functions, value = TRUE)) {
    expect_false(any(all.names(body(get(name))) %in% simulators),
                 label = name)
  }
})

test_that("R's random functions are called only inside random_ functions", {
  for (name in grep("^random_", model_functions, invert = TRUE,
                    value = TRUE)) {
    expect_false(any(all.names(body(get(name))) %in% r_random_functions),
                 label = name)
  }
})

test_that("settings and parameters are loaded before any other code", {
  for (name in model_functions) {
    statements <- statements_of(name)
    is_load <- vapply(statements, is_load_call, logical(1))
    if (any(is_load)) {
      # the load calls are the first statements, with none after others
      expect_equal(which(is_load), seq_len(sum(is_load)), label = name)
    }
  }
})

test_that("loaded names do not clash with arguments and are never assigned to", {
  for (name in model_functions) {
    statements <- statements_of(name)
    loaded <- c()
    for (statement in statements) {
      if (is_load_call(statement)) {
        loaded <- c(loaded, vapply(as.list(statement)[-1], as.character,
                                   character(1)))
      }
    }
    expect_length(intersect(loaded, names(formals(get(name)))), 0)
    assigned <- unlist(lapply(statements, assigned_names))
    expect_length(intersect(loaded, assigned), 0)
  }
})

test_that("every setting and parameter loaded by the model exists", {
  for (name in model_functions) {
    for (statement in statements_of(name)) {
      if (is_load_call(statement)) {
        kind <- as.character(statement[[1]])
        defaults <- if (kind == "load_settings") {
          default_settings
        } else {
          default_parameters
        }
        loaded <- vapply(as.list(statement)[-1], as.character, character(1))
        expect_true(all(loaded %in% names(defaults)), label = name)
      }
    }
  }
})

# the HTML anchors in a markdown file
anchors_in <- function(file) {
  lines <- readLines(file.path(repository_root, file), warn = FALSE)
  matches <- regmatches(lines, regexpr("(?<=<a id=\")[a-z-]+", lines,
                                       perl = TRUE))
  unique(matches)
}

mapping <- yaml::read_yaml(file.path(repository_root,
                                     "model/mapping.yaml"))$features
mapped <- function(field) unique(unlist(lapply(mapping, `[[`, field)))

test_that("everything named in the links file exists", {
  expect_length(setdiff(mapped("description"),
                        anchors_in("model/description.md")), 0)
  expect_length(setdiff(mapped("maths"), anchors_in("model/maths.md")), 0)
  expect_length(setdiff(mapped("code"), model_functions), 0)
  figures <- mapped("figures")
  expect_true(all(file.exists(file.path(repository_root, figures))))
})

test_that("every equation and model function is in the links file", {
  equations <- grep("^eq-", anchors_in("model/maths.md"), value = TRUE)
  expect_length(setdiff(equations, mapped("maths")), 0)
  expect_length(setdiff(model_functions, mapped("code")), 0)
})
