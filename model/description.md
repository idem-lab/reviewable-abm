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

A fixed population of individuals lives in households of random sizes.
Each household has one member plus a number drawn from a Poisson
distribution, so that sizes have a fixed average, and households are filled
in turn until everyone has a household; the last is cut short to fit. Each
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
event. Household contact events recur in every timestep, so their
duration is set in hours per day and multiplied by the length of the
timestep. Each non-household contact event is a single encounter, with a
fixed duration in hours whatever the length of the timestep. Contact
events are resolved one at a time, in random order.

<a id="sec-transmission"></a>

## Transmission

A contact event can transmit infection only if exactly one of the pair is
infected. Transmission occurs at a constant hazard over the duration of the
contact event. The log of this hazard is the sum of the log of a baseline
hazard and three effects: the infectiousness of the infected individual
(from their viral load and age), the susceptibility of the uninfected
individual (from their immunity and age), and the location of the
contact event (household or elsewhere). At present the effects of age are
steps: children differ from adults, and all children, and all adults, are
alike.

<a id="sec-viral-load"></a>

## Viral load

Each infection has its own potential peak viral load, drawn at infection:
the peak its viral load would reach in someone with no immunity. Viral load
changes with time since infection: it is zero at infection, rises to a peak
at a fixed time after infection, then declines, following a bell-shaped
curve in the log of time since infection. The immunity an individual had
when they were infected, left from earlier infections, reduces their viral
load throughout that infection, so their peak viral load is lower than the
potential peak. Because viral load is zero at infection, an individual
infected during a timestep cannot transmit until the next timestep.

Because infectiousness is proportional to viral load, the time from
infection to onward transmission (the generation interval) follows a
lognormal distribution, apart from the effects of recovery and of
timesteps.

<a id="sec-immunity"></a>

## Recovery and immunity

An infection ends once its viral load has passed its peak and fallen below
a low recovery threshold, the same for all infections. Very little
transmission happens after this. The duration of infection therefore
depends on the viral load: infections with a higher peak viral load last
longer, so immunity shortens infections. In the rare infections whose viral
load never reaches the threshold, the individual stays infected, so cannot
be reinfected, until the peak, but transmits very little. Recovered
individuals can be reinfected.

Immunity reduces an individual's log hazard of infection. Each infection
boosts the individual's immunity at the time of infection, by adding an
amount drawn for that infection to whatever immunity they had left. Boost
sizes vary between infections following a lognormal distribution, and are
positively correlated with the infection's potential peak viral load:
infections with a higher potential peak tend to give larger boosts, or the
two are unrelated. The boost does not affect the viral load of the infection that
caused it. Immunity then declines at a constant rate until it is lost
entirely, so higher immunity lasts longer. Because immunity acts on the
log scale, susceptibility returns slowly at first and then quickly,
reaching full susceptibility abruptly. Individuals who have never been
infected have no immunity.
