# Expected: the secondary attack rate, the proportion of other household
# members infected by the index case, rises with the household location
# score, because the score multiplies the hazard of every household contact
# event. For an adult index case meeting an adult with no immunity, the
# chance over a whole infection is about 0.38, 0.56 and 0.73 at scores of
# 0, 0.7 and 1.4; with ages drawn as in the model, children's lower
# infectiousness and susceptibility make it a little lower. It changes
# little with household size, falling slightly in larger households, where
# other members are more often infected first by someone else. The
# household final attack rate, the proportion of other members ever
# infected, is higher than the secondary attack rate, because members
# infected by the index case go on to infect others; the difference grows
# with household size and with the score, and the final attack rate
# approaches 1 at high scores.

source("reports/theme.R")

draws <- read_draws("household_transmission")
summaries <- list()
for (measure in c("secondary_attack_rate", "final_attack_rate")) {
  means <- aggregate(draws[[measure]],
                     by = list(household_size = draws$household_size,
                               score = draws$household_location_score),
                     FUN = mean)
  errors <- aggregate(draws[[measure]],
                      by = list(household_size = draws$household_size,
                                score = draws$household_location_score),
                      FUN = function(x) sd(x) / sqrt(length(x)))
  summaries[[measure]] <- data.frame(
    means[, c("household_size", "score")],
    measure = ifelse(measure == "secondary_attack_rate",
                     "secondary attack rate",
                     "household final attack rate"),
    mean = means$x, lower = means$x - 1.96 * errors$x,
    upper = means$x + 1.96 * errors$x
  )
}
summaries <- do.call(rbind, summaries)
summaries$measure <- factor(summaries$measure,
                            levels = c("secondary attack rate",
                                       "household final attack rate"))

figure <- ggplot(summaries, aes(score, mean,
                                colour = factor(household_size))) +
  geom_ribbon(aes(ymin = lower, ymax = upper,
                  fill = factor(household_size)),
              colour = NA, alpha = 0.2, show.legend = FALSE) +
  geom_line() +
  facet_wrap(~ measure) +
  scale_colour_household_size(aesthetics = c("colour", "fill")) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "household location score", y = "proportion of other members",
       colour = "household size",
       title = "Transmission within households",
       caption = paste(
         "2000 households per point, each with one index case and no",
         "immunity, and household contact events only.",
         "\nRibbons: 95% intervals for the mean."
       ))
save_figure(figure, "household_transmission", width = 9)
