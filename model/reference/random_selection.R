# choosing at random from what already exists

# the positions in the population of a number of different individuals,
# each equally likely to be chosen
random_individuals <- function(population, number) {

  sample.int(length(population), number)

}

# the same elements in a random order
random_order <- function(elements) {

  elements[sample.int(length(elements))]

}
