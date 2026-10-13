/-
# Human and AI contribution, formalised: entry point

Two layers, each of them with machine-checked proofs in this package.

## Layer 1: content layer - provenance identifiability (retrospective attribution)

* `Provenance.Basic` - total variation distance TV, test accuracy, Bayesian
  optimality, non-identifiability.
* `Provenance.Contamination` - the TV mixing theorem, the exponential law for
  recursive contamination, the collapse upper bound.
* `Provenance.Coverage` - the coverage function, submodularity, the single-sample
  marginal gain theorem.
* `Provenance.HypothesisTest` - **the TV theorem in set form** and the
  **Neyman-Pearson power upper bound**: for any test (z-test, t-test, any
  threshold) the "hits minus false alarms" never exceeds `TV`, and that upper
  bound is attainable.
* `Provenance.Examples` - exact rational instance cross-checks.

Core results: the best detection advantage is `TV/2`; `TV = 0` iff every test is
exactly random; a contamination rate `π` attenuates the advantage **exactly**
linearly to a factor `π`; **no statistical test can break through `TV`**. The
bottleneck at the content layer is `TV` itself, not that the tests are not good
enough.

### The verification budget correction (`Provenance.VerifyBudget`)

    miss rate(N) = max( (1−q)^N , λ·TV )        ← TV floor

    N* = −ln( max( c/(A·d) , λ·TV ) ) / d,     A=(1−p)L,  d=ln(1/(1−q))

* `starN_le_floorRounds` - **\(N^\star\) has a hard upper bound independent of
  \(p\)**: however inaccurate the human is, the verification budget cannot grow
  without limit.
* `starN_mono_in_p` - \(N^\star\) is non-increasing in \(p\), strictly decreasing
  when the TV floor does not bind.
* `starN_mono_in_tv` - \(N^\star\) is non-increasing in `TV`: the larger TV, the
  earlier verification saturates and the smaller the budget.

## Layer 2: system layer - contribution decomposition under observation-layer filtering (ex-ante pricing)

* `Provenance.Refinement` - lifts "truth" from a point to an equivalence class
  \([s^*]_\alpha\) on an observation layer, lifts the error from a single value to
  a layer-indexed function, and decomposes the contribution into
  **"the human changes \(\Phi(\alpha)\)"** and **"the AI compresses \(e_t^\alpha\)
  down to \(\Phi(\alpha)\)"**.
* `Provenance.Value` - **separability of influence and value**: why KL, or any
  information gain, **cannot** stand in for value.
* `Provenance.VerifyBudget` - **layer 2 landing on layer 1**: the optimal
  verification budget \(N^\star\) under the TV floor. It corrects the `R(N)` of
  original section 6, where the miss rate cannot be pushed to 0, and gives a
  closed form together with three monotonicity statements.
* `Provenance.Incommensurable` - **incommensurability** (original section 8,
  item 1). \(\mathcal U\) = order-preserving + additive + \(\phi(1)=1\), on the
  signed domain \(\mathbb{R}\).

### The core duality proved at layer 2

* **The AI's total within-layer gain has a hard upper bound** `log(e₀/Φ)`, and
  that upper bound is **decided by the layer alone, independent of the step count**;
* **The human's layer-change gain has no upper bound**;
* **No layer change means zero human gain** (a good question ⟺ strictly lowering
  Φ, see `positive_layer_gain_iff_strict_drop`);
* **Vanishing marginal AI contribution** holds only under a fixed layer, and a
  fixed layer is precisely the state in which the human contributes nothing.

### The counterexamples proved at layer 2

* `influence_value_separable` - two outputs of equal absolute influence can have
  values `+M` and `−M`, **with \(M\) arbitrarily large**. So the proposal of using
  influence as a proxy for value fails mathematically.
* `separation_grows_without_bound` - a large influence is exactly the dangerous
  case; screening down to a small sample does not help.
* `cover_value_is_a_layer_gain` - `ΔCover` is not an independent third term, it is
  a special case of the between-layer gain.
* `layered_bits_decomposition` - a two-term bit decomposition (between-layer plus
  within-layer), with no double counting and a single unit.

### The verdict on incommensurability (`Provenance.Incommensurable`)

Item 1 of original section 8 is **neither a theorem nor a counterexample - it
splits into two regimes**:

* **The TV floor binds (\(T \ge x_c\))**: **fully incommensurable**.
  `starN_indep_of_p_when_floor_binds` - two humans of any two different
  reliabilities give **exactly the same** \(N^\star\), not even a monotonicity.
* **The TV floor does not bind (\(T < x_c\))**: **commensurable, but not linearly**.
  `starN_exp_formula` gives \(\exp(d\,N^\star)=A\,d/c\), that is
  \(A=\tfrac{c}{d}e^{dN^\star}\) - **order-preserving** but **not affine**, so it
  is not in \(\mathcal U\).

The accurate statement is therefore "**no linear conversion exists**" rather than
"**fully incommensurable**". The latter is too strong and would be killed by Lean.

In addition `incommensurable_witness` gives the literal form of item 1 of original
section 8: **within a single process the AI's workload can be arbitrarily large
while the human's cost is arbitrarily small** - neither quantity controls the
other.

## Layer 3: calibration non-identifiability - the sign is not determined by the data

`Provenance.Calibration` asks an earlier question: for those quantities used to
**measure** human and AI contribution, where does their own direction come from?

Take the most widely used "minimal necessary human contribution" estimator in the
literature, the original formula divided by \(I(y)\):

  `minContribution s tau = 1 - tau / s`

where `s` = the mean per-token unconditional surprisal of the output and
`tau` = the fitted plausibility threshold.

* **The human does not appear in the formula** - `reported_ignores_human` /
  `human_cannot_move_reported`: the reported value depends on the output alone and
  does not move by a single unit when the human input changes.
* **The sign is decided by the relative size of threshold and surprisal, and is
  unrelated to the collaboration** - the main theorem `sign_not_identified`: for
  any single output, **there exist two calibrations for which `signOf` takes
  opposite values**; `sign_not_identified_exact` pins the witnesses down further to
  `tau = s/2` and `tau = 3s/2`.
* The threshold `tau` is fitted precisely **out of distribution**, so the sign is
  not identified by the data (`sign_not_identified_in_context`).
* Incidentally refuting the `[0,1]` reading for the estimator variant: `lt_one`
  gives the upper bound, `estimator_not_a_proportion` refutes non-negativity
  outright, and `unbounded_below` shows there is no lower bound.

This layer turns "sign non-identifiability" from a prose-level criticism into a
machine-checkable theorem: **the apparent sign is a product of calibration, not a
product of measurement.**

## Side topic: fragmentation - why innovation is hard to scale

`Provenance.Fragmentation` is an **independent problem**, not the same question as
the three layers above. It does not ask whether the source can be detected. It
asks whether innovation scales up under human-AI collaboration.

The core assertion: **on a fixed layer, the layer movement a coalition achieves
equals the layer movement of its best member** (`marginal_agent_pure_waste`); and
holding an increment back amounts to waiting on a window that will be overwritten
(`holdValue_antitone`, `publish_dominates_when_covered`).

* `marginal_agent_pure_waste` - the N+1st person: gain exactly 0, cost exactly `log(Φ/a)`
* `waste_nonneg` / `headcount_adds_waste_only` - merging never adds output, headcount only adds waste
* `saturation_duality` - sets the human-side "independent of headcount" beside the AI-side "independent of step count"
* `fragmentation_squeeze` - both routes, adding people and holding back, are blocked at once
* `scale_by_new_layers_not_by_headcount` - the only exit is a new layer

**Falsifiable point**: this module models a coalition as taking its best member, of
`max` type. If two people really can beat the better of the two in practice,
`add_member_same_reach` fails at once. This is the place where the topic is most
easily overturned by reality, which is why it is written as a theorem rather than
left to intuition.

## Reproduction

```
cd /d D:\lean_proj\source_identifiability
lake build
```

-/

import Provenance.Basic
import Provenance.Contamination
import Provenance.Coverage
import Provenance.HypothesisTest
import Provenance.Refinement
import Provenance.Value
import Provenance.VerifyBudget
import Provenance.Incommensurable
import Provenance.Calibration
import Provenance.Examples
import Provenance.Fragmentation
import Provenance.Corpus
import Provenance.Tagged