# random draws that are not specific to one part of the model

# the indices in the population of a number of different individuals, each
# equally likely to be chosen
random_individual_indices <- function(population, number) {

  sample.int(length(population), number)

}

# the same elements in a random order
random_order <- function(elements) {

  elements[sample.int(length(elements))]

}

# TRUE with the given probability, otherwise FALSE
random_bernoulli <- function(probability) {

  rbinom(1, size = 1, prob = probability) == 1

}
