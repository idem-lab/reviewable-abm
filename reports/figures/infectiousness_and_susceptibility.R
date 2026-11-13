# Expected: relative infectiousness is proportional to viral load, a
# straight line through the origin, and children's is lower by the factor
# exp(child infectiousness score) = exp(-0.2), about 0.82, at every viral
# load, so the child line has a shallower slope.
# Relative susceptibility steps down at the adult age (18) for children by
# exp(child susceptibility score) = exp(-0.4), about 0.67, and falls
# exponentially with immunity level, as exp(-immunity), at every age, so
# age and immunity multiply and do not interact on the log scale.

source("reports/theme.R")
library(patchwork)

infectiousness <- read_draws("infectiousness")
infectiousness <- infectiousness[infectiousness$age %in% c(10, 30), ]
infectiousness$age_group <- ifelse(infectiousness$age < 18,
                                   "child (age 10)", "adult (age 30)")
susceptibility <- read_draws("susceptibility")

by_viral_load <- ggplot(infectiousness,
                        aes(viral_load, relative_infectiousness,
                            colour = age_group)) +
  geom_line() +
  labs(x = "viral load", y = "relative infectiousness", colour = NULL,
       title = "Infectiousness by viral load")

by_age <- ggplot(susceptibility[susceptibility$immunity_level %in%
                                  c(0, 1, 2), ],
                 aes(age, relative_susceptibility,
                     colour = factor(immunity_level))) +
  geom_step() +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "age (years)", y = "relative susceptibility",
       colour = "immunity level", title = "Susceptibility by age")

by_immunity <- ggplot(susceptibility[susceptibility$age %in% c(10, 30), ],
                      aes(immunity_level, relative_susceptibility,
                          colour = ifelse(age < 18, "child (age 10)",
                                          "adult (age 30)"))) +
  geom_line() +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "immunity level", y = "relative susceptibility", colour = NULL,
       title = "Susceptibility by immunity")

by_age_and_immunity <- ggplot(susceptibility,
                              aes(age, immunity_level,
                                  fill = relative_susceptibility)) +
  geom_raster() +
  scale_fill_viridis_c(limits = c(0, 1)) +
  labs(x = "age (years)", y = "immunity level",
       fill = "relative\nsusceptibility",
       title = "Susceptibility by age and immunity") +
  theme(legend.position = "right")

figure <- (by_viral_load + by_immunity) / (by_age + by_age_and_immunity) +
  plot_annotation(caption = paste(
    "Relative to an adult with viral load 1 (infectiousness) or an adult",
    "with no immunity (susceptibility)."
  ))
save_figure(figure, "infectiousness_and_susceptibility", width = 10,
            height = 8)
