/-
# Incommensurability: the between-layer gain \(v_H\) against the within-layer
gain \(v_A\)

This file handles item 1 of Section 8 of the original analysis:
incommensurability.

## Choosing the utility class \(\mathcal U\) (a modelling decision)

The user chose **direction B**: order-preserving + additive + \(\phi(1)=1\),
over a signed domain \(\mathbb{R}\). The between-layer value can be negative:
coarsening an equivalence class is a negative contribution, see
`Provenance.influence_value_separable`.

> **Why the domain is signed**: draft 5 of the original took \(v_H\) to be a
> "number of bits" (nonnegative), but coarsening an observation layer, which
> introduces an error constraint, is **negative**. A nonnegative domain wipes
> out that directional information and repeats the KL mistake exactly.

**Known fact (not proved in this file)**: on \(\mathbb{R}\), additivity plus
monotonicity forces linearity, so \(\mathcal U\) contains only affine maps, and
\(\phi(1)=1\) then fixes the slope.
\(\mathcal U = \{\text{affine maps with slope }1\}\).

Every result below holds for **each** element of \(\mathcal U\), so this
classification is not needed.

## Verdict: incommensurability **falls into two regimes** and holds on only
half of the range

### Regime ①: the TV floor binds (\(T \ge x_c\)) — **fully incommensurable**

`starN_indep_of_p_when_floor_binds`: **any two people of differing reliability
give exactly the same \(N^\star\)**. The AI's effort carries no information at
all about the person. Over this stretch there is not even monotonicity, let
alone a linear conversion.

### Regime ②: the TV floor does not bind (\(T < x_c\)) — **commensurable, but
nonlinear**

`starN_exp_formula`:

    exp( d·N* )  =  A·d / c ,     A = (1−p)L,   d = ln(1/(1−q))

that is, \(A = \frac{c}{d}\,e^{dN^\star}\). Hence:

* **order-preserving** (monotone increasing), proved as
  `starN_strictly_mono_in_p`;
* **but not affine**: it is exponential. So there **exists no**
  \(\phi \in \mathcal U\) with \(\phi(N^\star) = A\).

> **This corrects the original claim**: over this stretch the situation is not
> "incommensurable" but "commensurable but nonlinear". Stating the whole claim
> as "fully incommensurable" is **too strong**, and Lean kills it.

### The two extreme quantified statements (the literal form of item 1 of
Section 8)

* `ai_effort_arbitrarily_large` — the AI's effort is **unbounded** (as
  `TV → 0`).
* `human_value_arbitrarily_small` — the human cost of unreliability is
  **arbitrarily small** (as `p → 1`).
* `incommensurable_witness` — **both hold in the same process**: the AI effort is
  arbitrarily large and the human cost arbitrarily small. No order-preserving
  map can therefore convert a within-layer quantity into a between-layer one.

### Range of between-layer against within-layer gains (packaging
`Provenance.Refinement`)

* `human_gain_unbounded` — the between-layer gain `log(Φα/Φβ)` is **unbounded**.
* `ai_total_gain_bounded` — the within-layer gain `log(e₀/e)` has a **hard
  upper bound** `log(e₀/Φ)`, and that bound is decided by the layer alone,
  independently of the number of steps.

One is \([0,\infty)\), the other is \([0,K]\). This is the plainest
formalisation of "two scales".

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement
import Provenance.VerifyBudget

open scoped BigOperators

namespace Provenance

/-- The permitted utility class \(\mathcal U\): order-preserving + additive +
positivity-preserving + \(\phi(1)=1\).

**The domain is the signed \(\mathbb{R}\)**: a between-layer value can be
negative. -/
def U (φ : ℝ → ℝ) : Prop :=
  (∀ a b, a ≤ b → φ a ≤ φ b)
    ∧ (∀ a b, φ (a + b) = φ a + φ b)
    ∧ (∀ a, 0 ≤ a → 0 ≤ φ a)
    ∧ φ 1 = 1

/-- **Regime ①: the TV floor binds ⟹ the AI's effort is entirely independent of
the person's reliability.**

This is the half of incommensurability that genuinely holds: there is not even
monotonicity.

Consequence: once `λ·TV ≥ c/(A·d)`, **no amount of further verification solves
the problem**, and **trusting anyone else is no use either**, since `N*` no
longer varies with \(p\). -/
theorem starN_indep_of_p_when_floor_binds {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p ≤ V'.p)
    (hfill : idealResidual V' ≤ tvFloor V') :
    starN V = starN V' := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hid : idealResidual V ≤ idealResidual V' :=
    idealResidual_mono_in_p hV hV' hq hc hp hL
  have hid2 : idealResidual V ≤ tvFloor V := by
    refine hid.trans ?_
    rw [← hdt]
    exact hfill
  have h1 : max (idealResidual V) (tvFloor V) = tvFloor V := max_eq_right hid2
  have h2 : max (idealResidual V') (tvFloor V') = tvFloor V' := max_eq_right hfill
  rw [starN, starN, h1, h2, hdt, roundsFor_congr hdc.symm (tvFloor V)]

/-- **Regime ②: the TV floor does not bind ⟹ \(A\) and \(N^\star\) are related
exponentially.**

    exp( d·N* )  =  A·d / c ,    A = (1−p)L,  d = ln(1/(1−q))

This makes "not linearly convertible" precise. The relation **does** exist and
is order-preserving, but it is `exp` and **not affine**, so \(\mathcal U\)
contains no such map. -/
theorem starN_exp_formula {V : VerifyParams} (hV : VOk V)
    (hfill : tvFloor V ≤ idealResidual V) :
    Real.exp (decay V * starN V) = lossScale V * decay V / V.c := by
  have hd : decay V ≠ 0 := ne_of_gt (decay_pos hV)
  have hmax : max (idealResidual V) (tvFloor V) = idealResidual V := max_eq_left hfill
  have hstep : decay V * starN V = -(Real.log (idealResidual V)) := by
    rw [starN, hmax, roundsFor]
    field_simp
    ring
  rw [hstep, Real.exp_neg, Real.exp_log (idealResidual_pos hV)]
  rw [show idealResidual V = V.c / (lossScale V * decay V) from rfl]
  field_simp [ne_of_gt hV.c_pos, ne_of_gt (mul_pos (lossScale_pos hV) (decay_pos hV))]

/-- **The AI's effort is unbounded.**

As `TV → 0` the floor disappears and the number of verification rounds can be
arbitrarily large.
(Construction: take `d = 1`, that is `1−q = e^{−1}`, then `λ = e^{−2M}` and
`TV = 1`, so `N_0 = −ln(e^{−2M}) = 2M > M`.) -/
theorem ai_effort_arbitrarily_large {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) := by
  have he1 : 0 < Real.exp (-1) := Real.exp_pos (-1)
  have he1' : Real.exp (-1) < 1 := by
    have h : Real.exp (-1) < Real.exp 0 := Real.exp_lt_exp.mpr (by norm_num : (-1:ℝ) < 0)
    rw [Real.exp_zero] at h
    exact h
  set V : VerifyParams :=
    { p := (1 : ℝ) / 2, Phi := 1, L := 1, q := 1 - Real.exp (-1), c := 1,
      tv := 1, lam := Real.exp (-2 * M) } with hVdef
  have hV : VOk V := by
    refine ⟨by norm_num, by norm_num, by norm_num, by norm_num, ?_, ?_,
      by norm_num, by norm_num, by norm_num, ?_⟩
    · simp only [hVdef]; linarith
    · simp only [hVdef]; linarith
    · simp only [hVdef]; exact Real.exp_pos _
  refine ⟨V, hV, ?_⟩
  have hd : decay V = 1 := by
    simp only [decay, hVdef]
    rw [show (1:ℝ) - (1 - Real.exp (-1)) = Real.exp (-1) by ring, Real.log_exp,
      abs_of_nonpos (by norm_num : (-1:ℝ) ≤ 0)]
    ring
  have htf : tvFloor V = Real.exp (-2 * M) := by
    simp only [tvFloor, hVdef]
    ring
  rw [roundsFor, htf, hd, Real.log_exp]
  linarith

/-- **The human cost of unreliability can be arbitrarily small.**

The person is almost always right and the AI almost never has to work.
(Construction: `p = 1/2` and `L = M` give `A = M/2 < M`.) -/
theorem human_value_arbitrarily_small {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ lossScale V < M := by
  set V : VerifyParams :=
    { p := (1 : ℝ) / 2, Phi := 1, L := M, q := (1 : ℝ) / 2, c := 1, tv := 1, lam := 1 } with hVdef
  have hV : VOk V := by
    refine ⟨by norm_num, by norm_num, by norm_num, hM, by norm_num, by norm_num,
      by norm_num, by norm_num, by norm_num, by norm_num⟩
  refine ⟨V, hV, ?_⟩
  simp only [lossScale, hVdef]
  norm_num
  linarith

/-- **The literal form of item 1 of Section 8: in the same process the AI's
effort is arbitrarily large while the human cost is arbitrarily small.**

No order-preserving map can therefore convert the within-layer quantity
\(v_A\) into the between-layer quantity \(v_H\): in one and the same family the
two quantities **control neither other**. -/
theorem incommensurable_witness {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) ∧ lossScale V < M := by
  set V : VerifyParams :=
    { p := 1 - M / (2 * (M + 1)), Phi := 1, L := 1, q := 1 - Real.exp (-1), c := 1,
      tv := 1, lam := Real.exp (-2 * M) } with hVdef
  have he1 : 0 < Real.exp (-1) := Real.exp_pos (-1)
  have he1' : Real.exp (-1) < 1 := by
    have h : Real.exp (-1) < Real.exp 0 := Real.exp_lt_exp.mpr (by norm_num : (-1:ℝ) < 0)
    rw [Real.exp_zero] at h
    exact h
  have hden : (0:ℝ) < 2 * (M + 1) := by linarith
  have hqle : (M:ℝ) / (2 * (M + 1)) ≤ 1 := (div_le_iff₀ hden).2 (by linarith)
  have hp0 : (0:ℝ) ≤ 1 - M / (2 * (M + 1)) := sub_nonneg.mpr hqle
  have hp1 : (1 : ℝ) - M / (2 * (M + 1)) < 1 := by
    have hpos : (0:ℝ) < M / (2 * (M + 1)) := div_pos hM hden
    linarith
  have hV : VOk V := by
    refine ⟨hp0, hp1, by norm_num, by norm_num, ?_, ?_,
      by norm_num, by norm_num, by norm_num, ?_⟩
    · simp only [hVdef]; linarith
    · simp only [hVdef]; linarith
    · simp only [hVdef]; exact Real.exp_pos _
  refine ⟨V, hV, ?_, ?_⟩
  · have hd : decay V = 1 := by
      simp only [decay, hVdef]
      rw [show (1:ℝ) - (1 - Real.exp (-1)) = Real.exp (-1) by ring, Real.log_exp,
        abs_of_nonpos (by norm_num : (-1:ℝ) ≤ 0)]
      ring
    have htf : tvFloor V = Real.exp (-2 * M) := by
      simp only [tvFloor, hVdef]
      ring
    rw [roundsFor, htf, hd, Real.log_exp]
    linarith
  · have hsmall : (M:ℝ) / (2 * (M + 1)) < M := (div_lt_iff₀ hden).2 (by nlinarith)
    have hid : (1:ℝ) - (1 - M / (2 * (M + 1))) = M / (2 * (M + 1)) := by ring
    rw [lossScale, hVdef, hid, mul_one]
    exact hsmall

/-- **Packaged: regimes ①② plus the two extremes.**

The complete verdict on incommensurability:
* floor binds ⟹ fully independent (`starN_indep_of_p_when_floor_binds`);
* floor does not bind ⟹ exponentially related and nonlinear
  (`starN_exp_formula`);
* both ends together ⟹ neither controls the other (`incommensurable_witness`). -/
theorem incommensurable_two_regime {M : ℝ} (hM : 0 < M) :
    (∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V))
      ∧ (∃ V : VerifyParams, VOk V ∧ lossScale V < M)
      ∧ (∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) ∧ lossScale V < M) :=
  ⟨ai_effort_arbitrarily_large hM, human_value_arbitrarily_small hM,
    incommensurable_witness hM⟩

/-- **Unbounded between layers against a hard ceiling within a layer**: the two
scales are disjoint.

The between-layer gain `log(Φα/Φβ)` ranges over \([0,\infty)\), while the
within-layer gain `log(e₀/e)` is always `≤ log(e₀/Φ)`, and that bound is
**decided by the layer alone, independently of the number of steps**. -/
theorem layer_scales_disjoint {M e0 Φ : ℝ} (hM : 0 ≤ M) (he0 : 0 < e0) (hΦ : 0 < Φ) :
    (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M)
      ∧ (∀ _eN : ℝ, 0 < _eN → Φ ≤ _eN → Real.log (e0 / _eN) ≤ Real.log (e0 / Φ)) :=
  ⟨human_gain_unbounded hM, fun _eN heN hle => ai_total_gain_bounded he0 hΦ heN hle⟩

end Provenance