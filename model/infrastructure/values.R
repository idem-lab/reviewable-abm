# infrastructure, not part of the model: the settings and parameters used
# in a run, held in locked environments so that nothing can change them
# while the model runs. set_values() makes them from the defaults in
# model/reference/default_values.R and any changes; model functions read
# them only with load_settings() and load_parameters().

# the current settings and parameters, each a locked environment; this
# environment is itself locked, so only set_values() can replace them
model_values <- new.env()
model_values$settings <- NULL
model_values$parameters <- NULL
lockEnvironment(model_values, bindings = TRUE)

# set the settings and parameters for a run: the defaults, with the values
# in the named lists settings and parameters replacing them by name. Also
# clears the simulation clock, which depends on the settings. Called by
# run_model(), and by tests of single functions.
set_values <- function(settings, parameters) {

  new_settings <- locked_values(default_settings, settings, "setting")
  new_parameters <- locked_values(default_parameters, parameters,
                                  "parameter")

  for (kind in c("settings", "parameters")) {
    unlockBinding(kind, model_values)
  }
  model_values$settings <- new_settings
  model_values$parameters <- new_parameters
  for (kind in c("settings", "parameters")) {
    lockBinding(kind, model_values)
  }

  reset_clock()

  invisible(NULL)

}

# a locked environment holding the defaults with the changes applied,
# stopping if a change is unnamed, named twice, NULL, or names a value that
# does not exist
locked_values <- function(defaults, changes, kind) {

  names <- names(changes)
  if (length(changes) > 0 && (is.null(names) || any(names == ""))) {
    stop("every ", kind, " given must be named")
  }
  if (any(duplicated(names))) {
    stop(kind, " given twice: ", names[duplicated(names)][1])
  }

  combined <- defaults
  for (name in names) {
    if (!name %in% names(defaults)) {
      stop("no ", kind, " called ", name)
    }
    if (is.null(changes[[name]])) {
      stop("the ", kind, " ", name, " is NULL")
    }
    combined[[name]] <- changes[[name]]
  }

  environment <- list2env(combined)
  lockEnvironment(environment, bindings = TRUE)

  environment

}

# the settings and parameters of the current run, as lists in the order of
# the defaults
current_values <- function() {

  list(settings = mget(names(default_settings),
                       envir = model_values$settings),
       parameters = mget(names(default_parameters),
                         envir = model_values$parameters))

}

# make the named settings available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a model function
load_settings <- function(...) {

  load_values(c(...), model_values$settings, "setting", parent.frame())

}

# make the named parameters available as variables of the same name in the
# function that calls this, stopping if a name does not exist; called only
# at the top of a model function
load_parameters <- function(...) {

  load_values(c(...), model_values$parameters, "parameter", parent.frame())

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
