# infrastructure, not part of the model: the settings and parameters used
# in a run, held in locked environments so that nothing can change them
# while the model runs. set_values() makes them from the defaults in
# model/reference/default_values.R and any changes; model functions read
# them only with load_settings() and load_parameters().

values <- new.env()

# set the settings and parameters for a run: the defaults, with the values
# in the lists settings and parameters replacing them by name. Called by
# run_model(), and by tests of single functions.
set_values <- function(settings, parameters) {

  values$settings <- locked_values(default_settings, settings, "setting")
  values$parameters <- locked_values(default_parameters, parameters,
                                     "parameter")

  invisible(NULL)

}

# a locked environment holding the defaults with the changes applied,
# stopping if a change names a value that does not exist
locked_values <- function(defaults, changes, kind) {

  for (name in names(changes)) {
    if (!name %in% names(defaults)) {
      stop("no ", kind, " called ", name)
    }
  }

  combined <- defaults
  for (name in names(changes)) {
    combined[[name]] <- changes[[name]]
  }

  environment <- list2env(combined)
  lockEnvironment(environment, bindings = TRUE)

  environment

}

# the settings and parameters of the current run, as lists
current_values <- function() {

  list(settings = as.list(values$settings),
       parameters = as.list(values$parameters))

}

# make the named settings available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a model function
load_settings <- function(...) {

  load_values(c(...), values$settings, "setting", parent.frame())

}

# make the named parameters available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a model function
load_parameters <- function(...) {

  load_values(c(...), values$parameters, "parameter", parent.frame())

}

# assign the named values from an environment into the calling function
load_values <- function(names, environment, kind, caller) {

  if (is.null(environment)) {
    stop("values have not been set; use run_model() or set_values()")
  }

  for (name in names) {
    if (!exists(name, envir = environment, inherits = FALSE)) {
      stop("no ", kind, " called ", name)
    }
    assign(name, get(name, envir = environment), envir = caller)
  }

  invisible(names)

}
