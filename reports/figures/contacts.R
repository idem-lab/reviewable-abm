# Expected: every household has at least one member, and sizes average the
# set average household size (4). In one timestep, each person has one
# household contact event with each other member of their household, and a
# Poisson-like number of non-household contact events with mean equal to
# the set rate (10 per day).

source("reports/theme.R")
library(patchwork)

household_sizes <- read_draws("household_sizes")
counts <- read_draws("contacts_per_person")
long <- rbind(
  data.frame(location = "household", contact_events = counts$household),
  data.frame(location = "non-household",
             contact_events = counts$non_household)
)

sizes_figure <- ggplot(household_sizes, aes(household_size)) +
  geom_bar(fill = data_colour) +
  scale_x_continuous(breaks = function(limits) seq(1, limits[2], by = 1)) +
  labs(x = "household size", y = "households",
       title = "Household sizes",
       caption = paste("Mean", round(mean(household_sizes$household_size),
                                     2)))

contacts_figure <- ggplot(long, aes(contact_events)) +
  geom_bar(fill = data_colour) +
  facet_wrap(~ location, scales = "free_x") +
  labs(x = "contact events per person in one day", y = "people",
       title = "Contact events per person")

save_figure(sizes_figure + contacts_figure +
              plot_layout(widths = c(1, 2)),
            "contacts")
