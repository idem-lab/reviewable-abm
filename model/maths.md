# Mathematical description

This document states the model in the [written description](description.md)
as equations. Each section corresponds to the section of the written
description with the same name. Every symbol is defined in the
[notation table](#sec-notation), with its name in the reference
implementation, and keeps one meaning throughout.

Individual state changes only at discrete times. A quantity written as a
function of time, such as $a_i(t)$, is its value during the timestep
starting at time $t$, and $x \leftarrow y$ means that $x$ is set to $y$.

## Notation {#sec-notation}

**Settings**

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $N$ | population size, a multiple of $H$ | individuals | `population_size` |
| $H$ | household size | individuals | `household_size` |
| $K$ | number of individuals infected at the start | individuals | `initial_infections` |
| $\Delta$ | timestep length | days | `timestep_length` |
| $A_{\max}$ | upper limit of initial ages (80) | years | `maximum_initial_age` |
| $A$ | age at which individuals become adults (18) | years | `adult_age` |

**Parameters**

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $\beta$ | baseline log hazard of transmission | log per hour | `per_contact_log_hazard` |
| $\psi$ | effect of the infected individual being a child | log hazard | `child_infectiousness_score` |
| $\phi$ | effect of the uninfected individual being a child | log hazard | `child_susceptibility_score` |
| $\gamma$ | effect of the contact being in a household | log hazard | `household_setting_score` |
| $\bar d_{\mathrm{h}}$ | daily duration of a household contact | hours per day | `household_contact_hours_per_day` |
| $\bar d_{\mathrm{o}}$ | daily duration of a non-household contact | hours per day | `non_household_contact_hours_per_day` |
| $m$ | non-household contacts per person per day | per day | `non_household_contacts_per_person_per_day` |
| $s_\nu$ | standard deviation of the log viral load level | | `viral_load_level_sdlog` |
| $\mu_V$ | meanlog of the viral load profile | log days | `viral_load_profile_meanlog` |
| $s_V$ | sdlog of the viral load profile | log days | `viral_load_profile_sdlog` |
| $\lambda$ | reduction in log viral load per unit of immunity | | `viral_load_immunity_effect` |
| $D$ | infectious duration | days | `infectious_duration` |
| $\rho$ | immunity level immediately after a boost | log hazard | `immunity_boost_level` |
| $W$ | time from a boost until immunity is lost | days | `immunity_duration` |

**Individual state**, for individual $i$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $h_i$ | household | | `household` |
| $a_i$ | age | years | `age` |
| $g_i$ | 1 if a child, 0 if an adult | | `is_child()` |
| $X_i$ | 1 if infected, 0 otherwise | | `infected` |
| $\tau_i$ | time since most recent infection | days | `time_since_infection` |
| $\sigma_i$ | time since most recent immunity boost; $\infty$ if never boosted | days | `time_since_boost` |
| $\nu_i$ | viral load level of the current or most recent infection | | `viral_load_level` |
| $V_i$ | viral load | | `viral_load` |
| $R_i$ | immunity level: the reduction in log hazard of infection | log hazard | `immunity_level` |
| $I_i$ | infectiousness score | log hazard | `infectiousness_score()` |
| $S_i$ | susceptibility score | log hazard | `susceptibility_score()` |

**Contacts**, for contact $c$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $e_c$ | setting: household or non-household | | `setting` |
| $d_c$ | duration | hours | `duration` |
| $\eta_c$ | log hazard of transmission | log per hour | `log_hazard` |
| $p_c$ | probability of transmission | | `transmission_probability()` |
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

At time 0, $K$ individuals chosen uniformly at random without replacement
are infected ([Infection](#sec-infection)). All other individuals have
$X_i = 0$. No individual has been boosted, so $\sigma_i = \infty$ and
$R_i = 0$ for all $i$.

## Time {#sec-time}

Timestep $k = 0, 1, 2, \dots$ starts at time $t_k = k \Delta$. Within each
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
\mathcal{C}_{\mathrm{h}} = \{(i, j) : i < j,\ h_i = h_j\}, \qquad
e_c = \text{household}, \qquad d_c = \bar d_{\mathrm{h}} \Delta
$$ {#eq-household-contacts}

The number of non-household contacts is Poisson. Each contact involves two
people, so a mean of $m$ contacts per person per day gives a mean of
$N m / 2$ contacts per day:

$$
M \sim \mathrm{Poisson}\left(\frac{N m \Delta}{2}\right)
$$ {#eq-non-household-count}

Each of the $M$ contacts is between a pair $(i, j)$ drawn independently and
uniformly from all unordered pairs of distinct individuals, so a pair can
be drawn more than once in a timestep, and can by chance be members of the
same household:

$$
e_c = \text{non-household}, \qquad d_c = \bar d_{\mathrm{o}} \Delta
$$ {#eq-non-household-contacts}

All household and non-household contacts in the timestep are put in a
uniformly random order and resolved one at a time
([Transmission](#sec-transmission)), so that infections caused by earlier
contacts are part of the state seen by later ones.

## Transmission {#sec-transmission}

When contact $c$ is resolved, if exactly one of its pair is infected, call
the infected individual $j$ and the uninfected individual $i$. The log
hazard of transmission is

$$
\eta_c = \beta + I_j + S_i + \gamma\, \mathbb{1}[e_c = \text{household}]
$$ {#eq-log-hazard}

with infectiousness and susceptibility scores

$$
I_j = \log V_j + \psi\, g_j
$$ {#eq-infectiousness-score}

$$
S_i = -R_i + \phi\, g_i
$$ {#eq-susceptibility-score}

The hazard is constant over the contact, so the probability of
transmission is

$$
p_c = 1 - \exp\left(-d_c\, e^{\eta_c}\right)
$$ {#eq-transmission-probability}

and $i$ is infected with probability $p_c$
([Infection](#sec-infection)). If both or neither of the pair are infected,
nothing happens. When $V_j = 0$, $I_j = -\infty$ and $p_c = 0$.

Adults and non-household contacts are the reference categories, with
effects of zero; $\beta$ absorbs their effects and the scale of viral load.

## Viral load {#sec-viral-load}

### Infection {#sec-infection}

When individual $i$ is infected, at the start of the simulation or by a
contact, their viral load level is drawn and their time since infection is
set to zero:

$$
\nu_i \sim \mathrm{LogNormal}(0, s_\nu), \qquad
X_i \leftarrow 1, \qquad \tau_i \leftarrow 0
$$ {#eq-infection}

The meanlog of $\nu_i$ is fixed at 0 because $\beta$ sets the overall scale
of infectiousness.

### Viral load over time

An infected individual's viral load is their viral load level, multiplied
by a lognormal density in time since infection, and reduced by their
current immunity:

$$
V_i(t) = X_i \, \nu_i \, f\left(\tau_i(t)\right) \exp\left(-\lambda R_i(t)\right)
$$ {#eq-viral-load}

$$
f(\tau) = \frac{1}{\tau s_V \sqrt{2\pi}}
  \exp\left(-\frac{(\log \tau - \mu_V)^2}{2 s_V^2}\right), \qquad f(0) = 0
$$ {#eq-viral-load-profile}

$f$ peaks at $\tau = \exp(\mu_V - s_V^2)$ days. Because $f(0) = 0$, an
individual has $V_i = 0$ during the timestep in which they are infected, so
cannot transmit until the next timestep. Individuals who are not infected
have $V_i = 0$.

## Recovery and immunity {#sec-immunity}

At step 2 of each timestep, every infected individual whose infection has
lasted at least $D$ days recovers, and their immunity is boosted:

$$
\text{if } X_i = 1 \text{ and } \tau_i \ge D: \qquad
X_i \leftarrow 0, \qquad \sigma_i \leftarrow 0
$$ {#eq-recovery}

A boost restores immunity to $\rho$ whatever immunity remained. Immunity
then declines linearly with time since the boost, and is lost after $W$
days:

$$
R_i(t) = \rho \max\left(0,\ 1 - \frac{\sigma_i(t)}{W}\right)
$$ {#eq-immunity}

with $R_i = 0$ when $\sigma_i = \infty$. Susceptibility to infection is
proportional to $\exp(-R_i)$ (@eq-susceptibility-score), so it rises slowly
at first after a boost and reaches its full value abruptly at
$\sigma_i = W$.

An infection that starts in timestep $k$ has $\tau_i = 0$ at step 2 of that
timestep, so it ends at step 2 of timestep $k + \lceil D / \Delta \rceil$.

## Advancing individuals {#sec-advance}

At step 3 of each timestep, for every individual:

$$
a_i \leftarrow a_i + \frac{\Delta}{365.25}, \qquad
\tau_i \leftarrow \tau_i + \Delta \ \text{ if } X_i = 1, \qquad
\sigma_i \leftarrow \sigma_i + \Delta
$$ {#eq-advance}

then $R_i$ is recalculated from @eq-immunity, and $V_i$ from
@eq-viral-load using the new $R_i$. Ages are in years and elapsed times in
days.
