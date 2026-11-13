# the shared look of the behaviour figures, used by every script in
# reports/figures/. Run every script from the root of the repository.

library(ggplot2)

# colours, so that colour always means one quantity that a figure varies.
# Everything else uses two dark colours distinct from those scales: values
# simulated or drawn from the model are IDEM dark teal (from the "idem"
# palette of the idpalette package, github.com/idem-lab/idpalette), and
# values from the equations in maths.md are near-black.
data_colour <- "#178793"
expectation_colour <- "#1A1A1A"

# colour-blind-safe colours (Okabe and Ito 2008), used only to tell apart
# individual people or runs, never for a quantity
identity_colours <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7",
                      "#E69F00", "#56B4E9", "#000000", "#999999")

theme_set(
  theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          legend.position = "bottom",
          legend.key.width = unit(1.5, "cm"),
          legend.box = "vertical",
          strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold"),
          plot.title.position = "plot",
          plot.caption = element_text(hjust = 0, colour = "grey40"))
)

# lines are heavier than ggplot2's default, so that colours are easy to
# see; figures of individual simulations draw thinner lines themselves
update_geom_defaults("line", list(linewidth = 1.3))
update_geom_defaults("step", list(linewidth = 1.3))

# a colour scale for each ordered quantity that figures vary, each in its
# own family of hues, bright, and running from light (low values) to dark
# (high values), with the palest and darkest ends left out because colours
# there are hard to tell apart. Hues that red-green colour-blindness
# confuses are not used for two quantities in the same figure.
hcl_ramp <- function(hue_light, hue_dark) {
  function(n) {
    grDevices::hcl(h = seq(hue_light, hue_dark, length.out = n), c = 100,
                   l = seq(78, 38, length.out = n), fixup = TRUE)
  }
}
quantity_scale <- function(hue_light, hue_dark) {
  function(aesthetics = "colour", ...) {
    discrete_scale(aesthetics, palette = hcl_ramp(hue_light, hue_dark), ...)
  }
}
# quantities on the same scale share a colour scale: viral load, potential
# peak viral load and peak viral load; immunity level, immunity at
# infection and boost size
scale_colour_viral_load <- quantity_scale(85, 10)
scale_colour_immunity <- quantity_scale(225, 265)
scale_colour_waning_rate <- quantity_scale(110, 150)
scale_colour_household_size <- quantity_scale(350, 300)

# continuous fills for heat maps, in the hue family of the quantity they
# show, from white through the same ramp
fill_ramp <- function(hue_light, hue_dark, ...) {
  scale_fill_gradientn(colours = c("white",
                                   hcl_ramp(hue_light, hue_dark)(5)),
                       ...)
}
scale_fill_relative_susceptibility <- function(...) {
  fill_ramp(225, 265, limits = c(0, 1), ...)
}
scale_fill_transmission_probability <- function(...) {
  fill_ramp(85, 10, limits = c(0, 1), ...)
}
scale_fill_viral_load <- function(...) {
  fill_ramp(85, 10, ...)
}

# groups of two are shown by line type, not colour: adults solid and
# children dotted; household solid and non-household dashed
scale_linetype_age_group <- function(...) {
  scale_linetype_manual(values = c("solid", "dotted"), ...)
}
scale_linetype_location <- function(...) {
  scale_linetype_manual(values = c("solid", "dashed"), ...)
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
