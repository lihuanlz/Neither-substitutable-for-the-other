/-
# Verification budget: the optimal number of verification rounds \(N^\star\) under a
verification floor

This file answers section 6 of the original analysis. The expected regret there is
written

    R(N) = p·Φ(α) + (1−p)·L·(1−q)^N + c_v·N

where the term "verify enough rounds \(N\) ⟹ miss rate \((1−q)^N \to 0\)" is refuted by
a result of `Provenance.HypothesisTest`:

    |power − false positive rate| ≤ TV(p, q)      (`Provenance.abs_mass_diff_le_tv`)

A residual miss rate of exactly 0 cannot be right: \(N\) rounds of verification are
themselves a statistical test of the two hypotheses, and the Bayes bound of
`Provenance.HypothesisTest` puts every such test's error at \((1−TV)/2\) or worse.
The residual miss rate therefore has a **floor** at a fixed fraction of that bound:

    missRate(N) = max( (1−q)^N , T ),      T = λ·(1−TV)/2

## The corrected model

    R(N) = p·Φ(α) + A·max( (1−q)^N , T ) + c·N

    A = (1−p)·L        miss-cost scale (larger when the human is less reliable)
    T = λ·(1−TV)/2     **verification floor**: a fixed fraction of the Bayes error of
                       the two hypotheses (independent of N)
    s = 1−q ∈ (0,1)    residual factor of one round, d = |ln s| > 0

## Key derivation

The first-order condition `c = A·s^N·d` gives the **unconstrained optimal residual**
`x_c = c/(A·d)`, while the floor requires `x ≥ T`. Hence the optimal attainable
residual is

    x* = max( x_c , T )

Reaching residual `x` requires `N = −ln x / d`, which is **decreasing** in `x`. Therefore

> **\(N^\star = \dfrac{-\ln\big(\max(x_c,\ T)\big)}{d} = \min(N_c,\ N_0)\)**

`x*` takes a `max` and `N*` takes a `min`: **the floor only ever buys you fewer
verification rounds, never more.**

## Main results

* `tvFloor_eq_lam_bayes`, `tvFloor_le_bayes`: the floor **is** a fixed fraction `λ` of
  the Bayes error `(1−TV)/2` of the two hypotheses, and for `λ ≤ 1` never exceeds that
  error.
* `starN_le_floorRounds`: **a hard upper bound, independent of \(p\)**:
  \(N^\star \le N_0 = \dfrac{\ln\frac{2}{\lambda\,(1-TV)}}{\ln\frac1{1-q}}\).
  This is the mathematical form of "an unreliable human does not license unbounded
  verification".
* `starN_mono_in_p`: **\(N^\star\) is non-increasing in \(p\)**: the more reliable the
  human, the smaller the verification budget.
* `starN_strictly_mono_in_p`: strictly decreasing when the floor is **not binding**.
* `starN_mono_in_tv`: **\(N^\star\) is non-decreasing in \(TV\)**: the closer the two
  hypotheses, the higher the Bayes error, the earlier the floor binds and the smaller
  the budget that can pay off. Better-separated hypotheses (larger `TV`) lower the
  floor and let more rounds pay; they do not by themselves make review safer.
* `regret_ge_floor`: the floor of the regret: `R(N) ≥ pΦ + A·T + cN`.
* `missRate_eq_pow_of_tv_one`: at `TV = 1` (perfectly distinguishable hypotheses) the
  floor vanishes and the **original formula is recovered**.

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
  /-- detection probability `q` of a single verification round (rounds independent); the
  residual miss rate after `N` rounds is `(1 − q)^N` -/
  q : ℝ
  /-- cost of a single verification round -/
  c : ℝ
  /-- total variation distance of the content layer `TV(p_H, p_A)` -/
  tv : ℝ
  /-- floor as a fraction of the Bayes error `(1 − TV)/2` -/
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
  /-- single-round detection probability positive -/
  q_pos : 0 < V.q
  /-- single-round detection probability below 1 -/
  q_lt_1 : V.q < 1
  /-- single-round cost positive -/
  c_pos : 0 < V.c
  /-- TV strictly positive (the degenerate case `TV = 0` is excluded) -/
  tv_pos : 0 < V.tv
  /-- TV strictly below 1 (the boundary case `TV = 1`, perfectly distinguishable
  hypotheses, is handled separately in `missRate_eq_pow_of_tv_one`) -/
  tv_lt_1 : V.tv < 1
  /-- floor fraction positive -/
  lam_pos : 0 < V.lam
  /-- the floor `T = λ·(1−TV)/2` is a probability, so the miss rate `max((1−q)^N, T)`
  never exceeds 1 and `N*` is never negative -/
  floor_lt_one : V.lam * (1 - V.tv) / 2 < 1

/-- The **decay rate** of a single verification round, `d = |ln(1−q)| = ln(1/(1−q)) > 0`. -/
noncomputable def decay (V : VerifyParams) : ℝ := |Real.log (1 - V.q)|

/-- The miss-cost scale `A = (1−p)·L`. The less reliable the human, the larger `A`. -/
noncomputable def lossScale (V : VerifyParams) : ℝ := (1 - V.p) * V.L

/-- The **verification floor** `T = λ·(1−TV)/2`: a fixed fraction `λ` of the Bayes
error `(1−TV)/2` of the two hypotheses. This is the residual miss rate that no number
of verification rounds can push down. -/
noncomputable def tvFloor (V : VerifyParams) : ℝ := V.lam * (1 - V.tv) / 2

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

/-- Optimal residual ignoring the floor (first-order condition `c = A·s^N·d`):
`x_c = c/(A·d)`. -/
noncomputable def idealResidual (V : VerifyParams) : ℝ :=
  V.c / (lossScale V * decay V)

/-- **The optimal verification budget**

    N* = −ln( max( c/(A·d) , λ·(1−TV)/2 ) ) / d

With no floor (`TV = 1`, `T = 0`) this degenerates to the closed form of section 6,
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
  have h : 0 < 1 - V.tv := by linarith [hV.tv_lt_1]
  exact div_pos (mul_pos hV.lam_pos h) (by norm_num)

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

/-! ## 3. The floor: the miss rate cannot be pushed to 0 -/

/-- The floor is **a fixed fraction `λ` of the Bayes error `(1 − TV)/2`** of the two
hypotheses (the Bayes bound is `Provenance.HypothesisTest`). The identification of the
two sides is by rearrangement. -/
theorem tvFloor_eq_lam_bayes (V : VerifyParams) :
    tvFloor V = V.lam * ((1 - V.tv) / 2) := by
  unfold tvFloor
  ring

/-- With `λ ≤ 1` the floor never exceeds the Bayes error itself: the residual miss
rate stays at or below the error of the best possible test of the two hypotheses. -/
theorem tvFloor_le_bayes {V : VerifyParams} (hV : VOk V) (hlam : V.lam ≤ 1) :
    tvFloor V ≤ (1 - V.tv) / 2 := by
  unfold tvFloor
  have h : 0 ≤ 1 - V.tv := by linarith [hV.tv_lt_1]
  have h2 : V.lam * (1 - V.tv) ≤ 1 * (1 - V.tv) :=
    mul_le_mul_of_nonneg_right hlam h
  linarith

/-- **The floor exists**: under any number of verification rounds, the residual miss
rate is at least `T = λ·(1−TV)/2`.

This is what `|power − false positive rate| ≤ TV` looks like in the language of
budgets: `N` rounds of verification are a statistical test of the two hypotheses, and
no test beats its own Bayes floor. -/
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

    N*  ≤  N_0 = ln(2/(λ·(1−TV))) / ln(1/(1−q))

The right-hand side contains **no `p`**. So: **an unreliable human (\(p \to 0\)) does
not license unbounded verification**: the hypotheses' Bayes floor puts a floor under
the residual miss rate, and no amount of extra verification pushes it below that floor.

This revises the conclusion of section 6 that "smaller \(p\) means larger \(N^\star\)":
\(N^\star\) does indeed grow as \(p\) falls, but **it has a ceiling**. -/
theorem starN_le_floorRounds {V : VerifyParams} (hV : VOk V) :
    starN V ≤ roundsFor V (tvFloor V) := by
  rw [starN]
  exact roundsFor_mono hV (tvFloor_pos hV) (maxResidual_pos hV)
    (le_max_right (idealResidual V) (tvFloor V))

/-- Closed form of the upper bound: `N_0 = ln(2/(λ·(1−TV))) / ln(1/(1−q))`, **with no
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
theorem lossScale_mono_in_p {V : VerifyParams} (hV : VOk V)
    (hp : V.p ≤ V'.p) (hL : V'.L = V.L) :
    lossScale V' ≤ lossScale V := by
  have h1 : (1 : ℝ) - V'.p ≤ 1 - V.p := sub_le_sub_left hp 1
  rw [lossScale, lossScale, hL]
  exact mul_le_mul_of_nonneg_right h1 (le_of_lt hV.L_pos)

theorem lossScale_strict_mono_in_p {V : VerifyParams} (hV : VOk V)
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

/-- **Strictness**: when the floor is **not binding** (`T < x_c`), \(N^\star\) is
**strictly** decreasing in `p`.

For the verification budget to genuinely respond to the human's reliability, the floor
has to be non-binding. Once the floor is the bottleneck, `N*` is pinned to the
constant `N_0` and trusting anyone more changes nothing: **the bottleneck is the
distinguishability of the content layer, not the intensity of verification**. -/
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

/-- **\(N^\star\) is non-decreasing in `TV`**.

The closer the two hypotheses (the smaller `TV`), the higher the Bayes error
`(1−TV)/2`, the higher the floor, the earlier verification saturates and the
**smaller** the budget that can pay off. Raising `TV` (better-separated hypotheses)
lowers the floor and lets more rounds pay; it does not by itself make review safer. -/
theorem starN_mono_in_tv {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam)
    (hL : V'.L = V.L) (hp : V'.p = V.p) (htv : V.tv ≤ V'.tv) :
    starN V ≤ starN V' := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' ≤ tvFloor V := by
    unfold tvFloor
    rw [hlam]
    have h1 : (1 : ℝ) - V'.tv ≤ 1 - V.tv := sub_le_sub_left htv 1
    have h2 : V.lam * (1 - V'.tv) ≤ V.lam * (1 - V.tv) :=
      mul_le_mul_of_nonneg_left h1 (le_of_lt hV.lam_pos)
    linarith
  have hid1 := idealResidual_mono_in_p hV hV' hq hc hp.symm.le hL
  have hid2 := idealResidual_mono_in_p hV' hV hq.symm hc.symm hp.le hL.symm
  have hid : idealResidual V = idealResidual V' := le_antisymm hid1 hid2
  have hmax : max (idealResidual V') (tvFloor V') ≤ max (idealResidual V) (tvFloor V) :=
    max_le_max (le_of_eq hid.symm) hdt
  rw [starN, starN, ← roundsFor_congr hdc (max (idealResidual V') (tvFloor V'))]
  exact roundsFor_mono hV (maxResidual_pos hV') (maxResidual_pos hV) hmax

/-! ## 8. Optimality: `starN` minimizes the regret

The text defines `N* = starN` and derives its properties around the
minimization of `R(N) = p·Φ + A·max((1−q)^N, T) + c·N`. The theorems above
bound and compare `starN`; this section closes the gap and proves, inside
Lean, that `starN` is the exact minimizer of the regret over all real `N`.
The argument is the discrete structure of the cost: with the floor slack the
regret is convex in `N` with its minimum where the marginal round pays exactly
its cost; with the floor binding, every round past the crossing buys nothing. -/

/-- The residual decay written as an exponential: `(1−q)^N = exp(−d·N)`. -/
theorem rpow_eq_exp (V : VerifyParams) (hV : VOk V) (N : ℝ) :
    (1 - V.q) ^ N = Real.exp (-(decay V) * N) := by
  have hs0 : (0:ℝ) < 1 - V.q := by linarith [hV.q_lt_1]
  have hs1 : (1:ℝ) - V.q < 1 := by linarith [hV.q_pos]
  have hlog : Real.log (1 - V.q) = -decay V := by
    unfold decay
    rw [abs_of_neg (Real.log_neg hs0 hs1)]
    ring
  rw [Real.rpow_def_of_pos hs0, hlog]

/-- At the recommended budget the residual hits the target exactly:
`(1−q)^{roundsFor x} = x`. -/
theorem rpow_roundsFor (V : VerifyParams) (hV : VOk V) {x : ℝ} (hx : 0 < x) :
    (1 - V.q) ^ (roundsFor V x) = x := by
  rw [rpow_eq_exp V hV, roundsFor]
  have hd : decay V ≠ 0 := ne_of_gt (decay_pos hV)
  have h : -(decay V) * (-(Real.log x) / decay V) = Real.log x := by
    field_simp
  rw [h, Real.exp_log hx]

/-- The residual at the optimal budget is exactly the binding target. -/
theorem starN_missRate (V : VerifyParams) (hV : VOk V) :
    missRate V (starN V) = max (idealResidual V) (tvFloor V) := by
  unfold missRate starN
  rw [rpow_roundsFor V hV (maxResidual_pos hV)]
  exact max_eq_left (le_max_right _ _)

/-- The decay is antitone in the number of rounds. -/
theorem rpow_antitone (V : VerifyParams) (hV : VOk V) {M M' : ℝ} (h : M ≤ M') :
    (1 - V.q) ^ M' ≤ (1 - V.q) ^ M := by
  rw [rpow_eq_exp V hV, rpow_eq_exp V hV, Real.exp_le_exp]
  have hd : 0 < decay V := decay_pos hV
  have hneg : -(decay V) ≤ 0 := by linarith
  exact mul_le_mul_of_nonpos_left h hneg

/-- **The optimality theorem**: `starN` minimizes
`R(N) = p·Φ + A·max((1−q)^N, T) + c·N` over all real `N`.

With the floor slack (`T ≤ x_c`) the optimum is interior and sits where one
more round costs exactly what it saves; with the floor binding (`T > x_c`) it
sits exactly at the crossing. Either way `starN` is the exact minimizer, not
a rounding of one — this closes the last prose derivation of section 3.2. -/
theorem starN_optimal {V : VerifyParams} (hV : VOk V) (N : ℝ) :
    regret V (starN V) ≤ regret V N := by
  have hd : 0 < decay V := decay_pos hV
  have hA : 0 < lossScale V := lossScale_pos hV
  have hT : 0 < tvFloor V := tvFloor_pos hV
  have hxc : 0 < idealResidual V := idealResidual_pos hV
  have hc : 0 < V.c := hV.c_pos
  have hAd : lossScale V * decay V ≠ 0 := mul_ne_zero (ne_of_gt hA) (ne_of_gt hd)
  -- `A · x_c · d = c`: one marginal round at the ideal residual pays its cost.
  have hAxc : lossScale V * idealResidual V * decay V = V.c := by
    unfold idealResidual
    field_simp [hAd]
    ring
  have hreg : ∀ M : ℝ, regret V M
      = V.p * V.Phi + lossScale V * missRate V M + V.c * M := fun _ => rfl
  rcases le_or_lt (tvFloor V) (idealResidual V) with hle | hlt
  · -- Floor slack: the optimum is interior, at `N* = −ln x_c / d`.
    have hstar : starN V = roundsFor V (idealResidual V) := by
      rw [starN, max_eq_left hle]
    have hsN : (1 - V.q) ^ (starN V) = idealResidual V := by
      rw [hstar]; exact rpow_roundsFor V hV hxc
    have hlogxc : Real.log (idealResidual V) = -(decay V) * starN V := by
      have e := hsN
      rw [rpow_eq_exp V hV] at e
      rw [← e, Real.log_exp]
    have hregS : regret V (starN V)
        = V.p * V.Phi + lossScale V * idealResidual V + V.c * starN V := by
      rw [hreg, starN_missRate V hV, max_eq_left hle]
    rcases le_or_lt N (starN V) with hN | hN
    · -- Below the optimum: residual above `x_c`, so rounds are underpaid.
      have hge : tvFloor V ≤ (1 - V.q) ^ N := by
        have e : idealResidual V ≤ (1 - V.q) ^ N := by
          rw [← hsN]; exact rpow_antitone V hV hN
        exact hle.trans e
      have hmiss : missRate V N = (1 - V.q) ^ N := by
        unfold missRate; exact max_eq_left hge
      have hpow : (1 - V.q) ^ N
          = idealResidual V * Real.exp (decay V * (starN V - N)) := by
        rw [rpow_eq_exp V hV]
        have he : -(decay V) * N
            = Real.log (idealResidual V) + decay V * (starN V - N) := by
          linarith [hlogxc]
        rw [he, Real.exp_add, Real.exp_log hxc]
      have hexp := Real.add_one_le_exp (decay V * (starN V - N))
      have hu : 0 ≤ starN V - N := sub_nonneg.mpr hN
      have e1 : lossScale V * idealResidual V * (1 + decay V * (starN V - N))
          ≤ lossScale V * idealResidual V
            * Real.exp (decay V * (starN V - N)) :=
        mul_le_mul_of_nonneg_left (by linarith [hexp])
          (mul_nonneg (le_of_lt hA) (le_of_lt hxc))
      have e2 : lossScale V * idealResidual V * decay V * (starN V - N)
          = V.c * (starN V - N) := by rw [hAxc]
      rw [hregS, hreg, hmiss, hpow]
      nlinarith [e1, e2, mul_nonneg (le_of_lt hc) hu]
    · -- Above the optimum.
      rcases le_or_lt N (roundsFor V (tvFloor V)) with hNT | hNT
      · -- Middle region: residual still above the floor, rounds are overpaid.
        have hge : tvFloor V ≤ (1 - V.q) ^ N := by
          have e : (1 - V.q) ^ (roundsFor V (tvFloor V)) ≤ (1 - V.q) ^ N :=
            rpow_antitone V hV hNT
          rwa [rpow_roundsFor V hV hT] at e
        have hmiss : missRate V N = (1 - V.q) ^ N := by
          unfold missRate; exact max_eq_left hge
        have hpow : (1 - V.q) ^ N
            = idealResidual V * Real.exp (-(decay V * (N - starN V))) := by
          rw [rpow_eq_exp V hV]
          have he : -(decay V) * N
              = Real.log (idealResidual V) + -(decay V * (N - starN V)) := by
            linarith [hlogxc]
          rw [he, Real.exp_add, Real.exp_log hxc]
        have hexp := Real.add_one_le_exp (-(decay V * (N - starN V)))
        have hu : 0 ≤ N - starN V := sub_nonneg.mpr (le_of_lt hN)
        have e1 : lossScale V * idealResidual V * (1 - decay V * (N - starN V))
            ≤ lossScale V * idealResidual V
              * Real.exp (-(decay V * (N - starN V))) :=
          mul_le_mul_of_nonneg_left (by linarith [hexp])
            (mul_nonneg (le_of_lt hA) (le_of_lt hxc))
        have e2 : lossScale V * idealResidual V * decay V * (N - starN V)
            = V.c * (N - starN V) := by rw [hAxc]
        rw [hregS, hreg, hmiss, hpow]
        nlinarith [e1, e2, mul_nonneg (le_of_lt hc) hu]
      · -- Past the crossing: the floor binds and rounds buy nothing.
        have hle2 : (1 - V.q) ^ N ≤ tvFloor V := by
          have e : (1 - V.q) ^ N ≤ (1 - V.q) ^ (roundsFor V (tvFloor V)) :=
            rpow_antitone V hV (le_of_lt hNT)
          rwa [rpow_roundsFor V hV hT] at e
        have hmiss : missRate V N = tvFloor V := by
          unfold missRate; exact max_eq_right hle2
        have hgap : roundsFor V (tvFloor V) - starN V
            = Real.log (idealResidual V / tvFloor V) / decay V := by
          rw [hstar, roundsFor, roundsFor,
            Real.log_div (ne_of_gt hxc) (ne_of_gt hT)]
          field_simp [ne_of_gt hd]
          ring
        have hw : (0:ℝ) < idealResidual V / tvFloor V := div_pos hxc hT
        have hlogw : 1 - (idealResidual V / tvFloor V)⁻¹
            ≤ Real.log (idealResidual V / tvFloor V) := by
          have h1 := Real.log_le_sub_one_of_pos (inv_pos.mpr hw)
          rw [Real.log_inv] at h1
          linarith [h1]
        have hxcT : idealResidual V - tvFloor V
            = idealResidual V * (1 - (idealResidual V / tvFloor V)⁻¹) := by
          rw [inv_div]
          field_simp [ne_of_gt hxc]
        -- `A·(x_c − T) ≤ c·log(x_c/T)/d`: the exact form of `log w ≥ 1 − 1/w`.
        have hfinal : lossScale V * (idealResidual V - tvFloor V)
            ≤ V.c * (Real.log (idealResidual V / tvFloor V) / decay V) := by
          rw [← hAxc]
          have eRHS : lossScale V * idealResidual V * decay V
              * (Real.log (idealResidual V / tvFloor V) / decay V)
              = lossScale V * idealResidual V
                * Real.log (idealResidual V / tvFloor V) := by
            field_simp [ne_of_gt hd]
            ring
          rw [eRHS, hxcT, mul_assoc]
          exact mul_le_mul_of_nonneg_left
            (mul_le_mul_of_nonneg_left hlogw (le_of_lt hxc)) (le_of_lt hA)
        rw [hregS, hreg, hmiss]
        have e1 : lossScale V * idealResidual V - lossScale V * tvFloor V
            ≤ V.c * (roundsFor V (tvFloor V) - starN V) := by
          rw [← mul_sub, hgap]
          exact hfinal
        have e2 : V.c * roundsFor V (tvFloor V) ≤ V.c * N :=
          mul_le_mul_of_nonneg_left (le_of_lt hNT) (le_of_lt hc)
        linarith [e1, e2]
  · -- Floor binds: the optimum sits exactly at the crossing.
    have hstar : starN V = roundsFor V (tvFloor V) := by
      rw [starN, max_eq_right (le_of_lt hlt)]
    have hsN : (1 - V.q) ^ (starN V) = tvFloor V := by
      rw [hstar]; exact rpow_roundsFor V hV hT
    have hlogT : Real.log (tvFloor V) = -(decay V) * starN V := by
      have e := hsN
      rw [rpow_eq_exp V hV] at e
      rw [← e, Real.log_exp]
    have hregS : regret V (starN V)
        = V.p * V.Phi + lossScale V * tvFloor V + V.c * starN V := by
      rw [hreg, starN_missRate V hV, max_eq_right (le_of_lt hlt)]
    rcases le_or_lt N (starN V) with hN | hN
    · -- Below the crossing: residual above the floor, rounds are underpaid.
      have hge : tvFloor V ≤ (1 - V.q) ^ N := by
        rw [← hsN]; exact rpow_antitone V hV hN
      have hmiss : missRate V N = (1 - V.q) ^ N := by
        unfold missRate; exact max_eq_left hge
      have hpow : (1 - V.q) ^ N
          = tvFloor V * Real.exp (decay V * (starN V - N)) := by
        rw [rpow_eq_exp V hV]
        have he : -(decay V) * N
            = Real.log (tvFloor V) + decay V * (starN V - N) := by
          linarith [hlogT]
        rw [he, Real.exp_add, Real.exp_log hT]
      have hexp := Real.add_one_le_exp (decay V * (starN V - N))
      have hu : 0 ≤ starN V - N := sub_nonneg.mpr hN
      have e1 : lossScale V * tvFloor V * (1 + decay V * (starN V - N))
          ≤ lossScale V * tvFloor V
            * Real.exp (decay V * (starN V - N)) :=
        mul_le_mul_of_nonneg_left (by linarith [hexp])
          (mul_nonneg (le_of_lt hA) (le_of_lt hT))
      have e2 : V.c ≤ lossScale V * tvFloor V * decay V := by
        have h1 := mul_le_mul_of_nonneg_right
          (mul_le_mul_of_nonneg_left (le_of_lt hlt) (le_of_lt hA)) (le_of_lt hd)
        rw [hAxc] at h1
        exact h1
      rw [hregS, hreg, hmiss, hpow]
      nlinarith [e1, mul_nonneg (sub_nonneg.mpr e2) hu,
        mul_nonneg (le_of_lt hc) hu]
    · -- Above the crossing: the floor binds on both sides; only cost grows.
      have hmissN : missRate V N = tvFloor V := by
        have hle2 : (1 - V.q) ^ N ≤ tvFloor V := by
          rw [← hsN]; exact rpow_antitone V hV (le_of_lt hN)
        unfold missRate; exact max_eq_right hle2
      rw [hregS, hreg, hmissN]
      have e1 : V.c * starN V ≤ V.c * N :=
        mul_le_mul_of_nonneg_left (le_of_lt hN) (le_of_lt hc)
      linarith [e1]

/-! ## 7. Boundary case: `TV = 1` recovers the original formula -/

/-- **At `TV = 1` the floor disappears**: the two hypotheses are perfectly
distinguishable, the Bayes error is `0`, the miss rate is just `(1−q)^N`, and
verification can approach 0 arbitrarily closely.

Only then is it worth speaking of "a few more rounds". (Stated without `VOk`, since
`TV = 1` is exactly the boundary `VOk` excludes; `q ≤ 1` suffices.) -/
theorem missRate_eq_pow_of_tv_one {V : VerifyParams} (htv : V.tv = 1) (hq : V.q ≤ 1)
    (N : ℝ) : missRate V N = (1 - V.q) ^ N := by
  unfold missRate tvFloor
  rw [htv]
  have h0 : V.lam * (1 - 1) / 2 = 0 := by ring
  rw [h0]
  exact max_eq_left (Real.rpow_nonneg (show (0:ℝ) ≤ 1 - V.q by linarith) N)

end Provenance
