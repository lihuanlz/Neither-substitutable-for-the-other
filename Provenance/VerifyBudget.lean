/-
# Verification budget: the optimal number of verification rounds \(N^\star\) under a TV floor

This file answers section 6 of the original analysis. The expected regret there is
written

    R(N) = p·Φ(α) + (1−p)·L·(1−q)^N + c_v·N

where the term "verify enough rounds \(N\) ⟹ miss rate \((1−q)^N \to 0\)" is refuted by
a result of `Provenance.HypothesisTest`:

    |power − false positive rate| ≤ TV(p, q)      (`Provenance.abs_mass_diff_le_tv`)

**However many rounds are run, net discrimination never exceeds `TV`.** The residual
miss rate therefore has a **floor**:

    missRate(N) = max( (1−q)^N , T ),      T = λ·TV

## The corrected model

    R(N) = p·Φ(α) + A·max( (1−q)^N , T ) + c·N

    A = (1−p)·L      miss-cost scale (larger when the human is less reliable)
    T = λ·TV         **TV floor** (independent of N)
    s = 1−q ∈ (0,1)  residual factor of one round, d = |ln s| > 0

## Key derivation

The first-order condition `c = A·s^N·d` gives the **unconstrained optimal residual**
`x_c = c/(A·d)`, while the TV floor requires `x ≥ T`. Hence the optimal attainable
residual is

    x* = max( x_c , T )

Reaching residual `x` requires `N = −ln x / d`, which is **decreasing** in `x`. Therefore

> **\(N^\star = \dfrac{-\ln\big(\max(x_c,\ T)\big)}{d} = \min(N_c,\ N_0)\)**

`x*` takes a `max` and `N*` takes a `min`: **the TV floor only ever buys you fewer
verification rounds, never more.**

## Main results

* `starN_le_floorRounds` — **a hard upper bound, independent of \(p\)**:
  \(N^\star \le N_0 = \dfrac{\ln\frac{1}{\lambda\,TV}}{\ln\frac1{1-q}}\).
  This is the mathematical form of "an unreliable human does not license unbounded
  verification".
* `starN_mono_in_p` — **\(N^\star\) is non-increasing in \(p\)**: the more reliable the
  human, the smaller the verification budget.
* `starN_strictly_mono_in_p` — strictly decreasing when the TV floor is **not binding**.
* `starN_mono_in_tv` — **\(N^\star\) is non-increasing in \(TV\)** (counterintuitive but
  correct): the further apart the two distributions, the earlier verification saturates
  and the smaller the budget.
* `regret_ge_floor` — the floor of the regret: `R(N) ≥ pΦ + A·T + cN`.
* `missRate_eq_pow_of_tv_zero` — when `TV = 0` the floor vanishes and the **original
  formula is recovered**. That is: TV is both the ceiling of the verification budget and
  its only binding constraint.

## Relation to layer 2

`p·Φ(α)` is indeed a layer-2 quantity, but it is a **constant** in \(N\) and takes no part
in the optimisation. Everything that determines \(N^\star\) comes from the layer-1 `TV`.
The two levels occupy one term each in `R(N)` and do not interfere.

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Basic
import Provenance.HypothesisTest

open scoped BigOperators

namespace Provenance

/-- Parameters of the verification budget. -/
structure VerifyParams where
  /-- probability that the human judges correctly -/
  p : ℝ
  /-- irreducible error lower bound `Φ(α)` of layer α -/
  Phi : ℝ
  /-- scale of the miss cost -/
  L : ℝ
  /-- miss probability `q` of a single verification round (rounds independent) -/
  q : ℝ
  /-- cost of a single verification round -/
  c : ℝ
  /-- total variation distance of the content layer `TV(p_H, p_A)` -/
  tv : ℝ
  /-- TV → cost conversion coefficient -/
  lam : ℝ

/-- Admissibility of the parameters. A structure rather than a conjunction, so that the
fields can be cited individually. -/
structure VOk (V : VerifyParams) : Prop where
  /-- probability non-negative -/
  p_ge_0 : 0 ≤ V.p
  /-- no one is always right: the miss cost must be positive, otherwise \(N^\star\) is meaningless -/
  p_lt_1 : V.p < 1
  /-- irreducible lower bound positive -/
  Phi_pos : 0 < V.Phi
  /-- cost scale positive -/
  L_pos : 0 < V.L
  /-- single-round miss probability positive -/
  q_pos : 0 < V.q
  /-- single-round miss probability below 1 -/
  q_lt_1 : V.q < 1
  /-- single-round cost positive -/
  c_pos : 0 < V.c
  /-- TV strictly positive (the degenerate case `TV = 0` is handled separately) -/
  tv_pos : 0 < V.tv
  /-- TV at most 1 -/
  tv_le_1 : V.tv ≤ 1
  /-- conversion coefficient positive -/
  lam_pos : 0 < V.lam

/-- The **decay rate** of a single verification round, `d = |ln(1−q)| = ln(1/(1−q)) > 0`. -/
noncomputable def decay (V : VerifyParams) : ℝ := |Real.log (1 - V.q)|

/-- The miss-cost scale `A = (1−p)·L`. The less reliable the human, the larger `A`. -/
noncomputable def lossScale (V : VerifyParams) : ℝ := (1 - V.p) * V.L

/-- The **TV floor** `T = λ·TV`: the residual miss rate that no number of verification
rounds can push down. -/
noncomputable def tvFloor (V : VerifyParams) : ℝ := V.lam * V.tv

/-- The **residual miss rate** `max((1−q)^N, T)`. -/
noncomputable def missRate (V : VerifyParams) (N : ℝ) : ℝ :=
  max ((1 - V.q) ^ N) (tvFloor V)

/-- **Expected regret** `R(N) = p·Φ + A·max((1−q)^N, T) + c·N`. -/
noncomputable def regret (V : VerifyParams) (N : ℝ) : ℝ :=
  V.p * V.Phi + lossScale V * missRate V N + V.c * N

/-- Verification rounds needed to reach a residual miss rate `x ∈ (0,1]`:
`N = −ln x / d`.

**Strictly decreasing in `x`**: the lower the target, the more rounds it takes. -/
noncomputable def roundsFor (V : VerifyParams) (x : ℝ) : ℝ :=
  -(Real.log x) / decay V

/-- Optimal residual ignoring the TV floor (first-order condition `c = A·s^N·d`):
`x_c = c/(A·d)`. -/
noncomputable def idealResidual (V : VerifyParams) : ℝ :=
  V.c / (lossScale V * decay V)

/-- **The optimal verification budget**

    N* = −ln( max( c/(A·d) , λ·TV ) ) / d

With no TV floor (`TV = 0`, `T = 0`) this degenerates to the closed form of section 6,
`ln(A·d/c)/d`, that is `ln((1−p)L·|ln(1−q)|/c) / ln(1/(1−q))`. -/
noncomputable def starN (V : VerifyParams) : ℝ :=
  roundsFor V (max (idealResidual V) (tvFloor V))

/-! ## 1. Basic positivity -/

theorem log_one_sub_q_neg {V : VerifyParams} (hV : VOk V) :
    Real.log (1 - V.q) < 0 := by
  have h1 : 0 < (1 : ℝ) - V.q := by linarith [hV.q_lt_1]
  have h2 : (1 : ℝ) - V.q < 1 := by linarith [hV.q_pos]
  have hlt : Real.log (1 - V.q) < Real.log 1 :=
    (Real.log_lt_log_iff h1 (by norm_num)).mpr h2
  rw [Real.log_one] at hlt
  exact hlt

theorem decay_pos {V : VerifyParams} (hV : VOk V) : 0 < decay V := by
  rw [decay, abs_of_neg (log_one_sub_q_neg hV)]
  exact neg_pos.mpr (log_one_sub_q_neg hV)

/-- `d = ln(1/(1−q))`, the denominator the closed form usually writes. -/
theorem decay_eq_log_inv {V : VerifyParams} (hV : VOk V) :
    decay V = Real.log (1 / (1 - V.q)) := by
  rw [decay, abs_of_neg (log_one_sub_q_neg hV)]
  have h1 : (1 : ℝ) - V.q ≠ 0 := ne_of_gt (by linarith [hV.q_lt_1])
  have h2 : (1 : ℝ) ≠ 0 := by norm_num
  rw [Real.log_div h2 h1, Real.log_one]
  ring

theorem lossScale_pos {V : VerifyParams} (hV : VOk V) : 0 < lossScale V := by
  unfold lossScale
  exact mul_pos (by linarith [hV.p_lt_1]) hV.L_pos

theorem tvFloor_pos {V : VerifyParams} (hV : VOk V) : 0 < tvFloor V := by
  unfold tvFloor
  exact mul_pos hV.lam_pos hV.tv_pos

theorem idealResidual_pos {V : VerifyParams} (hV : VOk V) : 0 < idealResidual V := by
  unfold idealResidual
  exact div_pos hV.c_pos (mul_pos (lossScale_pos hV) (decay_pos hV))

theorem maxResidual_pos {V : VerifyParams} (hV : VOk V) :
    0 < max (idealResidual V) (tvFloor V) :=
  lt_of_lt_of_le (idealResidual_pos hV) (le_max_left (idealResidual V) (tvFloor V))

/-! ## 2. Monotonicity tools: the larger the target residual, the fewer the rounds -/

theorem roundsFor_mono {V : VerifyParams} (hV : VOk V) {x x' : ℝ}
    (hx : 0 < x) (hx' : 0 < x') (h : x ≤ x') :
    roundsFor V x' ≤ roundsFor V x := by
  unfold roundsFor
  have hlog : -(Real.log x') ≤ -(Real.log x) :=
    neg_le_neg ((Real.log_le_log_iff hx hx').mpr h)
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_le_mul_of_nonneg_right hlog (inv_nonneg.mpr (le_of_lt (decay_pos hV)))

theorem roundsFor_strict_mono {V : VerifyParams} (hV : VOk V) {x x' : ℝ}
    (hx : 0 < x) (hx' : 0 < x') (h : x < x') :
    roundsFor V x' < roundsFor V x := by
  unfold roundsFor
  have hlog : -(Real.log x') < -(Real.log x) :=
    neg_lt_neg ((Real.log_lt_log_iff hx hx').mpr h)
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_lt_mul_of_pos_right hlog (inv_pos.mpr (decay_pos hV))

/-- With the same decay rate, `roundsFor` takes the same value. -/
theorem roundsFor_congr {V V' : VerifyParams} (hd : decay V = decay V') (x : ℝ) :
    roundsFor V' x = roundsFor V x := by
  unfold roundsFor
  rw [hd]

/-- `inv` is antitone on the positive reals (proved here to avoid depending on a
specific lemma name). -/
theorem inv_lt_inv_of_lt {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (h : a < b) :
    b⁻¹ < a⁻¹ := by
  by_contra hcon
  push_neg at hcon
  have hnot : ¬ (a⁻¹ ≤ b⁻¹) := by
    intro hh
    have hba : b ≤ a := (inv_le_inv₀ ha hb).mp hh
    exact absurd h (not_lt_of_ge hba)
  exact hnot hcon

/-! ## 3. The TV floor: the miss rate cannot be pushed to 0 -/

/-- **The floor exists**: under any number of verification rounds, the residual miss
rate is at least `T = λ·TV`.

This is what `|power − false positive rate| ≤ TV` looks like in the language of budgets. -/
theorem missRate_ge_tvFloor (V : VerifyParams) (N : ℝ) :
    tvFloor V ≤ missRate V N :=
  le_max_right _ _

/-- **The floor of the regret**: `R(N) ≥ p·Φ + A·T + c·N`. It does not depend on the
order of growth in the number of verification rounds. -/
theorem regret_ge_floor {V : VerifyParams} (hV : VOk V) {N : ℝ} :
    V.p * V.Phi + lossScale V * tvFloor V + V.c * N ≤ regret V N := by
  unfold regret
  have hm := missRate_ge_tvFloor V N
  have hA : 0 ≤ lossScale V := le_of_lt (lossScale_pos hV)
  have hmul : lossScale V * tvFloor V ≤ lossScale V * missRate V N :=
    mul_le_mul_of_nonneg_left hm hA
  linarith

/-! ## 4. Main theorem: a hard upper bound on \(N^\star\), independent of \(p\) -/

/-- **Core: \(N^\star\) has a hard upper bound that does not depend on \(p\).**

    N*  ≤  N_0 = ln(1/(λ·TV)) / ln(1/(1−q))

The right-hand side contains **no `p`**. So: **an unreliable human (\(p \to 0\)) does
not license unbounded verification** — TV puts a floor under the residual miss rate, and
no amount of extra verification pushes it below that floor.

This revises the conclusion of section 6 that "smaller \(p\) means larger \(N^\star\)":
\(N^\star\) does indeed grow as \(p\) falls, but **it has a ceiling**. -/
theorem starN_le_floorRounds {V : VerifyParams} (hV : VOk V) :
    starN V ≤ roundsFor V (tvFloor V) := by
  rw [starN]
  exact roundsFor_mono hV (tvFloor_pos hV) (maxResidual_pos hV)
    (le_max_right (idealResidual V) (tvFloor V))

/-- Closed form of the upper bound: `N_0 = ln(1/(λ·TV)) / ln(1/(1−q))`, **with no
\(p\)**. -/
theorem starN_le_floorRounds_closed {V : VerifyParams} (hV : VOk V) :
    starN V ≤ Real.log (1 / tvFloor V) / Real.log (1 / (1 - V.q)) := by
  have h1 : starN V ≤ -(Real.log (tvFloor V)) / decay V := starN_le_floorRounds hV
  have hT : tvFloor V ≠ 0 := ne_of_gt (tvFloor_pos hV)
  have h2 : -(Real.log (tvFloor V)) = Real.log (1 / tvFloor V) := by
    rw [Real.log_div (by norm_num) hT, Real.log_one]
    ring
  rw [h2, decay_eq_log_inv hV] at h1
  exact h1

/-! ## 5. Main theorem: \(N^\star\) is monotone in \(p\) -/

/-- **\(N^\star\) is non-increasing in the human's reliability** (same verifier, same
cost scale).

**Direction**: the more reliable the human (the larger `p`), the smaller or unchanged the
optimal verification budget.

This confirms the directional claim of section 6 (`N*` decreasing in `p`), while
`starN_le_floorRounds` puts a ceiling on it. -/
theorem lossScale_mono_in_p {V V' : VerifyParams} (hV : VOk V)
    (hp : V.p ≤ V'.p) (hL : V'.L = V.L) :
    lossScale V' ≤ lossScale V := by
  have h1 : (1 : ℝ) - V'.p ≤ 1 - V.p := sub_le_sub_left hp 1
  rw [lossScale, lossScale, hL]
  exact mul_le_mul_of_nonneg_right h1 (le_of_lt hV.L_pos)

theorem lossScale_strict_mono_in_p {V V' : VerifyParams} (hV : VOk V)
    (hp : V.p < V'.p) (hL : V'.L = V.L) :
    lossScale V' < lossScale V := by
  have h1 : (1 : ℝ) - V'.p < 1 - V.p := sub_lt_sub_left hp 1
  rw [lossScale, lossScale, hL]
  exact mul_lt_mul_of_pos_right h1 hV.L_pos

/-- The unconstrained optimal residual `x_c = c/(A·d)` is non-increasing in `p`: the
more reliable the human, the smaller the cost scale and the lower the attainable
residual. -/
theorem idealResidual_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c)
    (hp : V.p ≤ V'.p) (hL : V'.L = V.L) :
    idealResidual V ≤ idealResidual V' := by
  have hls := lossScale_mono_in_p hV hp hL
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdpos : 0 < decay V' := by rw [hdc]; exact decay_pos hV
  have hden : lossScale V' * decay V' ≤ lossScale V * decay V' :=
    mul_le_mul_of_nonneg_right hls (le_of_lt hdpos)
  have hdenpos : 0 < lossScale V * decay V' := mul_pos (lossScale_pos hV) hdpos
  have hdenpos' : 0 < lossScale V' * decay V' := mul_pos (lossScale_pos hV') hdpos
  have hinv : (lossScale V * decay V')⁻¹ ≤ (lossScale V' * decay V')⁻¹ :=
    (inv_le_inv₀ hdenpos hdenpos').mpr hden
  unfold idealResidual
  calc V.c / (lossScale V * decay V)
      = V.c / (lossScale V * decay V') := by rw [hdc]
    _ = (lossScale V * decay V')⁻¹ * V.c := by rw [div_eq_mul_inv, mul_comm]
    _ ≤ (lossScale V' * decay V')⁻¹ * V.c := mul_le_mul_of_nonneg_right hinv (le_of_lt hV.c_pos)
    _ = V'.c / (lossScale V' * decay V') := by rw [div_eq_mul_inv, mul_comm, hc]

theorem idealResidual_strict_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c)
    (hp : V.p < V'.p) (hL : V'.L = V.L) :
    idealResidual V < idealResidual V' := by
  have hls := lossScale_strict_mono_in_p hV hp hL
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdpos : 0 < decay V' := by rw [hdc]; exact decay_pos hV
  have hden : lossScale V' * decay V' < lossScale V * decay V' :=
    mul_lt_mul_of_pos_right hls hdpos
  have hdenpos : 0 < lossScale V * decay V' := mul_pos (lossScale_pos hV) hdpos
  have hdenpos' : 0 < lossScale V' * decay V' := mul_pos (lossScale_pos hV') hdpos
  have hinv : (lossScale V * decay V')⁻¹ < (lossScale V' * decay V')⁻¹ :=
    inv_lt_inv_of_lt hdenpos' hdenpos hden
  unfold idealResidual
  calc V.c / (lossScale V * decay V)
      = V.c / (lossScale V * decay V') := by rw [hdc]
    _ = (lossScale V * decay V')⁻¹ * V.c := by rw [div_eq_mul_inv, mul_comm]
    _ < (lossScale V' * decay V')⁻¹ * V.c := by
          simpa [mul_comm] using mul_lt_mul_of_pos_left hinv hV.c_pos
    _ = V'.c / (lossScale V' * decay V') := by rw [div_eq_mul_inv, mul_comm, hc]

/-- **\(N^\star\) is non-increasing in the human's reliability** (same verifier, same
cost scale).

**Direction**: the more reliable the human (the larger `p`), the smaller or unchanged the
optimal verification budget.

This confirms the directional claim of section 6 (`N*` decreasing in `p`), while
`starN_le_floorRounds` puts a ceiling on it. -/
theorem starN_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p ≤ V'.p) :
    starN V' ≤ starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hid := idealResidual_mono_in_p hV hV' hq hc hp hL
  have hmax : max (idealResidual V) (tvFloor V) ≤ max (idealResidual V') (tvFloor V') :=
    max_le_max hid hdt.symm.le
  rw [starN, starN, ← roundsFor_congr hdc (max (idealResidual V') (tvFloor V'))]
  exact roundsFor_mono hV (maxResidual_pos hV) (maxResidual_pos hV') hmax

/-- **Strictness**: when the TV floor is **not binding** (`T < x_c`), \(N^\star\) is
**strictly** decreasing in `p`.

For the verification budget to genuinely respond to the human's reliability, TV has to
be non-binding. Once TV is the bottleneck, `N*` is pinned to the constant `N_0` and
trusting anyone more changes nothing — **the bottleneck is the distinguishability of
the content layer, not the intensity of verification**. -/
theorem starN_strictly_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p < V'.p) (hfree : tvFloor V' < idealResidual V') :
    starN V' < starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hidlt := idealResidual_strict_mono_in_p hV hV' hq hc hp hL
  have hfree' : tvFloor V < idealResidual V' := by rw [← hdt]; exact hfree
  have key : max (idealResidual V) (tvFloor V) < max (idealResidual V') (tvFloor V') := by
    rw [hdt, max_eq_left (le_of_lt hfree')]
    rcases le_total (idealResidual V) (tvFloor V) with h | h
    · rw [max_eq_right h]
      exact hfree'
    · rw [max_eq_left h]
      exact hidlt
  rw [starN, starN, ← roundsFor_congr hdc (max (idealResidual V') (tvFloor V'))]
  exact roundsFor_strict_mono hV (maxResidual_pos hV) (maxResidual_pos hV') key

/-! ## 6. Main theorem: \(N^\star\) is monotone in `TV` -/

/-- **\(N^\star\) is non-increasing in `TV`**.

Counterintuitive but correct: the further apart the two distributions, the earlier
verification saturates and the **smaller** the budget needed. Raising `TV` therefore does
not make human review safer; it makes machine verification cheaper. -/
theorem starN_mono_in_tv {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam)
    (hL : V'.L = V.L) (hp : V'.p = V.p) (htv : V.tv ≤ V'.tv) :
    starN V' ≤ starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V ≤ tvFloor V' := by
    unfold tvFloor
    rw [hlam]
    exact mul_le_mul_of_nonneg_left htv (le_of_lt hV.lam_pos)
  have hid1 := idealResidual_mono_in_p hV hV' hq hc hp.symm.le hL
  have hid2 := idealResidual_mono_in_p hV' hV hq.symm hc.symm hp.le hL.symm
  have hid : idealResidual V = idealResidual V' := le_antisymm hid1 hid2
  have hmax : max (idealResidual V) (tvFloor V) ≤ max (idealResidual V') (tvFloor V') :=
    max_le_max (le_of_eq hid) hdt
  have hstep : roundsFor V (max (idealResidual V') (tvFloor V'))
      ≤ roundsFor V (max (idealResidual V) (tvFloor V)) :=
    roundsFor_mono hV (maxResidual_pos hV) (maxResidual_pos hV') hmax
  rw [starN, starN, roundsFor_congr hdc.symm (max (idealResidual V') (tvFloor V'))]
  exact hstep

/-! ## 7. Degenerate case: `TV = 0` recovers the original formula -/

/-- **When `TV = 0` the floor disappears**: the miss rate is just `(1−q)^N`, and
verification can approach 0 arbitrarily closely.

That is: TV is both the ceiling of the verification budget and its only binding
constraint. `TV = 0` means the two distributions coincide exactly, and only then is it
worth speaking of "a few more rounds". -/
theorem missRate_eq_pow_of_tv_zero {V : VerifyParams} (hV : VOk V) (htv : V.tv = 0)
    (N : ℝ) : missRate V N = (1 - V.q) ^ N := by
  unfold missRate tvFloor
  rw [htv, mul_zero]
  exact max_eq_left (Real.rpow_nonneg (show (0:ℝ) ≤ 1 - V.q by linarith [hV.q_lt_1]) N)

end Provenance