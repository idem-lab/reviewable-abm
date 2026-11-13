# viral load and immunity for eight individuals, each infected on day 0
# and reinfected on day 120 with characteristics drawn by the model's
# random_infection_characteristics(), advanced a day at a time

source("reports/helpers.R")

set_values(settings = list(), parameters = list())
set.seed(2)

rows <- list()
for (person in 1:8) {
  individual <- individual_with(age = 30)
  for (day in 0:300) {
    if (day %in% c(0, 120)) {
      individual <- infection(recovery(individual),
                              random_infection_characteristics())
    }
    if (ready_to_recover(individual)) {
      individual <- recovery(individual)
    }
    rows[[length(rows) + 1]] <- data.frame(
      person = person, day = day, infected = individual$infected,
      viral_load = individual$viral_load,
      immunity_level = individual$immunity_level
    )
    individual <- advance_individuals_one_timestep(list(individual))[[1]]
  }
}
write_draws(do.call(rbind, rows), "individual_trajectories")
