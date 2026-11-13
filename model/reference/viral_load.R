# infection and viral load (maths.md: Viral load)

# characteristics of a new infection, its potential peak viral load and
# immunity boost size: lognormal, with correlated logs
random_infection_characteristics <- function() {

  load_parameters("potential_peak_viral_load_sdlog",
                  "immunity_boost_meanlog",
                  "immunity_boost_sdlog",
                  "viral_load_boost_correlation")

  # in the order (potential peak viral load, boost size); the meanlog of the
  # potential peak viral load is fixed at 0
  meanlogs <- c(0, immunity_boost_meanlog)
  covariance_of_logs <- viral_load_boost_correlation *
    potential_peak_viral_load_sdlog * immunity_boost_sdlog
  covariance <- matrix(
    c(potential_peak_viral_load_sdlog ^ 2, covariance_of_logs,
      covariance_of_logs, immunity_boost_sdlog ^ 2),
    nrow = 2
  )

  # the first is the log potential peak viral load and the second the log
  # boost size, in the order of meanlogs
  logs <- random_multivariate_normal(meanlogs, covariance)

  list(
    potential_peak_viral_load = exp(logs[1]),
    boost_size = exp(logs[2])
  )

}

# an individual just infected, with the given characteristics of the
# infection: their immunity is recorded, then boosted
infection <- function(individual, infection_characteristics) {

  individual$immunity_at_infection <- individual$immunity_level
  individual$infected <- TRUE
  individual$timesteps_since_infection <- 0
  individual$timesteps_since_boost <- 0

  individual$potential_peak_viral_load <-
    infection_characteristics$potential_peak_viral_load
  individual$boost_size <- infection_characteristics$boost_size
  individual$immunity_after_boost <- individual$immunity_at_infection +
    individual$boost_size

  # levels at zero elapsed time
  individual$viral_load <- viral_load(individual)
  individual$immunity_level <- immunity_level(individual)

  individual

}

# viral load of an individual, on a scale where a typical infection with no
# immunity peaks at 1; zero if not infected
viral_load <- function(individual) {

  viral_load <- 0

  if (individual$infected) {
    viral_load <- peak_viral_load(individual) *
      viral_load_profile(time_since_infection(individual))
  }

  viral_load

}

# peak viral load of the individual's current or most recent infection: the
# potential peak, reduced by the immunity they had when infected
peak_viral_load <- function(individual) {

  individual$potential_peak_viral_load *
    viral_load_immunity_multiplier(individual$immunity_at_infection)

}

# change in viral load with time since infection, in days: a Gaussian curve
# in log time, peaking at 1, and zero at infection
viral_load_profile <- function(time_since_infection) {

  load_parameters("viral_load_peak_time", "viral_load_profile_width")

  viral_load_profile <- 0

  if (time_since_infection > 0) {
    log_relative_time <- log(time_since_infection / viral_load_peak_time)
    viral_load_profile <- exp(-log_relative_time ^ 2 /
                                (2 * viral_load_profile_width ^ 2))
  }

  viral_load_profile

}

# reduction in viral load throughout an infection from the immunity the
# individual had when infected, as a multiplier: 1 with no immunity
viral_load_immunity_multiplier <- function(immunity_at_infection) {

  load_parameters("viral_load_immunity_effect")

  exp(-viral_load_immunity_effect * immunity_at_infection)

}
