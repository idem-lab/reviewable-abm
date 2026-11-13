# Expected: the probability of transmission rises with contact event
# duration, steeply at first and then levelling off towards 1, as
# 1 - exp(-hazard x duration). It is higher for higher infector viral load
# and in households, where the hazard is multiplied by
# exp(household location score).

source("reports/theme.R")

draws <- read_draws("transmission_probability")
draws$location <- ifelse(draws$in_household, "household", "non-household")

figure <- ggplot(draws, aes(duration, probability,
                            colour = factor(viral_load),
                            linetype = location)) +
  geom_line() +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "contact event duration (hours)",
       y = "probability of transmission",
       colour = "infector viral load", linetype = NULL,
       title = "Transmission during one contact event",
       caption = "Two adults, with no immunity.")

save_figure(figure, "transmission_probability")
