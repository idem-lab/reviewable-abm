# transmission pairs: single infectors, each followed from infection to
# recovery with the model's own functions, meeting a constant rate of
# non-household contact events with fresh contacts who are adults with no
# immunity, so contacts are never depleted. Records the generation interval
# of each transmission (the infector's time since infection when it
# happens) and the number of secondary infections caused by each infector,
# for several profile widths and timestep lengths.

source("reports/helpers.R")

# follow one infector through their infection, in the same order of steps
# as simulate_epidemic(), and return their transmissions
simulate_infector <- function(width, timestep_length) {
  set_values(settings = list(timestep_length = timestep_length),
             parameters = list(viral_load_profile_width = width))
  contacts_per_day <-
    default_parameters$non_household_contact_events_per_person_per_day
  hours_per_contact_event <-
    default_parameters$non_household_contact_event_hours
  infector <- infection(individual_with(age = 30),
                        random_infection_characteristics())
  contact <- individual_with(age = 30)
  generation_intervals <- c()
  repeat {
    # 1. contact events, which may transmit infection
    number_of_contact_events <- random_poisson(contacts_per_day *
                                                 timestep_length)
    for (k in seq_len(number_of_contact_events)) {
      event <- contact_event(c(1, 2), FALSE, hours_per_contact_event)
      probability <- transmission_probability(infector, contact, event)
      if (random_bernoulli(probability)) {
        generation_intervals <- c(generation_intervals,
                                  infector$time_since_infection)
      }
    }
    # 2. recovery
    if (ready_to_recover(infector)) {
      break
    }
    # 3. advance
    infector <- advance_individuals_one_timestep(list(infector))[[1]]
  }
  list(potential_peak_viral_load = infector$potential_peak_viral_load,
       duration = infector$time_since_infection,
       generation_intervals = generation_intervals)
}

conditions <- expand.grid(profile_width = c(0.3, 0.4, 0.55),
                          timestep_length = c(1, 0.1))
infectors_per_condition <- 6000

intervals <- list()
offspring <- list()
for (condition in seq_len(nrow(conditions))) {
  width <- conditions$profile_width[condition]
  timestep_length <- conditions$timestep_length[condition]
  results <- run_in_parallel(infectors_per_condition, function(infector) {
    simulate_infector(width, timestep_length)
  }, seed = condition)
  offspring[[condition]] <- data.frame(
    profile_width = width, timestep_length = timestep_length,
    infector = seq_along(results),
    potential_peak_viral_load = vapply(results, `[[`, numeric(1),
                                       "potential_peak_viral_load"),
    duration = vapply(results, `[[`, numeric(1), "duration"),
    secondary_infections = vapply(results, function(result) {
      length(result$generation_intervals)
    }, numeric(1))
  )
  intervals[[condition]] <- data.frame(
    profile_width = width, timestep_length = timestep_length,
    generation_interval = unlist(lapply(results, `[[`,
                                        "generation_intervals"))
  )
}

write_draws(do.call(rbind, offspring), "offspring")
write_draws(do.call(rbind, intervals), "generation_intervals")
