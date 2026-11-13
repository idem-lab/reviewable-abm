# household transmission: single households, each with one index case and
# everyone else susceptible, with household contact events only, followed
# with the model's own functions until no one is infected. Each
# transmission is attributed to its infector, giving the secondary attack
# rate (the proportion of other members infected by the index case) and
# the household final attack rate (the proportion of other members ever
# infected), across household location scores and household sizes. Ages
# are drawn as in the model.

source("reports/helpers.R")

# follow one household of the given size, with member 1 the index case,
# resolving contact events as simulate_contact_event() does but recording
# who infected whom
simulate_household <- function(household_size, location_score) {
  set_values(settings = list(),
             parameters = list(household_location_score = location_score))
  household <- list(member_indices = seq_len(household_size))
  population <- list()
  for (i in household$member_indices) {
    population[[i]] <- simulate_new_individual(household_index = 1)
  }
  population[[1]] <- infection(population[[1]],
                               random_infection_characteristics())
  infectors <- rep(NA, household_size)
  repeat {
    contact_events <- random_order(contact_events_in_household(household))
    for (k in seq_along(contact_events)) {
      i <- contact_events[[k]]$individual_indices[1]
      j <- contact_events[[k]]$individual_indices[2]
      if (population[[i]]$infected != population[[j]]$infected) {
        a <- if (population[[i]]$infected) i else j
        b <- if (population[[i]]$infected) j else i
        probability <- transmission_probability(population[[a]],
                                                population[[b]],
                                                contact_events[[k]])
        if (random_bernoulli(probability)) {
          population[[b]] <- infection(population[[b]],
                                       random_infection_characteristics())
          infectors[b] <- a
        }
      }
    }
    population <- recover_individuals(population)
    infected <- vapply(population, `[[`, logical(1), "infected")
    if (!any(infected)) {
      break
    }
    population <- advance_individuals_one_timestep(population)
  }
  others <- household_size - 1
  data.frame(
    household_size = household_size,
    household_location_score = location_score,
    secondary_attack_rate = sum(infectors %in% 1) / others,
    final_attack_rate = sum(!is.na(infectors)) / others
  )
}

conditions <- expand.grid(household_size = c(2, 3, 4, 6),
                          location_score = c(0, 0.35, 0.7, 1.05, 1.4))
households_per_condition <- 2000

rows <- list()
for (condition in seq_len(nrow(conditions))) {
  results <- run_in_parallel(households_per_condition, function(household) {
    simulate_household(conditions$household_size[condition],
                       conditions$location_score[condition])
  }, seed = condition)
  rows[[condition]] <- do.call(rbind, results)
}

write_draws(do.call(rbind, rows), "household_transmission")
