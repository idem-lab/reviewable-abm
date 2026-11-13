# Expected: at the default values, transmission is high enough that nearly
# every replicate started by 5 infections in 300 people takes off.
# Incidence and prevalence rise to a peak within the first two months and
# then decline as people recover and become immune. Immunity at the
# default waning rate lasts about 200 days, so within 150 days there is no
# second wave, and prevalence falls towards zero; replicates differ in the
# timing and height of the peak.

source("reports/theme.R")
library(patchwork)

draws <- read_draws("epidemics")

incidence_figure <- ggplot(draws, aes(time, new_infections,
                                      group = replicate)) +
  geom_line(alpha = 0.3, colour = figure_colours[2]) +
  labs(x = "day", y = "incidence (new infections per day)",
       title = "Incidence")

prevalence_figure <- ggplot(draws, aes(time, prevalence,
                                       group = replicate)) +
  geom_line(alpha = 0.3, colour = figure_colours[1]) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(x = "day", y = "prevalence (proportion infected)",
       title = "Prevalence")

figure <- incidence_figure / prevalence_figure +
  plot_annotation(
    title = "Epidemics at the default parameter values",
    caption = paste(length(unique(draws$replicate)),
                    "replicates, population 300, 5 infected at the start.")
  )
save_figure(figure, "epidemics", height = 7)
