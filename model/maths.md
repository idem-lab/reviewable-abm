# Mathematical description

This document states the model in the [written description](description.md)
as equations. Sections with the same label as a section of the
written description state the same part of the model. Each symbol is
defined briefly where it is first used, and in full, with its units and its
name in the reference implementation, in the [notation](#sec-notation)
tables at the end. Each symbol keeps one meaning throughout.

The notation follows the usual conventions for epidemic models where they
exist: $N$ for population size, $I_0$ for the number initially infected,
$\beta$ for transmission rates, $c$ for the contact rate, $\tau$ for time
since infection, $\mu$ and $\sigma$ for the mean and standard deviation of
the log of a lognormal random variable, $\rho$ for a correlation, and
$\omega$ for the rate at which immunity wanes.

Individual state changes only at discrete times. A quantity written as a
function of time, such as $a_i(t)$, is its value during the timestep
starting at time $t$, and $x \leftarrow y$ means that $x$ is set to $y$.

## Contents

- [Population](#sec-population)
- [Time](#sec-time)
- [Contact events](#sec-contacts)
- [Transmission](#sec-transmission)
- [Viral load](#sec-viral-load)
  - [Infection](#sec-infection)
  - [Viral load over time](#sec-viral-load-over-time)
  - [Generation interval](#sec-generation-interval)
- [Recovery and immunity](#sec-immunity)
  - [Duration of infection](#sec-duration)
- [Advancing individuals](#sec-advance)
- [Notation](#sec-notation)

<a id="sec-population"></a>

## Population

The population consists of $N$ individuals, $i = 1, \dots, N$, living in
households of $H$ consecutive individuals:

<a id="eq-household"></a>

```math
h_i = \lceil i / H \rceil
```

where $h_i$ is the household to which individual $i$ belongs, and
$\lceil x \rceil$ is the smallest integer greater than or equal to $x$.
$N$ is a multiple of $H$.

Initial ages are independent and uniform:

<a id="eq-initial-age"></a>

```math
a_i(0) \sim \mathrm{Uniform}(0, A_{\max})
```

where $a_i(t)$ is the age of individual $i$ in years, and $A_{\max}$ is the
upper limit of initial ages (80 years).

An individual is a child while younger than $A$ (18 years):

<a id="eq-child"></a>

```math
g_i(t) = \mathbb{1}\left[a_i(t) < A\right]
```

where $g_i$ is 1 if individual $i$ is a child and 0 if an adult, and
$\mathbb{1}[\cdot]$ is 1 when the condition in brackets holds and 0
otherwise.

At time 0, $I_0$ individuals chosen uniformly at random without replacement
are infected ([Infection](#sec-infection)). For every other individual,
$X_i = 0$, where $X_i$ is 1 if individual $i$ is infected and 0 otherwise.
Before these initial infections, no individual has any immunity: their
immunity level is $z_i = 0$, their immunity after their most recent boost
is $z_i^{\mathrm{boost}} = 0$, and the time since that boost is
$\tau_i^{\mathrm{boost}} = \infty$
([Recovery and immunity](#sec-immunity)).

<a id="sec-time"></a>

## Time

Timestep $n = 0, 1, 2, \dots$ starts at time $t_n = n \Delta t$, where
$\Delta t$ is the timestep length in days. Within each timestep:

1. contact events are generated and resolved ([Contact events](#sec-contacts),
   [Transmission](#sec-transmission));
2. infections end ([Recovery and immunity](#sec-immunity));
3. ages, elapsed times and levels are advanced
   ([Advancing individuals](#sec-advance)).

<a id="sec-contacts"></a>

## Contact events

Each timestep has one household contact event for each unordered pair of
individuals in the same household:

<a id="eq-household-contacts"></a>

```math
\mathcal C_{\mathrm{hh}} = \{(i, j) : i < j,\ h_i = h_j\}, \qquad
\ell_k = 1, \qquad d_k = \bar d_{\mathrm{hh}} \Delta t
```

where $\mathcal C_{\mathrm{hh}}$ is the set of pairs with a household
contact event. For each contact event $k$, $\ell_k$ is 1 if it is a
household contact event and 0 otherwise, and $d_k$ is its duration in hours.
$\bar d_{\mathrm{hh}}$ is the daily duration of a household contact event,
in hours per day.

The number of non-household contact events is Poisson. Each contact event
involves two people, so a mean of $c$ non-household contact events per
person per day gives a mean of $N c / 2$ contact events per day:

<a id="eq-non-household-count"></a>

```math
M \sim \mathrm{Poisson}\left(\frac{N c \, \Delta t}{2}\right)
```

where $M$ is the number of non-household contact events in the timestep.

Each of the $M$ contact events is between a pair $(i, j)$ drawn
independently and uniformly from all unordered pairs of distinct
individuals, so a pair can be drawn more than once in a timestep, and can by
chance be members of the same household:

<a id="eq-non-household-contacts"></a>

```math
\ell_k = 0, \qquad d_k = \bar d_{\mathrm{nh}} \Delta t
```

where $\bar d_{\mathrm{nh}}$ is the daily duration of a non-household
contact event, in hours per day.

All household and non-household contact events in the timestep are put in a
uniformly random order and resolved one at a time
([Transmission](#sec-transmission)), so that infections caused by earlier
contact events are part of the state seen by later ones.

<a id="sec-transmission"></a>

## Transmission

When contact event $k$ is resolved, if exactly one of its pair is infected,
call the infected individual $j$ and the uninfected individual $i$. The log
of the hazard of transmission is the sum of the log of the baseline hazard,
the infectiousness and susceptibility scores of the pair, and the effect of
the contact event's location:

<a id="eq-hazard"></a>

```math
\log \beta_k = \log \beta_0 + \eta_j^{\mathrm{inf}} + \eta_i^{\mathrm{sus}}
  + \alpha_{\mathrm{hh}}\, \ell_k
```

where $\beta_k$ is the hazard of transmission during contact event $k$, per
hour; $\beta_0$ is the baseline hazard of transmission;
$\eta_j^{\mathrm{inf}}$ is the infectiousness score of the infected
individual and $\eta_i^{\mathrm{sus}}$ the susceptibility score of the
uninfected individual; and $\alpha_{\mathrm{hh}}$ is the log hazard ratio
for a household contact event.

The scores are log hazard ratios:

<a id="eq-infectiousness-score"></a>

```math
\eta_j^{\mathrm{inf}} = \log V_j + \alpha_{\mathrm{inf}}\, g_j
```

<a id="eq-susceptibility-score"></a>

```math
\eta_i^{\mathrm{sus}} = \alpha_{\mathrm{sus}}\, g_i - z_i
```

where $V_j$ is the viral load of the infected individual ([Viral
load](#sec-viral-load)), and $\alpha_{\mathrm{inf}}$ and
$\alpha_{\mathrm{sus}}$ are the log hazard ratios for an infected and an
uninfected individual who is a child. Adults and non-household contact
events are the reference categories, with log hazard ratios of zero.

The hazard is constant over the contact event, so the probability of
transmission is

<a id="eq-transmission-probability"></a>

```math
p_k = 1 - \exp\left(-\beta_k d_k\right)
```

and individual $i$ is infected with probability $p_k$
([Infection](#sec-infection)). If both or neither of the pair are infected,
nothing happens. When $V_j = 0$, $\beta_k = 0$ and $p_k = 0$.

<a id="sec-viral-load"></a>

## Viral load

<a id="sec-infection"></a>

### Infection

When individual $i$ is infected, at the start of the simulation or by a
contact event:

<a id="eq-infection"></a>

```math
z_i^{\mathrm{inf}} \leftarrow z_i, \qquad
X_i \leftarrow 1, \qquad \tau_i^{\mathrm{inf}} \leftarrow 0, \qquad
\tau_i^{\mathrm{boost}} \leftarrow 0
```

where $z_i$ is the individual's current immunity level, left from earlier
infections ([immunity equation](#eq-immunity)), and $z_i^{\mathrm{inf}}$
records it at the moment of infection. $z_i^{\mathrm{inf}}$ reduces the
viral load of this infection ([Viral load over time](#sec-viral-load-over-time)).
$\tau_i^{\mathrm{inf}}$ is the time since infection and
$\tau_i^{\mathrm{boost}}$ the time since the most recent immunity boost, both
in days.

At the same time, the infection's viral load level $\nu_i$ and the size of
its immunity boost $\Delta z_i$ are drawn. Both are lognormal, and their
logs are correlated:

<a id="eq-infection-draws"></a>

```math
\begin{pmatrix} \log \nu_i \\ \log \Delta z_i \end{pmatrix}
\sim \mathrm{Normal}\left(
  \begin{pmatrix} 0 \\ \mu_z \end{pmatrix},
  \begin{pmatrix} \sigma_\nu^2 & \rho \sigma_\nu \sigma_z \\
                  \rho \sigma_\nu \sigma_z & \sigma_z^2 \end{pmatrix}
\right)
```

where $\sigma_\nu$ is the standard deviation of $\log \nu_i$, $\mu_z$ and
$\sigma_z$ are the mean and standard deviation of $\log \Delta z_i$, and
$\rho \ge 0$ is the correlation between the two logs, so that infections
with a higher viral load level tend to give larger boosts. The boost is
added to the individual's current immunity:

<a id="eq-boost"></a>

```math
z_i^{\mathrm{boost}} \leftarrow z_i^{\mathrm{inf}} + \Delta z_i
```

where $z_i^{\mathrm{boost}}$ is the immunity level just after the boost
([Recovery and immunity](#sec-immunity)).

The mean of $\log \nu_i$ is fixed at 0, so that the viral load of a typical
infection (with the median level, $\nu_i = 1$, and no immunity) peaks at 1.
Viral load is on a relative scale: $\beta_0$ converts it into a hazard of
transmission.

<a id="sec-viral-load-over-time"></a>

### Viral load over time

An infected individual's viral load is their viral load level, multiplied
by a viral load profile in time since infection, and reduced by the
immunity they had when infected:

<a id="eq-viral-load"></a>

```math
V_i(t) = X_i \, \nu_i \, g\left(\tau_i^{\mathrm{inf}}(t)\right) \exp\left(-\kappa z_i^{\mathrm{inf}}\right)
```

where $g$ is the viral load profile and $\kappa$ is the reduction in log
viral load per unit of immunity level. The profile is a Gaussian curve in
log time since infection, with its peak of 1 at $\tau_{\mathrm{peak}}$
days:

<a id="eq-viral-load-profile"></a>

```math
g(\tau) = \exp\left(-\frac{\left(\log (\tau / \tau_{\mathrm{peak}})\right)^2}{2 w^2}\right),
\qquad g(0) = 0
```

where $w$ is the width of the profile on the log time scale.

Because $g(0) = 0$, an individual has $V_i = 0$ during the timestep in
which they are infected, so cannot transmit until the next timestep.
Individuals who are not infected have $V_i = 0$.

<a id="sec-generation-interval"></a>

### Generation interval

Within an infection, viral load is a fixed scale,
$\nu_i e^{-\kappa z_i^{\mathrm{inf}}}$, multiplied by $g$. The intrinsic
generation interval (the time from infection to onward transmission, if
the individual's contact events, and the susceptibility of the people they
meet, do not change over the infection) therefore has a density
proportional to $g$, which is a lognormal density:

<a id="eq-generation-interval"></a>

```math
\text{generation interval} \sim
  \mathrm{LogNormal}\left(\log \tau_{\mathrm{peak}} + w^2,\ w\right)
```

The meanlog exceeds $\log \tau_{\mathrm{peak}}$ by $w^2$ because a
lognormal density is $g(\tau)$ divided by $\tau$, up to a constant. This
holds apart from the truncation at recovery
([Duration of infection](#sec-duration)) and the discrete timesteps.

<a id="sec-immunity"></a>

## Recovery and immunity

At step 2 of each timestep, every infected individual whose viral load has
passed its peak and is below a threshold recovers:

<a id="eq-recovery"></a>

```math
\text{if } X_i = 1, \ \tau_i^{\mathrm{inf}} \ge \tau_{\mathrm{peak}} \text{ and } V_i < V_{\mathrm{rec}}: \qquad
X_i \leftarrow 0
```

where $V_{\mathrm{rec}}$ is the recovery threshold: the viral load at
recovery, as a fraction of the peak viral load of a typical infection. The
viral load is the one calculated at step 3 of the previous timestep
([Advancing individuals](#sec-advance)).
Recovery ends transmission and allows reinfection.

Immunity is boosted at infection ([boost equation](#eq-boost)). It then
declines at a constant rate until it is lost:

<a id="eq-immunity"></a>

```math
z_i(t) = \max\left(0,\ z_i^{\mathrm{boost}} - \omega\, \tau_i^{\mathrm{boost}}(t)\right)
```

where $z_i^{\mathrm{boost}}$ is the immunity level just after the most
recent boost, and $\omega$ is the rate at which immunity wanes, in log
hazard ratio per day. Immunity is therefore lost
$z_i^{\mathrm{boost}} / \omega$ days after the most recent boost, so higher
immunity lasts longer. $z_i = 0$ when $\tau_i^{\mathrm{boost}} = \infty$.

The hazard of infection is proportional to $\exp(-z_i)$
([susceptibility score equation](#eq-susceptibility-score)), so it rises
slowly at first after a boost and reaches its full value abruptly when
immunity is lost.

<a id="sec-duration"></a>

### Duration of infection

The duration of infection follows from the viral load. Setting
$V_i = V_{\mathrm{rec}}$ in the [viral load equation](#eq-viral-load)
gives the time since infection at which viral load falls below
$V_{\mathrm{rec}}$:

<a id="eq-duration"></a>

```math
\tau_{\mathrm{end}} = \tau_{\mathrm{peak}}
  \exp\left(w \sqrt{2 \log \frac{\nu_i e^{-\kappa z_i^{\mathrm{inf}}}}{V_{\mathrm{rec}}}}\right)
  \quad \text{if } \nu_i e^{-\kappa z_i^{\mathrm{inf}}} > V_{\mathrm{rec}},
  \qquad \text{otherwise } \tau_{\mathrm{end}} = \tau_{\mathrm{peak}}
```

and the infection ends at the first step 2 at which
$\tau_i^{\mathrm{inf}} \ge \tau_{\mathrm{end}}$. A typical infection, with
$\nu_i e^{-\kappa z_i^{\mathrm{inf}}} = 1$, lasts about
$\tau_{\mathrm{peak}} \exp\left(w \sqrt{-2 \log V_{\mathrm{rec}}}\right)$
days. Infections with a higher viral load level last longer, and immunity
at infection shortens infections.

<a id="sec-advance"></a>

## Advancing individuals

At step 3 of each timestep, for every individual:

<a id="eq-advance"></a>

```math
a_i \leftarrow a_i + \frac{\Delta t}{365.25}, \qquad
\tau_i^{\mathrm{inf}} \leftarrow \tau_i^{\mathrm{inf}} + \Delta t \ \text{ if } X_i = 1, \qquad
\tau_i^{\mathrm{boost}} \leftarrow \tau_i^{\mathrm{boost}} + \Delta t
```

then $z_i$ is recalculated from the [immunity equation](#eq-immunity), and
$V_i$ from the [viral load equation](#eq-viral-load).
Ages are in years and elapsed times in days.

<a id="sec-notation"></a>

## Notation

**Settings**

| Symbol | Meaning | Support | Units | Code name |
|---|---|---|---|---|
| $N$ | population size | positive multiple of $H$ | individuals | `population_size` |
| $H$ | household size | $\lbrace 1, 2, \dots \rbrace$ | individuals | `household_size` |
| $I_0$ | number of individuals infected at the start | $\lbrace 1, \dots, N \rbrace$ | individuals | `initial_infections` |
| $\Delta t$ | timestep length | $(0, \infty)$ | days | `timestep_length` |
| $A_{\max}$ | upper limit of initial ages (80) | $(0, \infty)$ | years | `maximum_initial_age` |
| $A$ | age at which individuals become adults (18) | $(0, A_{\max})$ | years | `adult_age` |
| $V_{\mathrm{rec}}$ | recovery threshold (0.001): viral load, after the peak, below which an infection ends, as a fraction of the peak viral load of a typical infection | $(0, 1)$ | | `recovery_viral_load_threshold` |

**Parameters**

| Symbol | Meaning | Support | Units | Code name |
|---|---|---|---|---|
| $\beta_0$ | baseline hazard of transmission: for an adult infected individual with viral load 1 (the peak of a typical infection), an adult uninfected individual with no immunity, and a non-household contact event | $(0, \infty)$ | per hour | `baseline_transmission_hazard` |
| $\alpha_{\mathrm{inf}}$ | log hazard ratio for an infected individual who is a child | $\mathbb{R}$ | | `child_infectiousness_score` |
| $\alpha_{\mathrm{sus}}$ | log hazard ratio for an uninfected individual who is a child | $\mathbb{R}$ | | `child_susceptibility_score` |
| $\alpha_{\mathrm{hh}}$ | log hazard ratio for a household contact event | $\mathbb{R}$ | | `household_location_score` |
| $\bar d_{\mathrm{hh}}$ | daily duration of a household contact event | $[0, 24]$ | hours per day | `household_contact_event_hours_per_day` |
| $\bar d_{\mathrm{nh}}$ | daily duration of a non-household contact event | $[0, 24]$ | hours per day | `non_household_contact_event_hours_per_day` |
| $c$ | non-household contact events per person per day | $[0, \infty)$ | per day | `non_household_contact_events_per_person_per_day` |
| $\sigma_\nu$ | sdlog of the viral load level | $[0, \infty)$ | | `viral_load_level_sdlog` |
| $\tau_{\mathrm{peak}}$ | time since infection at which viral load peaks | $(0, \infty)$ | days | `viral_load_peak_time` |
| $w$ | width of the viral load profile on the log time scale; also the sdlog of the intrinsic generation interval | $(0, \infty)$ | | `viral_load_profile_width` |
| $\kappa$ | reduction in log viral load per unit of immunity level at infection | $[0, \infty)$ | | `viral_load_immunity_effect` |
| $\mu_z$ | meanlog of the size of an immunity boost | $\mathbb{R}$ | | `immunity_boost_meanlog` |
| $\sigma_z$ | sdlog of the size of an immunity boost | $[0, \infty)$ | | `immunity_boost_sdlog` |
| $\rho$ | correlation between the log viral load level and the log size of the immunity boost of an infection | $[0, 1]$ | | `viral_load_boost_correlation` |
| $\omega$ | rate at which immunity wanes | $[0, \infty)$ | log hazard ratio per day | `immunity_waning_rate` |

**Individual state**, for individual $i$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $h_i$ | household to which the individual belongs | | `household` |
| $a_i$ | age | years | `age` |
| $g_i$ | 1 if a child, 0 if an adult | | `is_child()` |
| $X_i$ | 1 if infected, 0 otherwise | | `infected` |
| $\tau_i^{\mathrm{inf}}$ | time since most recent infection | days | `time_since_infection` |
| $\tau_i^{\mathrm{boost}}$ | time since most recent immunity boost, which is at infection; $\infty$ if never boosted | days | `time_since_boost` |
| $\Delta z_i$ | size of the most recent immunity boost | log hazard ratio | `boost_size` |
| $z_i^{\mathrm{boost}}$ | immunity level just after the most recent immunity boost; 0 if never boosted | log hazard ratio | `immunity_after_boost` |
| $\nu_i$ | viral load level of the current or most recent infection | | `viral_load_level` |
| $V_i$ | viral load | | `viral_load` |
| $z_i$ | immunity level: the reduction in log hazard of infection | log hazard ratio | `immunity_level` |
| $z_i^{\mathrm{inf}}$ | immunity level at the start of the current or most recent infection | log hazard ratio | `immunity_at_infection` |
| $\eta_i^{\mathrm{inf}}$ | infectiousness score | log hazard ratio | `infectiousness_score()` |
| $\eta_i^{\mathrm{sus}}$ | susceptibility score | log hazard ratio | `susceptibility_score()` |

**Contact events**, for contact event $k$

| Symbol | Meaning | Units | Code name |
|---|---|---|---|
| $\mathcal C_{\mathrm{hh}}$ | set of pairs of individuals with a household contact event in a timestep | | |
| $\ell_k$ | location: 1 if a household contact event, 0 otherwise | | `in_household` |
| $d_k$ | duration | hours | `duration` |
| $\beta_k$ | hazard of transmission | per hour | `hazard` |
| $p_k$ | probability of transmission | | `transmission_probability()` |
| $M$ | number of non-household contact events in a timestep | | `number_of_non_household_contact_events` |

**Functions, derived quantities and operators**

| Symbol | Meaning |
|---|---|
| $n$, $t_n$ | timestep index, and the time at which timestep $n$ starts |
| $g(\tau)$ | viral load profile: a Gaussian curve in log time since infection, peaking at 1 |
| $\tau_{\mathrm{end}}$ | time since infection at which viral load falls below $V_{\mathrm{rec}}$, in days |
| $\mathbb{1}[\cdot]$ | 1 when the condition in brackets holds, 0 otherwise |
| $\lceil x \rceil$ | smallest integer greater than or equal to $x$ |
| $x \leftarrow y$ | $x$ is set to $y$ |
