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

# read the results saved for a figure from reports/draws/<name>.csv
read_draws <- function(name) {
  read.csv(file.path("reports", "draws", paste0(name, ".csv")))
}

# save a figure as reports/figures/<name>.png
save_figure <- function(figure, name, width = 7, height = 4.5) {
  ggsave(file.path("reports", "figures", paste0(name, ".png")), figure,
         width = width, height = height, dpi = 150, bg = "white")
}
