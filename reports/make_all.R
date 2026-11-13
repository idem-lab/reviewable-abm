# remake every behaviour figure from the root of the repository. The draws
# (reports/draws/*.csv) take several minutes to simulate; to change only
# how figures look, run the scripts in reports/figures/ alone, which read
# the saved draws.

# run a script in a new R session, stopping if it fails, so that a figure
# is never made from out-of-date draws
run_script <- function(script) {
  message("running ", script)
  status <- system2("Rscript", script)
  if (status != 0) {
    stop(script, " failed")
  }
}

for (script in list.files("reports/draws", pattern = "\\.R$",
                          full.names = TRUE)) {
  run_script(script)
}

for (script in list.files("reports/figures", pattern = "\\.R$",
                          full.names = TRUE)) {
  run_script(script)
}
