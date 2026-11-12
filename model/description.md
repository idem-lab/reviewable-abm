# Model description

An illustrative agent-based model of a directly transmitted infection, with
household structure, variable infectiousness, and waning immunity. It
demonstrates the procedure in the README; its structure and parameter values
are not calibrated to any pathogen.

## Contents

- [Population](#sec-population)
- [Time](#sec-time)
- [Contact events](#sec-contacts)
- [Transmission](#sec-transmission)
- [Viral load](#sec-viral-load)
- [Recovery and immunity](#sec-immunity)

<a id="sec-population"></a>

## Population

A fixed population of individuals lives in households of equal size. Each
individual's age is drawn at the start of the simulation, uniformly between
0 and 80 years. Individuals under 18 are children and the rest are adults.
Ages increase as time passes. There are no births, deaths, or migration.
At the start, a fixed number of individuals, chosen at random, are newly
infected, and no one has any immunity.

<a id="sec-time"></a>

## Time

The simulation advances in timesteps of fixed length, measured in days. In
each timestep, in this order:

1. contact events occur, and may transmit infection;
2. infections whose viral load has passed its peak and fallen below the
   recovery threshold end;
3. each individual's age, and the times since their most recent infection
   and immunity boost, increase by the length of the timestep, and their
   viral load and immunity are recalculated from these times.

<a id="sec-contacts"></a>

## Contact events

In each timestep, every pair of individuals in the same household has one
contact event. In addition, a random number of contact events occur
between pairs chosen uniformly from the whole population, with a mean set
by the number of contact events per person per day (each contact event
counts for both people in it). These pairs can, by chance, live in the
same household; their contact event is still a non-household contact
event. Household and non-household contact events have different
durations, expressed in hours per day, so the duration of a contact event
is its daily duration multiplied by the length of the timestep. Contact
events are resolved one at a time, in random order.

<a id="sec-transmission"></a>

## Transmission

A contact event can transmit infection only if exactly one of the pair is
infected. Transmission occurs at a constant hazard over the duration of the
contact event. The log of this hazard is the sum of the log of a baseline
hazard and three effects: the infectiousness of the infected individual
(from their viral load and age group), the susceptibility of the uninfected
individual (from their immunity and age group), and the location of the
contact event (household or elsewhere).

<a id="sec-viral-load"></a>

## Viral load

Each infection has its own viral load level, drawn at infection. Viral load
also changes with time since infection, following the shape of a lognormal
density: zero at infection, rising to a peak after a few days, then
declining. The viral load level sets the height of the peak, and an
infection with the typical level and no immunity peaks at the same height
whatever the shape of the curve. An infected individual's current immunity,
left from earlier infections, reduces their viral load. Because viral load
is zero at infection, an individual infected during a timestep cannot
transmit until the next timestep.

<a id="sec-immunity"></a>

## Recovery and immunity

An infection ends once its viral load has passed its peak and fallen
below a recovery threshold, which is the same for all infections. The
duration of infection therefore depends on the viral load: infections with
a higher viral load level last longer, immunity shortens infections, and
an infection whose viral load never reaches the threshold ends just after
its peak. On recovery, an individual's
immunity is boosted, reducing their log hazard of infection by a fixed
amount, whatever immunity they had left. This reduction shrinks linearly
with time since the boost until immunity is lost entirely. Because the
reduction is on the log scale, susceptibility returns slowly at first and
then quickly, reaching full susceptibility abruptly. Individuals who have
never been infected have no immunity. Recovered individuals can be
reinfected.