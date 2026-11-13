# Design specification

This document sets out the rules for building and maintaining models under
the procedure described in the README. It is for the researchers who
review models and for the AI agents that implement them. Agents must
follow it.

## 1. Repository contents and review

| Content | Location | Written by | Reviewed by |
|---|---|---|---|
| Written description | `model/description.md` | agents | researchers, in detail |
| Mathematical description | `model/maths.md` | agents | researchers, in detail |
| Reference implementation (R) | `model/reference/` | agents | researchers, in detail |
| Links between the three | `model/mapping.yaml` | agents | researchers |
| Unit tests | `model/tests/` | agents | researchers |
| Behaviour figures, and the scripts that make them | `reports/` | agents | researchers |
| Acceptable divergence of the approximate simulator | `validation/tolerances.md` | agreed with researchers | researchers |
| Exact simulator | `impl/exact/` | agents | tests only |
| Approximate simulator | `impl/approx/` | agents | tests, and divergence reports read by researchers |
| Inference and scenarios | `analysis/` | agents | researchers review results |

The reference implementation defines the model. Where anything else
disagrees with it, the other item is wrong, unless researchers decide the
reference implementation is wrong.

## 2. Changing the model

1. A researcher opens an issue describing the change in scientific terms.
2. An agent proposes the change as a pull request that updates, together,
   the written description, the mathematical description, the reference
   implementation, the links file, the unit tests, and the behaviour
   figures. If any of these does not need to change, the pull request says
   why.
3. Automated checks run the unit tests, regenerate the behaviour figures,
   check the links file, and rebuild the review page.
4. Researchers review, using the review page, and comment. The agent
   responds with further changes until the researchers approve.
5. After approval, an agent updates the exact and approximate simulators in
   a separate pull request, which is accepted when the tests in Sections 6
   and 7 pass. Each simulator records which version of `model/` it was last
   tested against, so it is visible when a simulator is out of date.

## 3. The three descriptions

**Written description.** Plain scientific prose. Where it helps, follow
the ODD (Overview, Design concepts, Details) protocol for describing
agent-based models (Grimm et al. 2020). Each section has a label, such as
`sec-immunity`, so other documents can refer to it.

**Mathematical description.** Each symbol is defined briefly in the text
where it is first used, and in full in tables at the end of the document,
which also give its units and its name in the code. A symbol keeps one
meaning throughout the document. Each equation has a label, such as
`eq-immunity`. Parallel quantities that refer to different events share a
symbol and are distinguished by a text superscript naming the event: for
example, the time since infection and the time since an immunity boost
are `\tau_i^{\mathrm{inf}}` and `\tau_i^{\mathrm{boost}}`, and the immunity
level at infection and just after a boost are `z_i^{\mathrm{inf}}` and
`z_i^{\mathrm{boost}}`.

**Labels and equations.** Both descriptions must render on GitHub, where
researchers review them. A label is an HTML anchor on the line before its
heading or equation, such as `<a id="eq-immunity"></a>`, and is referred to
with an ordinary link, such as `[immunity equation](#eq-immunity)`. Display
equations go in fenced `math` code blocks, not between `$$`. In inline
maths (`$...$`), write subscripts before superscripts (`\tau_i^{b}`, not
`\tau^{b}_i`), and never put an underscore straight after a closing brace,
because GitHub can read it as the start of italics. Agents check the
rendering with GitHub's Markdown API before pushing.

**Links file.** The three descriptions do not divide the model in the same
way, so they are linked by a list of model features in
`model/mapping.yaml`. Each feature lists the description sections,
equations, R functions and figures involved, and any of these may appear
under several features. Automated checks confirm that everything named in
the file exists, and that every equation and model function appears under
at least one feature.

**Review page.** Built automatically for each proposed change. For each
feature it shows the description text, equations, code, and behaviour
figures together, listing first the features affected by the change, with
figures from before and after it. It also shows whole-model behaviour under
perturbations and interventions.

## 4. The reference implementation

The reference implementation is written to be read by infectious disease
modellers who read R but may not use it daily. Speed is not a
consideration. If a figure takes too long to produce, use a smaller
population or fewer replicates; do not restructure the code.

### Language

1. Base R only: no packages beyond those R loads by default (`base`,
   `stats`, `graphics`, `grDevices`, `utils`), and no classes. The one
   exception is a distribution these lack, drawn from a recommended
   package that ships with R and called with `::`, such as
   `MASS::mvrnorm()` for a multivariate normal.
2. Functions take values and return new values. No environments, `<<-`,
   `assign()` or `get()`, except for the simulation clock (rule 5).
3. No non-standard evaluation, such as `with()`, `subset()` or formulas.
4. Everything a function uses is passed to it as an argument, apart from
   the global settings in rule 5. No default argument values.
5. Settings, data and parameters are held in one list, `globals`, defined
   in one file. Functions read it with `setting("name")` and
   `parameter("name")`, which stop with an error if the name does not
   exist. (Reading a misspelt name with `$` returns `NULL` without an
   error.) Model functions never change `globals`. The current simulation
   time is read with `current_time()`. It is the only value that changes
   during a simulation without being passed as an argument, and only the
   main simulation loop sets it. Tests of functions that read it set it
   first.
6. One version of the model. No options or flags that switch between
   alternative structures. A proposed alternative is kept on a separate
   branch until researchers choose; a permanent alternative is a separate
   repository (Section 9).
7. Each function's last line is its returned value, outside any `if`. No
   `return()`.
8. Loop over individuals with `for`. Use `seq_len(n)` or `seq_along(x)`
   rather than `1:n` or `1:length(x)`: when `n` is zero, `1:n` is `c(1, 0)`
   and the loop runs twice instead of not at all, so a reviewer would have
   to check every loop for that case. This happens in practice, for
   example when a Poisson number of contact events is zero. Use a
   vectorised base function only when it reads at least as clearly as a
   loop, as `sum()` does.
9. Draw random numbers with R's named distribution functions (`rlnorm`,
   `rpois`, `runif`) rather than writing sampling out by hand, so the code
   and the equations name the same distribution. Draw jointly distributed
   quantities from their joint distribution, as the equations write it,
   rather than building them from independent draws. Use `sample.int()`
   rather than `sample()` on a number.
10. Use `&&` and `||` in `if` conditions.

### Individual state

1. Each individual carries their age, the time elapsed since each event
   that their state depends on (such as time since infection and time
   since last immunity boost), and the current levels calculated from
   those times (such as viral load and immunity level).
2. Event functions (such as infection, recovery and boosting) set the
   relevant elapsed time to zero and the level to its starting value.
3. Between events, one function, `advance_individuals_one_timestep()`, adds
   the length of one timestep to each individual's age and elapsed times,
   then recalculates each level from its elapsed time using the formula
   for the level as a function of time, rather than by updating the
   previous level. Apart from event functions, no other function changes
   ages, elapsed times or levels.
4. Other functions read levels from the individual rather than calculating
   them.
5. The timestep length is a setting, `setting("timestep_length")`, in days.
   Code does not assume it is one day.

### Names and comments

1. Objects such as an individual or a contact event are named lists, with the
   same element names everywhere they appear. The list of all individuals
   is called `population`, and one of its elements `individual`. An object
   that is updated keeps its name (`population <- ...`); a second name is
   used only where a function needs the old and new versions together.
   Function names say what the function returns or does. A function
   named for the value it returns builds that value in a variable of the
   same name, without any `random_` prefix: for example `viral_load`
   inside `viral_load()`, and `non_household_contact_events` inside
   `random_non_household_contact_events()`. Other variables take the name
   of what they hold, without generic words such as `result`, `value` or
   `count`.
2. A function that draws random numbers, directly or through the functions
   it calls, has a name starting `random_`. All other functions give the
   same output for the same input. Random values are drawn in the `random_`
   function and passed to the others.
3. Each recurring term has one meaning, defined once. For example, *score*
   means an additive term on the log hazard scale throughout, and no other
   word is used for the same idea.
4. Parameter names state what they are and on what scale, for example
   `infectiousness_profile_meanlog`.
5. Name a loop variable for what it holds, for example `household` or
   `timestep`. The exceptions are positions in the population and in the
   list of contact events, which are `i` and `k`, as in the mathematical
   description; `individual` and `contact_event` are the objects
   themselves.
6. When a function takes two or more arguments of the same kind, name them
   at the call, for example
   `random_transmission_outcome(infector = individual_a, infectee = individual_b)`.
7. Comments explain what the names do not, such as units, scales and the
   reason for a step, in as few words as possible.

### When to write a function

Write a separate function when it:

- corresponds to a sentence of the written description or a term in an
  equation;
- has its own behaviour figure or unit test;
- separates a random draw from a calculation;
- is used in more than one place in the model; or
- keeps the calling function under about 40 lines, with no more than two
  levels of nested loops and `if`s.

Write the code in place when the function's name would be no clearer than
its body, when it would need more than three or four arguments only to pass
information through, or when it is used once and its name would repeat a
comment. Do not combine two pieces of code because they look similar if
they describe different processes. Do not pass functions as arguments.

Order functions so that each appears above the functions it calls. Keep
each file to one group of related processes.

## 5. Unit tests and behaviour figures

These are not part of the model, so need not follow the rules in Section 4.

**Unit tests** use testthat. Each test checks one stated behaviour, with a
description that reads as a sentence. Prefer unit tests to checks within
the model code. Add a check to the model code (with `stopifnot()`) only
where a test cannot easily catch the error.

**Behaviour figures** use ggplot2 with a theme shared by all repositories
in this lineage and copied with them. Each figure script starts with a
comment stating what behaviour is expected and why, so reviewers can
compare the figure with the expectation. Component figures show one
process in isolation as its parameters vary. Whole-model figures show
epidemics under perturbations and interventions, with replicate
simulations, including extinction frequencies and other outcomes near
unstable states. Figures use fixed random seeds, and are committed so that
changes to them show in pull requests.

## 6. The exact simulator

The exact simulator implements the same model in a fast language. It is
tested against the reference implementation at two levels (comparing two
implementations of one model this way is called "docking"; Axtell et al.
1996):

1. Every function that does not draw random numbers gives the same output
   as its counterpart in the reference implementation for the same inputs,
   to floating-point precision.
2. Whole-model outputs from replicate simulations are statistically
   indistinguishable between the two implementations. Random number
   sequences differ between languages, so these comparisons are of
   distributions. Before relying on them, compare the reference
   implementation with itself across random seeds to establish how often
   the tests fail by chance.

## 7. The approximate simulator

The approximate simulator cannot reproduce the model exactly, and its
departures from it are uneven: close in some periods, population groups or
regions of parameter space, and far apart in others. A single tolerance
cannot capture this. Instead:

- **Divergence report.** For the model as a whole, agents simulate both the
  approximate and exact simulators across a range of parameter values
  covering the prior, and across the scenarios of interest, and report
  where and how they differ, by time, age group and parameter value, with
  component figures overlaid. This has no pass or fail; it shows
  researchers the nature of the approximation.
- **Acceptance criteria.** For each analysis, researchers state the
  quantities and conclusions the analysis depends on (for example, the
  ranking of interventions, or incidence in infants in the first season)
  and how much divergence in them is acceptable. These are recorded in
  `validation/tolerances.md` and tested over the region of parameter space
  supported by the posterior, rather than the whole prior.
- When an acceptance criterion fails, agents propose alternative
  approximate structures, each with its divergence report, and researchers
  choose between them.

## 8. Inference

The model is fitted by amortised neural posterior estimation. The network
is first trained on simulations from the approximate simulator, and then
trained further on simulations from the exact simulator (Krouglova et al.
2026; Saoulis et al. 2025).

- Where possible, both simulators take the same parameters, in the same
  order and on the same scales. Parameters the approximate simulator lacks
  can be supplied and ignored, but the benefit of the first stage of
  training falls as the number of such parameters grows (Krouglova et al.
  2026).
- The second stage uses a lower learning rate than the first, and stops
  when performance on held-out exact simulations stops improving. A
  network trained only on the approximate simulator is not used for
  results.
- The final network's calibration is checked against simulations from the
  exact simulator, with simulation-based calibration (Talts et al. 2018).
  Small second-stage training sets can give biased, overconfident
  posteriors (Saoulis et al. 2025).

## 9. Copying models between repositories

1. Each repository holds one model and one analysis. A new analysis or
   disease, or a permanent variant of a model, gets a new repository.
2. A new repository is made by copying the repository of the most similar
   existing model, with its full history, and with no continuing link to
   it:

   ```sh
   git clone https://github.com/OWNER/existing-model.git new-model
   cd new-model
   git remote set-url origin https://github.com/OWNER/new-model.git
   git push -u origin main --tags
   ```

   GitHub's fork button keeps a link to the original, and its template
   feature discards the history, so neither is used. The first change in
   the new repository records the source repository, version, and archive
   DOI in the README and in `CITATION.cff`, and removes the source's
   analyses.
3. Model code is never imported from another repository: no shared R
   packages, git submodules or git subtrees.
4. When an error is found in code that other repositories also copied, an
   issue is opened in each of those that are still active, and each is
   fixed through its own review. Archived repositories are not changed.
5. Within one model, each concept in the written description has exactly
   one function. Separate processes are not merged because their code looks
   alike.
6. Code that researchers do not review, such as inference code, may be
   shared between repositories as a versioned package.
7. When an analysis is complete, its version is tagged, archived (for
   example on Zenodo) and cited by that archive or tag, and the repository
   is made read-only.
8. Information that should not be public is kept in files excluded from
   the repository, not in committed files or commit messages.

## 10. GitHub settings

- Changes to `main` are made only through pull requests that pass the
  automated checks.
- `.github/CODEOWNERS` names the researchers who must approve changes to
  `model/`, `reports/`, `validation/tolerances.md`, this document, and
  `.github/` itself. Changes to other files need no researcher approval.
  (Enforcing this in a private repository needs a paid GitHub plan.)
- Agents use their own GitHub account, with write but not administrator
  access, so they cannot change these settings or approve their own work.
- Text that agents write on GitHub, such as pull request descriptions and
  comments, says that an agent wrote it.

## 11. Rules for agents

1. Change all three descriptions, the links file, the unit tests and the
   behaviour figures together, or state why one did not need to change.
2. Write the reference implementation to Section 4. Do not optimise it for
   speed, add packages or classes, add options, or replace loops.
3. Do not create shared functions, packages or imports between model
   repositories, or merge code that only looks similar (Section 9).
4. Do not change `model/`, `reports/`, `validation/tolerances.md`, this
   document or `.github/` without researcher approval, and never change who
   must approve what.
5. Keep the exact and approximate simulators tested against the reference
   implementation, and record the version of `model/` they were tested
   against.
6. Do not weaken a test or acceptance criterion to make it pass; report the
   failure.

## 12. Decisions still open

- Whether a style guide and linter enforce these rules.
- The design of the shared ggplot2 theme.

## References

Axtell R, Axelrod R, Epstein JM, Cohen MD (1996). Aligning simulation
models: a case study and results. *Computational and Mathematical
Organization Theory* 1:123–141. [doi:10.1007/BF01299065](https://doi.org/10.1007/BF01299065)

Grimm V, Railsback SF, Vincenot CE, et al. (2020). The ODD protocol for
describing agent-based and other simulation models: a second update to
improve clarity, replication, and structural realism. *Journal of
Artificial Societies and Social Simulation* 23(2):7. [doi:10.18564/jasss.4259](https://doi.org/10.18564/jasss.4259)

Krouglova AN, Johnson HR, Confavreux B, Deistler M, Gonçalves PJ (2026).
Multifidelity simulation-based inference for computationally expensive
simulators. *International Conference on Learning Representations*.
[arXiv:2502.08416](https://arxiv.org/abs/2502.08416)

Saoulis AA, Piras D, Jeffrey N, Spurio Mancini A, Ferreira AMG, Joachimi B
(2025). Transfer learning for multifidelity simulation-based inference in
cosmology. [arXiv:2505.21215](https://arxiv.org/abs/2505.21215)

Talts S, Betancourt M, Simpson D, Vehtari A, Gelman A (2018). Validating
Bayesian inference algorithms with simulation-based calibration.
[arXiv:1804.06788](https://arxiv.org/abs/1804.06788)
