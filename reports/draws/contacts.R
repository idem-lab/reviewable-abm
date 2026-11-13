# household sizes, and contact events per person in one timestep by
# location, from the model's simulate_households() and
# simulate_contact_events(), in a population of 2000

source("reports/helpers.R")

set_values(settings = list(population_size = 2000), parameters = list())
set.seed(1)
households <- simulate_households()
population <- simulate_initial_population(households)
contact_events <- simulate_contact_events(population, households)

household_sizes <- data.frame(
  household_size = vapply(households, function(household) {
    length(household$member_indices)
  }, numeric(1))
)
write_draws(household_sizes, "household_sizes")

# each contact event counts for both individuals in it
counts <- data.frame(individual = seq_along(population), household = 0,
                     non_household = 0)
for (event in contact_events) {
  location <- if (event$in_household) "household" else "non_household"
  for (i in event$individual_indices) {
    counts[i, location] <- counts[i, location] + 1
  }
}
write_draws(counts, "contacts_per_person")
