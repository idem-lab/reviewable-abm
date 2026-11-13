# Reviewable agent-based models with AI-assisted implementation

This repository describes a procedure for developing infectious disease
models to support policy decisions, using AI agents for the software
engineering while researchers keep complete oversight of the science. It
also aims to make it practical to fit complex agent-based models (ABMs) to
data rigorously, using amortised simulation-based inference.

The procedure rests on three ideas:

1. Researchers review what cannot be checked automatically: whether the
   model's written description, its equations, and its code describe the
   same model, and whether the model behaves plausibly.
2. Code whose only purpose is speed is not reviewed by researchers. It is
   checked by tests against code that they have reviewed.
3. Readable code and fast code are kept as separate implementations of the
   same model, so neither has to compromise for the other.

The procedure is under development. The design specification
([DESIGN.md](DESIGN.md)) gives the detailed rules that researchers and AI
agents follow.

## The model is defined three times

Every model is maintained as three parallel documents, which researchers
own and review in detail:

- a **written description**, in epidemiological terms;
- a **mathematical description**, with explicit notation;
- a **reference implementation**, in plain R, written for reading rather
  than speed.

When the model changes, AI agents make the equivalent change to all three,
in response to issues raised by researchers. Researchers then check that
the three still agree.

As an example, here is how one part of a model, the probability that a
contact event between two people transmits infection, might appear in each.

**Written description**

> A contact event can transmit infection only if exactly one of the pair is
> infected. Transmission occurs at a constant hazard over the duration of
> the contact event. The log of this hazard is the sum of the log of a
> baseline hazard and three effects: the infectiousness of the infected
> person (from their viral load and age group), the susceptibility of the
> uninfected person (from their immunity and age group), and the location of
> the contact event (household or elsewhere).

**Mathematical description**

For a contact event $k$ of duration $d_k$, between infected person $a$ and
uninfected person $b$:

```math
\log \beta_k = \log \beta_0 + \eta_a^{\mathrm{inf}} + \eta_b^{\mathrm{sus}}
  + \alpha_{\mathrm{hh}}\, \ell_k, \qquad
p_k = 1 - \exp\left(-\beta_k d_k\right)
```

where $\beta_k$ is the hazard of transmission, $\beta_0$ is the baseline
hazard, $\eta_a^{\mathrm{inf}}$ and $\eta_b^{\mathrm{sus}}$ are the
infectiousness and susceptibility of the two people as log hazard ratios,
$\ell_k$ is 1 if the contact event is in a household and 0 otherwise,
$\alpha_{\mathrm{hh}}$ is the log hazard ratio for a household contact event,
and $p_k$ is the probability of transmission.

**Reference implementation**

```r
# probability of transmission during one contact event, from a constant
# hazard over the contact event's duration
transmission_probability <- function(infector, infectee, contact_event) {

  baseline_transmission_hazard <- parameter("baseline_transmission_hazard")

  log_hazard <- log(baseline_transmission_hazard) +
    infectiousness_score(infector) +
    susceptibility_score(infectee) +
    location_score(contact_event)

  # per hour
  hazard <- exp(log_hazard)
  1 - exp(-hazard * contact_event$duration)

}
```

Alongside these, the reference implementation generates **behaviour
figures**: for example, transmission probability against contact event duration
for several viral loads, or immunity against time since infection for
several waning rates. These show researchers what the model's choices imply
in practice, which is often not obvious from the equations alone.

A review page, rebuilt automatically whenever the model changes, sets out
each feature of the model with its description, equations, code and
behaviour figures side by side. The links between the three documents do
not need to be one-to-one: a sentence of the description may involve
several functions, and a function may implement parts of several
equations. The review page also shows the behaviour of the whole model
under different scenarios, including dynamical feedbacks and outcomes near
unstable states, such as how often epidemics go extinct.

## Roles of researchers and AI agents

Researchers:

- own and review the written description, mathematical description,
  reference implementation, and behaviour figures;
- raise issues describing changes they want, in scientific terms;
- agree how far the approximate simulator (below) may depart from the
  model, for each question the model is used to answer;
- interpret and take responsibility for results.

AI agents:

- make each requested change consistently across all three documents, and
  regenerate the behaviour figures;
- write and maintain the fast simulators, and the tests that check them
  against the reference implementation;
- measure and document, with statistics and figures, how the approximate
  simulator differs from the model;
- run the inference and scenario simulations.

## Three simulators

The reference implementation is too slow for fitting. AI agents therefore
also maintain two faster simulators, which researchers do not routinely
review:

- An **exact simulator** implements the same model in a fast language (for
  example C++, Julia, or numba). It must reproduce the behaviour of the
  reference implementation, which is checked by tests on every change.
- An **approximate simulator**, for example a discrete-time stochastic
  compartmental model in JAX, or a machine learning emulator, is much faster
  but only behaves similarly. Some features of an ABM can only be
  approximated in a compartmental model. For example, immunity that wanes
  as a function of time since infection might be approximated by a few
  compartments in sequence, which could match the ABM closely at some times
  and diverge at others. Whether a given divergence matters depends on the
  question being asked, so acceptable divergence is agreed with researchers
  for each analysis, and documented in detail.

The approximate simulator is used for model development and most of the
inference. The exact simulator is used for the final fit and for scenario
simulations. If the two simulators take the same parameters, the neural
network trained for inference on the approximate simulator can be used as
the starting point for training on the exact simulator, which reduces the
number of slow simulations needed (Krouglova et al. 2026).

## One repository per analysis

Each analysis lives in its own repository, which holds everything needed
to reproduce it: the model, the simulators, the inference and scenario
code, and the results.

A new analysis, or a model of a new disease, starts by copying the
repository of the most similar existing model, including its full history
of changes, into a new repository. The copy is then changed as needed.
Nothing is shared between repositories afterwards. When an analysis is
complete, its repository is archived (for example on Zenodo) and cited by
that archive.

This is unusual. Software is normally written once and shared, so that a
fix or improvement in one place reaches everyone who uses it. Here, that
approach would work against review: a model shared between several
diseases or analyses needs switches between versions, and researchers
would have to check every combination, including parts that their model
does not use. Keeping one model per repository means a reviewer reads one
model from start to finish. AI agents make copying and adapting a model
fast, so the usual cost of duplicated code is small, while the cost of
keeping shared code correct for several diverging models remains.

Copying code deliberately has a basis in software engineering research:
Kapser and Godfrey (2008) judged that up to 71% of copied code in the two
open-source systems they studied had a positive effect on maintainability,
and Hinsen (2019) describes how research software that depends on
changing foundations eventually stops working. Because each repository
records the repository and version it was copied from, the history of
every line of code can still be traced.

Each repository is therefore a research compendium in the sense of Marwick
et al. (2018): a self-contained collection of the data, code and outputs of
one study, organised by a convention shared with related projects, with the
computational environment recorded, so that others can inspect, reproduce
and extend the work.

## Writing the reference implementation

The reference implementation is written for researchers who read R but
may not use it daily. The detailed rules are in [DESIGN.md](DESIGN.md). In
summary:

- plain R with no add-on packages and no classes;
- `for` loops over individuals, rather than vectorised or functional code;
- one version of the model only, with no options to switch between
  alternative structures;
- functions named so that the code reads close to the written description,
  with short comments for anything the names do not make clear;
- performance ignored entirely.

## References

Hinsen K (2019). Dealing with software collapse. *Computing in Science &
Engineering* 21(3):104–108. [doi:10.1109/MCSE.2019.2900945](https://doi.org/10.1109/MCSE.2019.2900945)

Kapser CJ, Godfrey MW (2008). "Cloning considered harmful" considered
harmful: patterns of cloning in software. *Empirical Software Engineering*
13:645–692. [doi:10.1007/s10664-008-9076-6](https://doi.org/10.1007/s10664-008-9076-6)

Krouglova AN, Johnson HR, Confavreux B, Deistler M, Gonçalves PJ (2026).
Multifidelity simulation-based inference for computationally expensive
simulators. *International Conference on Learning Representations*.
[arXiv:2502.08416](https://arxiv.org/abs/2502.08416)

Marwick B, Boettiger C, Mullen L (2018). Packaging data analytical work
reproducibly using R (and friends). *The American Statistician*
72(1):80–88. [doi:10.1080/00031305.2017.1375986](https://doi.org/10.1080/00031305.2017.1375986)
