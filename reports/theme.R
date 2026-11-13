# the shared look of the behaviour figures, used by every script in
# reports/figures/. Run every script from the root of the repository.

library(ggplot2)

# colour-blind-safe colours (Okabe and Ito 2008), in the order used for
# groups
figure_colours <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00",
                    "#56B4E9", "#000000", "#999999")

theme_set(
  theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          legend.position = "bottom",
          strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold"),
          plot.title.position = "plot",
          plot.caption = element_text(hjust = 0, colour = "grey40"))
)

options(ggplot2.discrete.colour = figure_colours,
        ggplot2.discrete.fill = figure_colours)

# lines are drawn a little thicker than ggplot2's default; figures of
# individual simulations draw thinner lines themselves
update_geom_defaults("line", list(linewidth = 0.9))
update_geom_defaults("step", list(linewidth = 0.9))

# a colour scale for each quantity that figures vary, so that the same
# colours always mean the same quantity: a sequential ramp from light (low
# values) to dark (high values), or fixed colours for groups
colour_ramp <- function(light, dark) {
  function(...) {
    discrete_scale("colour",
                   palette = grDevices::colorRampPalette(c(light, dark)),
                   ...)
  }
}
scale_colour_viral_load <- colour_ramp("#FDAE6B", "#7F2704")
scale_colour_immunity <- colour_ramp("#9ECAE1", "#08306B")
scale_colour_boost_size <- colour_ramp("#A1D99B", "#00441B")
scale_colour_waning_rate <- colour_ramp("#FC9272", "#67000D")
# adults then children, in alphabetical order of their labels
scale_colour_age_group <- function(...) {
  scale_colour_manual(values = c("#762A83", "#C2A5CF"), ...)
}
# household then non-household
scale_colour_location <- function(...) {
  scale_colour_manual(values = c("#252525", "#A0A0A0"), ...)
}

# read the results saved for a figure from reports/draws/<name>.csv
read_draws <- function(name) {
  read.csv(file.path("reports", "draws", paste0(name, ".csv")))
}

# save a figure as reports/figures/<name>.png
save_figure <- function(figure, name, width = 7, height = 4.5) {
  ggsave(file.path("reports", "figures", paste0(name, ".png")), figure,
         width = width, height = height, dpi = 150, bg = "white")
}
