# random draws that are not specific to one part of the model

# the indices in the population of a number of different individuals, each
# equally likely to be chosen
random_individual_indices <- function(population, number) {

  sample.int(length(population), number)

}

# the same elements in a random order
random_order <- function(elements) {

  # the indices of the elements, in a random order
  random_indices <- sample.int(length(elements))
  elements[random_indices]

}

# TRUE with the given probability, otherwise FALSE
random_bernoulli <- function(probability) {

  rbinom(1, size = 1, prob = probability) == 1

}

# a value drawn uniformly between lower and upper
random_uniform <- function(lower, upper) {

  runif(1, min = lower, max = upper)

}

# a count drawn from a Poisson distribution with the given mean
random_poisson <- function(mean) {

  rpois(1, lambda = mean)

}

# a vector drawn from a multivariate normal distribution with the given
# means and covariance matrix
random_multivariate_normal <- function(means, covariance) {

  MASS::mvrnorm(1, mu = means, Sigma = covariance)

}
