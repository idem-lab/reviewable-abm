# Expected: without waning, the first wave leaves most people with
# lasting, partial immunity, so after it prevalence stays low, with at
# most a little ongoing transmission among people whose immunity is
# small. With waning at 0.02 per day, immunity from a typical boost (about
# 2) is lost after about 100 days, so susceptibility returns across the
# population and a second wave follows the first, starting roughly 100 to
# 200 days after the first peak. Later waves are possible, and their timing
# varies between replicates.

source("reports/theme.R")

draws <- read_draws("resurgence")
draws$waning <- ifelse(draws$immunity_waning_rate == 0,
                       "no waning", "waning at 0.02 per day")

figure <- ggplot(draws, aes(time, prevalence, group = replicate)) +
  geom_line(alpha = 0.3, linewidth = 0.4, colour = figure_colours[1]) +
  facet_wrap(~ waning, ncol = 1) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(x = "day", y = "prevalence (proportion infected)",
       title = "Waning immunity and resurgence over two years",
       caption = paste(length(unique(draws$replicate)),
                       "replicates per panel, population 300."))
save_figure(figure, "resurgence", height = 6)
