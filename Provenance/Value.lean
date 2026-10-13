/-
# Separability of influence and value

This file formalises a **directional rebuttal** of the original framework:

> `D_KL( p(θ|D_A,h) ‖ p(θ|D_A) )` measures the **influence** of the datum `h`,
> not its **value**. It therefore cannot be used to price human output.

The rebuttal takes the form of a provable theorem: there exist two human outputs whose
**influence magnitudes on the irreducible floor \(\Phi\) are exactly equal**, yet whose
values have **opposite signs**: one beneficial at \(+M\) bits, the other harmful at
\(-M\) bits, and \(M\) can be arbitrarily large.

Corollary: any measure or ranking of value that **depends on influence magnitude alone**
must identify beneficial output with harmful output. A value function must therefore
carry a sign, or must carry additional utility/direction information.

## Main results

* `influence_value_separable`: equal influence magnitude, opposite value signs, of
  arbitrarily large size.
* `separation_grows_without_bound`: "the influence is small" is no excuse.
* `positive_layer_gain_iff_strict_drop`: **a human output has positive inter-layer
  value ⟺ it strictly lowers the irreducible lower bound**. This is a falsifiable
  criterion for a "good question".
* `zero_gain_iff_equal`: **zero value ⟺ the layer is unchanged**.
* `layered_bits_decomposition`: total log gain = inter-layer + within-layer, unified in
  bits.
* `cover_value_is_a_layer_gain`: the value of covering a new modality **is** a special
  case of the inter-layer gain, not a third term alongside it.
* `influence_and_value_are_distinct`: a packaged restatement.

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement

open scoped BigOperators

namespace Provenance

/-! ## 1. Influence and value are separable (the core rebuttal) -/

/-- **The influence-value separability theorem.**

For any magnitude \(M>0\), there are layer floors \(p,q\) and \(r,s\) such that

* the influence magnitudes are exactly equal: \(\big|\log(p/q)\big| = \big|\log(r/s)\big|\);
* the value signs are opposite: \(\log(p/q) > 0\) while \(\log(r/s) < 0\).

Construction: take \(p=e^M,\ q=1,\ r=1,\ s=e^M\). The first has value \(+M\) bits, the
second has value \(-M\) bits, and both have influence magnitude \(M\).

**This rules out any proposal that proxies value by influence (KL, or any other
information gain).** -/
theorem influence_value_separable {M : ℝ} (hM : 0 < M) :
    ∃ p q r s : ℝ,
      (0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s) ∧
      |Real.log (p / q)| = |Real.log (r / s)| ∧
      (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0) := by
  have hpos : 0 < Real.exp M := Real.exp_pos M
  have h₁ : |Real.log (Real.exp M / 1)| = M := by
    rw [Real.log_div (ne_of_gt hpos) one_ne_zero,
        Real.log_one, Real.log_exp, sub_zero, abs_of_pos hM]
  have h₂ : |Real.log (1 / Real.exp M)| = M := by
    rw [Real.log_div one_ne_zero (ne_of_gt hpos),
        Real.log_one, Real.log_exp, abs_of_neg (by linarith : (0 - M : ℝ) < 0)]
    ring
  refine ⟨Real.exp M, 1, 1, Real.exp M,
    ⟨hpos, (by norm_num : (0:ℝ) < 1), (by norm_num : (0:ℝ) < 1), hpos⟩,
    h₁.trans h₂.symm, ?_, ?_⟩
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero, Real.log_one, Real.log_exp]
    linarith
  · rw [Real.log_div one_ne_zero (ne_of_gt hpos), Real.log_one, Real.log_exp]
    linarith

/-- **The separability cannot be evaded by "the influence is small"**: the magnitude of
the separation \(M\) can be arbitrarily large.

So screening out low-influence items does not help: **large influence is exactly the
dangerous case**. -/
theorem separation_grows_without_bound {M : ℝ} (hM : 0 < M) :
    ∃ p q r s : ℝ,
      0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s ∧
      M ≤ |Real.log (p / q)| ∧ (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0) := by
  have hpos : 0 < Real.exp M := Real.exp_pos M
  refine ⟨Real.exp M, 1, 1, Real.exp M, hpos,
    (by norm_num : (0:ℝ) < 1), (by norm_num : (0:ℝ) < 1), hpos, ?_, ?_, ?_⟩
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero,
        Real.log_one, Real.log_exp, sub_zero, abs_of_pos hM]
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero, Real.log_one, Real.log_exp, sub_zero]
    linarith
  · rw [Real.log_div one_ne_zero (ne_of_gt hpos), Real.log_one, Real.log_exp]
    linarith

/-! ## 2. A falsifiable criterion for a good question -/

/-- **Positive inter-layer value ⟺ strictly lowering the irreducible lower bound.**

This turns "what counts as a good question" from rhetoric into a decidable condition:

    positive human value  ⟺  it makes Φ(β) < Φ(α)  ⟺  it makes "truth" more identifiable

In other words: **a question that does not lower \(\Phi\) has value exactly 0**. -/
theorem positive_layer_gain_iff_strict_drop {Φα Φβ : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) :
    0 < Real.log (Φα / Φβ) ↔ Φβ < Φα := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
  constructor
  · intro h
    have h1 : Real.log Φβ < Real.log Φα := by linarith
    by_contra hcon
    have hge : Φα ≤ Φβ := le_of_not_gt hcon
    have h2 : Real.log Φα ≤ Real.log Φβ := (Real.log_le_log_iff hα hβ).mpr hge
    exact h1.ne (le_antisymm h1.le h2)
  · intro h
    have h1 : Real.log Φβ < Real.log Φα := (Real.log_lt_log_iff hβ hα).mpr h
    linarith

/-- **Zero value ⟺ the layer is unchanged**: no change means no value. -/
theorem zero_gain_iff_equal {Φα Φβ : ℝ} (hα : 0 < Φα) (hβ : 0 < Φβ) :
    Real.log (Φα / Φβ) = 0 ↔ Φα = Φβ := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
  constructor
  · intro h
    have h1 : Real.log Φα = Real.log Φβ := by linarith
    exact (Real.strictMonoOn_log.eq_iff_eq hα hβ).mp h1
  · intro h
    rw [h]
    ring

/-! ## 3. A two-term decomposition unified in bits -/

/-- **Two-term decomposition in units of bits.**

This is the correct form of `V(h) = ΔΦ + Δe^α + ΔCover`: the three terms carry
different dimensions (error / error / weight) and must first be converted to bits; and
"covering a new modality" is itself a special case of a layer change, so it folds into
the first term and is no longer listed separately.

    total log gain  =  inter-layer gain  +  within-layer gain

The two residuals multiply to exactly the original residual, so **nothing is double
counted**.

(The mathematics is `Provenance.layered_decomposition`, restated here as a "bits ledger"
so that it can be cited alongside the influence and value lines.) -/
theorem layered_bits_decomposition {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (heN : 0 < eN) :
    Real.log (Φα / eN) = Real.log (Φα / Φβ) + Real.log (Φβ / eN) :=
  layered_decomposition hα hβ heN

/-- **The value of coverage is the inter-layer gain**, not a third term alongside it.

Take \(\Phi(\alpha)=1\) and \(\Phi(\beta)=e^{-M}\); then covering one new modality is
worth exactly \(M\) bits, which lies inside the range of inter-layer gain and is
unbounded above.

(This removes `ΔCover` from the decomposition and eliminates the double counting.) -/
theorem cover_value_is_a_layer_gain {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M :=
  human_gain_unbounded hM

/-! ## 4. The sign cannot be dropped -/

/-- **Value must carry a sign.**

Taken together, the results of this file give: `human_gain_unbounded` (inter-layer gain
is unbounded) and `ai_total_gain_bounded` (within-layer gain has a hard upper bound)
form a strict asymmetry, and `influence_value_separable` shows that this asymmetry
**cannot** be proxied by influence magnitude.

A complete accounting of contribution must therefore record two quantities:
**influence (magnitude, unsigned)** and **value (bits, signed)**. -/
theorem influence_and_value_are_distinct {M : ℝ} (hM : 0 < M) :
    (∃ p q r s : ℝ, 0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s ∧
      |Real.log (p / q)| = |Real.log (r / s)| ∧
      (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0))
      ∧ (∀ M' : ℝ, 0 ≤ M' → ∃ Φα Φβ : ℝ,
          0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M')
      ∧ (∀ e0 Φ eN : ℝ, 0 < e0 → 0 < Φ → 0 < eN → Φ ≤ eN →
          Real.log (e0 / eN) ≤ Real.log (e0 / Φ)) := by
  refine ⟨?_, ?_, ?_⟩
  · obtain ⟨p, q, r, s, hp, hlt, hpos, hneg⟩ := influence_value_separable hM
    exact ⟨p, q, r, s, hp.1, hp.2.1, hp.2.2.1, hp.2.2.2, hlt, hpos, hneg⟩
  · exact fun _ h => human_gain_unbounded h
  · exact fun e0 Φ eN he0 hΦ heN hle => ai_total_gain_bounded he0 hΦ heN hle

end Provenance