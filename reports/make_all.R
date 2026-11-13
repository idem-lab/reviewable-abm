# remake every behaviour figure from the root of the repository. The draws
# (reports/draws/*.csv) take several minutes to simulate; to change only
# how figures look, run the scripts in reports/figures/ alone, which read
# the saved draws.

for (script in list.files("reports/draws", pattern = "\\.R$",
                          full.names = TRUE)) {
  message("simulating ", script)
  system2("Rscript", script)
}

for (script in list.files("reports/figures", pattern = "\\.R$",
                          full.names = TRUE)) {
  message("plotting ", script)
  system2("Rscript", script)
}
