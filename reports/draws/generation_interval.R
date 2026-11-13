# the intrinsic generation interval: the viral load profile, from the
# model's viral_load_profile(), scaled to integrate to 1, and the lognormal
# density that maths.md says it equals, for several profile widths

source("reports/helpers.R")

profile_widths <- c(0.3, 0.4, 0.55)
times <- seq(0.01, 25, by = 0.01)
peak_time <- default_parameters$viral_load_peak_time

rows <- list()
for (width in profile_widths) {
  set_values(settings = list(),
             parameters = list(viral_load_profile_width = width))
  profile <- vapply(times, viral_load_profile, numeric(1))
  rows[[length(rows) + 1]] <- data.frame(
    profile_width = width,
    time_since_infection = times,
    from_profile = profile / sum(profile * 0.01),
    lognormal = dlnorm(times, meanlog = log(peak_time) + width ^ 2,
                       sdlog = width)
  )
}

write_draws(do.call(rbind, rows), "generation_interval")
