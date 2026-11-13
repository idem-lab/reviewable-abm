# Expected: transmission is lowered from the defaults so that the first
# wave infects fewer people. Without waning, the first wave leaves most of
# those infected with lasting, partial immunity, and infection dies out or
# persists at a low level. With waning at 0.04 per day, immunity from a
# typical boost (about 2) is lost after about 50 days, so susceptibility
# returns and, where infection has not died out, a second wave follows the
# first, with later waves possible. Some replicates die out after the first
# wave in both panels, because there are no imported infections.

source("reports/theme.R")

draws <- read_draws("resurgence")
draws$waning <- ifelse(draws$immunity_waning_rate == 0,
                       "no waning", "waning at 0.04 per day")

figure <- ggplot(draws, aes(time, prevalence, group = replicate)) +
  geom_line(alpha = 0.4, linewidth = 0.5, colour = data_colour) +
  facet_wrap(~ waning, ncol = 1) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(x = "day", y = "prevalence (proportion infected)",
       title = "Waning immunity and resurgence over two years",
       caption = paste(length(unique(draws$replicate)),
                       "replicates per panel, population 2000, 20 infected",
                       "at the start.\n8 non-household contact events per",
                       "person per day, 3 hours of household contact per",
                       "day."))
save_figure(figure, "resurgence", height = 6)
