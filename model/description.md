# Model description

An illustrative agent-based model of a directly transmitted infection, with
household structure, variable infectiousness, and waning immunity. It
demonstrates the procedure in the README; its structure and parameter values
are not calibrated to any pathogen.

## Population {#sec-population}

A fixed population of individuals lives in households of equal size. Each
individual's age is drawn at the start of the simulation, uniformly between
0 and 80 years. Individuals under 18 are children and the rest are adults.
Ages increase as time passes. There are no births, deaths, or migration.
At the start, a fixed number of individuals, chosen at random, are newly
infected, and no one has any immunity.

## Time {#sec-time}

The simulation advances in timesteps of fixed length, measured in days. In
each timestep, in this order:

1. contacts occur, and may transmit infection;
2. infections that have lasted the infectious duration end;
3. each individual's age, and the times since their most recent infection
   and immunity boost, increase by the length of the timestep, and their
   viral load and immunity are recalculated from these times.

## Contacts {#sec-contacts}

In each timestep, every pair of individuals in the same household has one
contact. In addition, a random number of contacts occurs between pairs
chosen uniformly from the whole population, with a mean set by the number
of contacts per person per day (each contact counts for both people in
it). These pairs can, by chance, live in the same household; their contact
is still a non-household contact. Household and non-household contacts
have different durations. Contact durations are expressed in hours per
day, so the duration of a contact is its daily duration multiplied by the
length of the timestep. Contacts are resolved one at a time, in random order.

## Transmission {#sec-transmission}

A contact can transmit infection only if exactly one of the pair is
infected. Transmission occurs at a constant hazard over the duration of the
contact. The log of this hazard is the sum of a baseline value and three
effects: the infectiousness of the infected individual (from their viral
load and age group), the susceptibility of the uninfected individual (from
their immunity and age group), and the location of the contact (household or
elsewhere).

## Viral load {#sec-viral-load}

Each infection has its own viral load level, drawn at infection. Viral load
also changes with time since infection, following the shape of a lognormal
density: zero at infection, rising to a peak after a few days, then
declining. An infected individual's current immunity, left from earlier infections,
reduces their viral load.
Because viral load is zero at infection, an individual infected during a
timestep cannot transmit until the next timestep.

## Recovery and immunity {#sec-immunity}

Infections last a fixed number of days. On recovery, an individual's
immunity is boosted, reducing their log hazard of infection by a fixed
amount, whatever immunity they had left. This reduction shrinks linearly with time since the boost until
immunity is lost entirely. Because the reduction is on the log scale,
susceptibility returns slowly at first and then quickly, reaching full
susceptibility abruptly. Individuals who have never been infected have no
immunity. Recovered individuals can be reinfected.
