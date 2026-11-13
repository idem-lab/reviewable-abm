# infection and viral load (maths.md: Viral load)

# infect an individual, with a random viral load level and immunity boost
random_infection <- function(individual) {

  draws <- random_viral_load_level_and_boost_size()

  infection(
    individual,
    viral_load_level = draws$viral_load_level,
    boost_size = draws$boost_size
  )

}

# viral load level and immunity boost size of a new infection: lognormal,
# with correlated logs
random_viral_load_level_and_boost_size <- function() {

  sdlog_level <- parameter("viral_load_level_sdlog")
  sdlog_boost <- parameter("immunity_boost_sdlog")
  correlation <- parameter("viral_load_boost_correlation")

  # the meanlog of the viral load level is fixed at 0
  meanlogs <- c(0, parameter("immunity_boost_meanlog"))
  covariance <- matrix(
    c(sdlog_level ^ 2, correlation * sdlog_level * sdlog_boost,
      correlation * sdlog_level * sdlog_boost, sdlog_boost ^ 2),
    nrow = 2
  )

  logs <- MASS::mvrnorm(1, mu = meanlogs, Sigma = covariance)

  list(
    viral_load_level = exp(logs[1]),
    boost_size = exp(logs[2])
  )

}

# an individual just infected: their immunity is recorded, then boosted
infection <- function(individual, viral_load_level, boost_size) {

  individual$immunity_at_infection <- individual$immunity_level
  individual$infected <- TRUE
  individual$time_since_infection <- 0
  individual$time_since_boost <- 0

  individual$viral_load_level <- viral_load_level
  individual$boost_size <- boost_size
  individual$immunity_after_boost <- individual$immunity_at_infection +
    boost_size

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
    viral_load <- individual$viral_load_level *
      viral_load_profile(individual$time_since_infection) *
      exp(-parameter("viral_load_immunity_effect") *
            individual$immunity_at_infection)
  }

  viral_load

}

# change in viral load with time since infection, in days: a Gaussian curve
# in log time, peaking at 1, and zero at infection
viral_load_profile <- function(time_since_infection) {

  viral_load_profile <- 0

  if (time_since_infection > 0) {
    log_relative_time <- log(time_since_infection /
                               parameter("viral_load_peak_time"))
    viral_load_profile <- exp(-log_relative_time ^ 2 /
                                (2 * parameter("viral_load_profile_width") ^ 2))
  }

  viral_load_profile

}
