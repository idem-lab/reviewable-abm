# infrastructure, not part of the model: load the reference implementation
# and its infrastructure. From the root of the repository, run
# `source("model/infrastructure/load_model.R")`, and then, for example,
# `run_model(settings = list(), parameters = list(immunity_waning_rate =
# 0.02))`.

for (file in list.files("model/reference", pattern = "\\.R$",
                        full.names = TRUE)) {
  source(file)
}

for (file in list.files("model/infrastructure", pattern = "\\.R$",
                        full.names = TRUE)) {
  if (basename(file) != "load_model.R") {
    source(file)
  }
}
