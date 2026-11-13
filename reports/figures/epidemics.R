# Expected: most replicates take off, rising to a peak within the first
# two months and then declining as infections end and immunity builds;
# some die out early by chance. Immunity wanes, so the number infected need
# not reach zero, and later waves are possible within 150 days.

source("reports/theme.R")

draws <- read_draws("epidemics")

figure <- ggplot(draws, aes(time, infected, group = replicate)) +
  geom_line(alpha = 0.4, colour = figure_colours[1]) +
  labs(x = "day", y = "number infected",
       title = "Epidemics at the default parameter values",
       caption = paste(length(unique(draws$replicate)),
                       "replicates, population 300,",
                       "5 infected at the start."))

save_figure(figure, "epidemics")
