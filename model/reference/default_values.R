# default values of the settings and parameters of the model, which are
# illustrative and not calibrated to any pathogen; see the notation tables
# in maths.md for their meanings and units. A run can change any of them
# (model/infrastructure/run_model.R), and model functions read them with
# load_settings() and load_parameters().

default_settings <- list(
  population_size = 500,
  average_household_size = 4,
  initial_infections = 5,
  timestep_length = 1, # days
  number_of_timesteps = 150,
  maximum_initial_age = 80, # years
  adult_age = 18, # years
  recovery_viral_load_threshold = 0.001 # fraction of a typical peak
)

default_parameters <- list(
  baseline_transmission_hazard = 0.015, # per hour
  child_infectiousness_score = -0.2,
  child_susceptibility_score = -0.4,
  household_location_score = 0.7,
  household_contact_event_hours_per_day = 6,
  non_household_contact_event_hours = 0.5,
  non_household_contact_events_per_person_per_day = 10,
  viral_load_level_sdlog = 1,
  viral_load_peak_time = 4, # days
  viral_load_profile_width = 0.4,
  viral_load_immunity_effect = 0.5,
  immunity_boost_meanlog = log(2),
  immunity_boost_sdlog = 0.5,
  viral_load_boost_correlation = 0.5,
  immunity_waning_rate = 0.01 # log hazard ratio per day
)
