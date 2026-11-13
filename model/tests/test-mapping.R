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

# the features in the links file
features <- function() {
  yaml::read_yaml(file.path(repository_root, "model/mapping.yaml"))$features
}

# everything listed under one field of the links file
mapped <- function(field) {
  unique(unlist(lapply(features(), `[[`, field)))
}

# the behaviour figures in reports/figures/
figure_files <- function() {
  file.path("reports/figures",
            list.files(file.path(repository_root, "reports/figures"),
                       pattern = "\\.png$"))
}

test_that("every feature has exactly the expected fields", {
  for (feature in features()) {
    expect_setequal(names(feature), c("name", "description", "maths", "code",
                                      "figures"))
  }
})

test_that("every section named in the links file exists", {
  expect_setequal(setdiff(mapped("description"),
                          anchors_in("model/description.md")),
                  character(0))
  expect_setequal(setdiff(mapped("maths"), anchors_in("model/maths.md")),
                  character(0))
})

test_that("every function named in the links file exists", {
  expect_setequal(setdiff(mapped("code"), model_functions()), character(0))
})

test_that("every figure named in the links file exists", {
  expect_setequal(setdiff(mapped("figures"), figure_files()), character(0))
})

test_that("every equation is in the links file", {
  equations <- grep("^eq-", anchors_in("model/maths.md"), value = TRUE)
  expect_setequal(setdiff(equations, mapped("maths")), character(0))
})

test_that("every model function is in the links file", {
  expect_setequal(setdiff(model_functions(), mapped("code")), character(0))
})

test_that("every section of the written description is in the links file", {
  expect_setequal(setdiff(anchors_in("model/description.md"),
                          mapped("description")),
                  character(0))
})

test_that("every behaviour figure is in the links file", {
  expect_setequal(setdiff(figure_files(), mapped("figures")), character(0))
})
