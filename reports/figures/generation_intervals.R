# Expected: with constant contact and contacts who are never depleted, the
# generation intervals of transmission pairs follow the intrinsic
# generation interval, a lognormal with meanlog log(4) + width^2 and sdlog
# equal to the width (maths.md, eq-generation-interval), whatever the
# infectors' peak viral loads, because the peak scales the whole profile.
# Truncation at recovery removes a negligible tail. With timesteps of 0.1
# days the distribution matches the lognormal closely.
# With timesteps of 1 day, transmission can only happen at whole days of
# time since infection, using the viral load at the start of each day, so
# the generation intervals are the lognormal density evaluated at whole
# days, normalised.

source("reports/theme.R")

draws <- read_draws("generation_intervals")
draws$width <- paste("profile width", draws$profile_width)
draws$timestep <- paste("timestep", draws$timestep_length, "days")

# the intrinsic generation interval, as a continuous density for timesteps
# of 0.1 days, and evaluated at whole days and normalised for timesteps of
# 1 day
continuous <- expand.grid(profile_width = unique(draws$profile_width),
                          time = seq(0.05, 30, by = 0.05))
continuous$density <- dlnorm(continuous$time,
                             meanlog = log(4) + continuous$profile_width ^ 2,
                             sdlog = continuous$profile_width)
continuous$timestep <- "timestep 0.1 days"
whole_days <- expand.grid(profile_width = unique(draws$profile_width),
                          time = 1:30)
whole_days$density <- dlnorm(whole_days$time,
                             meanlog = log(4) + whole_days$profile_width ^ 2,
                             sdlog = whole_days$profile_width)
whole_days$density <- whole_days$density /
  ave(whole_days$density, whole_days$profile_width, FUN = sum)
whole_days$timestep <- "timestep 1 days"
continuous$width <- paste("profile width", continuous$profile_width)
whole_days$width <- paste("profile width", whole_days$profile_width)

fine <- draws[draws$timestep_length == 0.1, ]
coarse <- draws[draws$timestep_length == 1, ]

figure <- ggplot() +
  geom_histogram(data = fine, aes(generation_interval,
                                  y = after_stat(density)),
                 binwidth = 0.5, boundary = 0, fill = data_colour,
                 alpha = 0.6) +
  geom_histogram(data = coarse, aes(generation_interval,
                                    y = after_stat(density)),
                 binwidth = 1, center = 0, fill = data_colour,
                 alpha = 0.6) +
  geom_line(data = continuous, aes(time, density),
            colour = expectation_colour) +
  geom_point(data = whole_days, aes(time, density),
             colour = expectation_colour) +
  facet_grid(timestep ~ width) +
  coord_cartesian(xlim = c(0, 20)) +
  labs(x = "generation interval (days)", y = "density",
       title = "Generation intervals of transmission pairs",
       caption = paste(
         "Bars: transmission pairs from 6000 infectors per panel, with",
         "constant contacts who are never depleted.",
         "\nBlack: the intrinsic generation interval in maths.md;",
         "points are its density at whole days, normalised."
       ))
save_figure(figure, "generation_intervals", width = 10, height = 6)
