# Mathematical description

This document states the model in the [written description](description.md)
as equations. Sections with the same name and label as a section of the
written description state the same part of the model. Every symbol is
defined in the [notation table](#sec-notation), with its name in the
reference implementation, and keeps one meaning throughout.

The notation follows the usual conventions for epidemic models where they
exist: $N$ for population size, $I_0$ for the number initially infected,
$\beta$ for the transmission rate, $\lambda$ for the hazard of infection,
$c$ for the contact rate, $\tau$ for time since infection, and $\mu$ and
$\sigma$ for the parameters of a lognormal distribution. Because $S$, $I$
and $R$ conventionally name the compartments of an SIR model, they are not
used for individual quantities.

Individual state changes only at discrete times. A quantity written as a
function of time, such as $a_i(t)$, is its value during the timestep
starting at time $t$, and $x \leftarrow y$ means that $x$ is set to $y$.

## Notation {#sec-notation}

**Settings**

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $N$ | population size, a multiple of $H$ | individuals | `population_size` |
| $H$ | household size | individuals | `household_size` |
| $I_0$ | number of individuals infected at the start | individuals | `initial_infections` |
| $\Delta t$ | timestep length | days | `timestep_length` |
| $A_{\max}$ | upper limit of initial ages (80) | years | `maximum_initial_age` |
| $A$ | age at which individuals become adults (18) | years | `adult_age` |

**Parameters**

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $\beta$ | baseline hazard of transmission: for an adult infected individual with unit viral load, an adult uninfected individual with no immunity, and a non-household contact | per hour | `baseline_transmission_hazard` |
| $\alpha_{\mathrm{inf}}$ | log hazard ratio for an infected individual who is a child | | `child_infectiousness_score` |
| $\alpha_{\mathrm{sus}}$ | log hazard ratio for an uninfected individual who is a child | | `child_susceptibility_score` |
| $\alpha_{\mathrm{hh}}$ | log hazard ratio for a household contact | | `household_location_score` |
| $\bar d_{\mathrm{hh}}$ | daily duration of a household contact | hours per day | `household_contact_hours_per_day` |
| $\bar d_{\mathrm{nh}}$ | daily duration of a non-household contact | hours per day | `non_household_contact_hours_per_day` |
| $c$ | non-household contacts per person per day | per day | `non_household_contacts_per_person_per_day` |
| $\sigma_\nu$ | sdlog of the viral load level | | `viral_load_level_sdlog` |
| $\mu_V$ | meanlog of the viral load profile | log days | `viral_load_profile_meanlog` |
| $\sigma_V$ | sdlog of the viral load profile | | `viral_load_profile_sdlog` |
| $\kappa$ | reduction in log viral load per unit of immunity level | | `viral_load_immunity_effect` |
| $D_{\mathrm{inf}}$ | duration of infection | days | `infectious_duration` |
| $z_{\max}$ | immunity level immediately after a boost | log hazard ratio | `immunity_boost_level` |
| $D_{\mathrm{imm}}$ | time from a boost until immunity is lost | days | `immunity_duration` |

**Individual state**, for individual $i$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $h_i$ | household | | `household` |
| $a_i$ | age | years | `age` |
| $g_i$ | 1 if a child, 0 if an adult | | `is_child()` |
| $X_i$ | 1 if infected, 0 otherwise | | `infected` |
| $\tau_i$ | time since most recent infection | days | `time_since_infection` |
| $\tau^{\mathrm{b}}_i$ | time since most recent immunity boost; $\infty$ if never boosted | days | `time_since_boost` |
| $\nu_i$ | viral load level of the current or most recent infection | | `viral_load_level` |
| $V_i$ | viral load | | `viral_load` |
| $z_i$ | immunity level: the reduction in log hazard of infection | log hazard ratio | `immunity_level` |
| $\eta^{\mathrm{inf}}_i$ | infectiousness score | log hazard ratio | `infectiousness_score()` |
| $\eta^{\mathrm{sus}}_i$ | susceptibility score | log hazard ratio | `susceptibility_score()` |

**Contacts**, for contact $k$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $\ell_k$ | location: household or non-household | | `location` |
| $d_k$ | duration | hours | `duration` |
| $\lambda_k$ | hazard of transmission | per hour | `hazard` |
| $p_k$ | probability of transmission | | `transmission_probability()` |
| $M$ | number of non-household contacts in a timestep | | `number_of_non_household_contacts` |

$\mathbb{1}[\cdot]$ is 1 when the condition holds and 0 otherwise.

## Population {#sec-population}

Individuals $i = 1, \dots, N$ live in households of $H$ consecutive
individuals:

$$
h_i = \lceil i / H \rceil
$$ {#eq-household}

Initial ages are independent and uniform:

$$
a_i(0) \sim \mathrm{Uniform}(0, A_{\max})
$$ {#eq-initial-age}

An individual is a child while younger than $A$:

$$
g_i(t) = \mathbb{1}\left[a_i(t) < A\right]
$$ {#eq-child}

At time 0, $I_0$ individuals chosen uniformly at random without replacement
are infected ([Infection](#sec-infection)). All other individuals have
$X_i = 0$. No individual has been boosted, so $\tau^{\mathrm{b}}_i = \infty$
and $z_i = 0$ for all $i$.

## Time {#sec-time}

Timestep $n = 0, 1, 2, \dots$ starts at time $t_n = n \Delta t$. Within each
timestep:

1. contacts are generated and resolved ([Contacts](#sec-contacts),
   [Transmission](#sec-transmission));
2. infections end ([Recovery and immunity](#sec-immunity));
3. ages, elapsed times and levels are advanced
   ([Advancing individuals](#sec-advance)).

## Contacts {#sec-contacts}

Each timestep has one household contact for each unordered pair of
individuals in the same household:

$$
\mathcal{C}_{\mathrm{hh}} = \{(i, j) : i < j,\ h_i = h_j\}, \qquad
\ell_k = \text{household}, \qquad d_k = \bar d_{\mathrm{hh}} \Delta t
$$ {#eq-household-contacts}

The number of non-household contacts is Poisson. Each contact involves two
people, so a mean of $c$ contacts per person per day gives a mean of
$N c / 2$ contacts per day:

$$
M \sim \mathrm{Poisson}\left(\frac{N c \, \Delta t}{2}\right)
$$ {#eq-non-household-count}

Each of the $M$ contacts is between a pair $(i, j)$ drawn independently and
uniformly from all unordered pairs of distinct individuals, so a pair can
be drawn more than once in a timestep, and can by chance be members of the
same household:

$$
\ell_k = \text{non-household}, \qquad d_k = \bar d_{\mathrm{nh}} \Delta t
$$ {#eq-non-household-contacts}

All household and non-household contacts in the timestep are put in a
uniformly random order and resolved one at a time
([Transmission](#sec-transmission)), so that infections caused by earlier
contacts are part of the state seen by later ones.

## Transmission {#sec-transmission}

When contact $k$ is resolved, if exactly one of its pair is infected, call
the infected individual $j$ and the uninfected individual $i$. The log of
the hazard of transmission is the sum of the log of the baseline hazard,
the infectiousness and susceptibility scores of the pair, and the effect of
the contact's location:

$$
\log \lambda_k = \log \beta + \eta^{\mathrm{inf}}_j + \eta^{\mathrm{sus}}_i
  + \alpha_{\mathrm{hh}}\, \mathbb{1}[\ell_k = \text{household}]
$$ {#eq-hazard}

with

$$
\eta^{\mathrm{inf}}_j = \log V_j + \alpha_{\mathrm{inf}}\, g_j
$$ {#eq-infectiousness-score}

$$
\eta^{\mathrm{sus}}_i = \alpha_{\mathrm{sus}}\, g_i - z_i
$$ {#eq-susceptibility-score}

The hazard is constant over the contact, so the probability of
transmission is

$$
p_k = 1 - \exp\left(-\lambda_k d_k\right)
$$ {#eq-transmission-probability}

and $i$ is infected with probability $p_k$
([Infection](#sec-infection)). If both or neither of the pair are infected,
nothing happens. When $V_j = 0$, $\lambda_k = 0$ and $p_k = 0$.

Adults and non-household contacts are the reference categories, with log
hazard ratios of zero.

## Viral load {#sec-viral-load}

### Infection {#sec-infection}

When individual $i$ is infected, at the start of the simulation or by a
contact, their viral load level is drawn and their time since infection is
set to zero:

$$
\nu_i \sim \mathrm{LogNormal}(0, \sigma_\nu), \qquad
X_i \leftarrow 1, \qquad \tau_i \leftarrow 0
$$ {#eq-infection}

The meanlog of $\nu_i$ is fixed at 0 because $\beta$ sets the overall scale
of infectiousness.

### Viral load over time

An infected individual's viral load is their viral load level, multiplied
by a lognormal density in time since infection, and reduced by their
current immunity:

$$
V_i(t) = X_i \, \nu_i \, f\left(\tau_i(t)\right) \exp\left(-\kappa z_i(t)\right)
$$ {#eq-viral-load}

$$
f(\tau) = \frac{1}{\tau \sigma_V \sqrt{2\pi}}
  \exp\left(-\frac{(\log \tau - \mu_V)^2}{2 \sigma_V^2}\right), \qquad f(0) = 0
$$ {#eq-viral-load-profile}

$f$ peaks at $\tau = \exp(\mu_V - \sigma_V^2)$ days. Because $f(0) = 0$, an
individual has $V_i = 0$ during the timestep in which they are infected, so
cannot transmit until the next timestep. Individuals who are not infected
have $V_i = 0$.

## Recovery and immunity {#sec-immunity}

At step 2 of each timestep, every infected individual whose infection has
lasted at least $D_{\mathrm{inf}}$ days recovers, and their immunity is
boosted:

$$
\text{if } X_i = 1 \text{ and } \tau_i \ge D_{\mathrm{inf}}: \qquad
X_i \leftarrow 0, \qquad \tau^{\mathrm{b}}_i \leftarrow 0
$$ {#eq-recovery}

A boost restores immunity to $z_{\max}$ whatever immunity remained.
Immunity then declines linearly with time since the boost, and is lost
after $D_{\mathrm{imm}}$ days:

$$
z_i(t) = z_{\max} \max\left(0,\ 1 - \frac{\tau^{\mathrm{b}}_i(t)}{D_{\mathrm{imm}}}\right)
$$ {#eq-immunity}

with $z_i = 0$ when $\tau^{\mathrm{b}}_i = \infty$. The hazard of infection
is proportional to $\exp(-z_i)$ (@eq-susceptibility-score), so it rises
slowly at first after a boost and reaches its full value abruptly at
$\tau^{\mathrm{b}}_i = D_{\mathrm{imm}}$.

An infection that starts in timestep $n$ has $\tau_i = 0$ at step 2 of that
timestep, so it ends at step 2 of timestep
$n + \lceil D_{\mathrm{inf}} / \Delta t \rceil$.

## Advancing individuals {#sec-advance}

At step 3 of each timestep, for every individual:

$$
a_i \leftarrow a_i + \frac{\Delta t}{365.25}, \qquad
\tau_i \leftarrow \tau_i + \Delta t \ \text{ if } X_i = 1, \qquad
\tau^{\mathrm{b}}_i \leftarrow \tau^{\mathrm{b}}_i + \Delta t
$$ {#eq-advance}

then $z_i$ is recalculated from @eq-immunity, and $V_i$ from
@eq-viral-load using the new $z_i$. Ages are in years and elapsed times in
days.
