# the rules in DESIGN.md Section 4 that the linter checks (lint/)

test_that("the model and its tests have no lints", {
  old <- setwd(repository_root)
  on.exit(setwd(old))
  source("lint/lint_model.R", local = TRUE)
  expect_equal(lint_model(), 0)
})
