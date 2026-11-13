# the links file, model/mapping.yaml (DESIGN.md Section 3)

# the names of the functions defined in the reference implementation
model_functions <- function() {
  files <- list.files(file.path(repository_root, "model/reference"),
                      pattern = "\\.R$", full.names = TRUE)
  names <- c()
  for (file in files) {
    for (expression in parse(file)) {
      is_definition <- is.call(expression) &&
        identical(expression[[1]], as.name("<-")) &&
        is.call(expression[[3]]) &&
        identical(expression[[3]][[1]], as.name("function"))
      if (is_definition) {
        names <- c(names, as.character(expression[[2]]))
      }
    }
  }
  names
}

# the HTML anchors in a markdown file
anchors_in <- function(file) {
  lines <- readLines(file.path(repository_root, file), warn = FALSE)
  matches <- regmatches(lines, regexpr("(?<=<a id=\")[a-z-]+", lines,
                                       perl = TRUE))
  unique(matches)
}

# everything listed under one field of the links file
mapped <- function(field) {
  mapping <- yaml::read_yaml(file.path(repository_root,
                                       "model/mapping.yaml"))$features
  unique(unlist(lapply(mapping, `[[`, field)))
}

test_that("every section named in the links file exists", {
  expect_length(setdiff(mapped("description"),
                        anchors_in("model/description.md")), 0)
  expect_length(setdiff(mapped("maths"), anchors_in("model/maths.md")), 0)
})

test_that("every function named in the links file exists", {
  expect_length(setdiff(mapped("code"), model_functions()), 0)
})

test_that("every figure named in the links file exists", {
  figures <- mapped("figures")
  expect_true(all(file.exists(file.path(repository_root, figures))))
})

test_that("every equation is in the links file", {
  equations <- grep("^eq-", anchors_in("model/maths.md"), value = TRUE)
  expect_length(setdiff(equations, mapped("maths")), 0)
})

test_that("every model function is in the links file", {
  expect_length(setdiff(model_functions(), mapped("code")), 0)
})

test_that("every section of the written description is in the links file", {
  expect_length(setdiff(anchors_in("model/description.md"),
                        mapped("description")), 0)
})
