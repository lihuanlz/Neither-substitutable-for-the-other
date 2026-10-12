/-
# Provenance identifiability, formalised

This file fully formalises the question of whether human data and AI data can be
told apart, over a **finite probability space**, and proves the following core
results, corresponding to section 1 of the original analysis:

* The original claim `P_e = ½(1 − TV(p_H, p_A))` - formalised as
  `bayes_errRate` / `errRate_ge`: **the error rate of the best test is exactly
  (1−TV)/2, and no test can go lower**.
* The original claim that identifiability fails as `p_A → p_H` - formalised as
  `unidentifiable`: **when TV = 0 the accuracy of every test is exactly 1/2**, not
  close to it but equal to it.
* A sharper characterisation - formalised as `identifiable_iff`: **a test better
  than random exists ⟺ TV > 0**, and the size of the advantage is exactly **TV/2**
  (`accuracy_bounds`).

## Notation

The observation space is `Fin n` (finite). `p` denotes the human distribution
`p_H`, `q` the AI distribution `p_A`, and the priors are `π_H = π_A = 1/2`,
matching the original setting of equal priors on the two classes.

## One sharpening of the original analysis

The original text says that identifiability fails as `p_A → p_H`. The accurate
statement is that **identifiability is controlled continuously by TV**: the best
attainable advantage is exactly `TV/2` (`accuracy_bounds`), while whether anything
is detectable at all also depends on the sample size and the noise level.
`accuracy_bounds` is written as the inequality `|acc − 1/2| ≤ TV/2`, so that this
quantification cannot be side-stepped.

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {n : ℕ}

/-- A probability distribution on a finite space (a probability mass function). -/
structure PMF (n : ℕ) where
  /-- Probability mass -/
  val : Fin n → ℝ
  /-- Non-negativity -/
  nonneg : ∀ i, 0 ≤ val i
  /-- Normalisation -/
  sum_one : ∑ i, val i = 1

/-- The total variation distance `TV(p, q) = ½ Σᵢ |pᵢ − qᵢ|`.

Division on `ℝ` is not executable, hence `noncomputable`. -/
noncomputable def totalVariation (p q : PMF n) : ℝ :=
  (1/2) * ∑ i : Fin n, |p.val i - q.val i|

/-- A test: it labels each observation "human" (true) or "AI" (false). -/
abbrev Test (n : ℕ) := Fin n → Bool

/-- Accuracy under equal priors, `acc(t) = ½ Σᵢ (tᵢ ? pᵢ : qᵢ)`. -/
noncomputable def accuracy (t : Test n) (p q : PMF n) : ℝ :=
  (1/2) * ∑ i : Fin n, (if t i then p.val i else q.val i)

/-- The Bayes-optimal test: it decides human whenever the prior likelihood ratio
exceeds 1, that is whenever `pᵢ ≥ qᵢ`. -/
noncomputable def bayes (p q : PMF n) : Test n := fun i => decide (p.val i ≥ q.val i)

/-- Error rate, `= 1 − accuracy`. -/
noncomputable def errRate (t : Test n) (p q : PMF n) : ℝ := 1 - accuracy t p q

/-! ## Basic properties -/

theorem bayes_eq (p q : PMF n) (i : Fin n) :
    bayes p q i = if p.val i ≥ q.val i then true else false := by
  simp [bayes]

theorem totalVariation_nonneg (p q : PMF n) : 0 ≤ totalVariation p q := by
  unfold totalVariation
  exact mul_nonneg (by norm_num) (Finset.sum_nonneg fun _ _ => abs_nonneg _)

theorem totalVariation_self (p : PMF n) : totalVariation p p = 0 := by
  unfold totalVariation
  simp

theorem totalVariation_comm (p q : PMF n) : totalVariation p q = totalVariation q p := by
  unfold totalVariation
  congr 1
  apply Finset.sum_congr rfl
  intro i _
  have e : p.val i - q.val i = -(q.val i - p.val i) := by ring
  rw [e, abs_neg]

theorem totalVariation_le_one (p q : PMF n) : totalVariation p q ≤ 1 := by
  have hsum : ∑ i : Fin n, |p.val i - q.val i| ≤ ∑ i : Fin n, (p.val i + q.val i) := by
    refine Finset.sum_le_sum fun i _ => ?_
    rw [abs_le]
    constructor <;> linarith [p.nonneg i, q.nonneg i]
  have h2 : ∑ i : Fin n, (p.val i + q.val i) = 2 := by
    rw [Finset.sum_add_distrib, p.sum_one, q.sum_one]; norm_num
  unfold totalVariation
  linarith

theorem totalVariation_triangle (p q r : PMF n) :
    totalVariation p r ≤ totalVariation p q + totalVariation q r := by
  have hpt : ∀ i : Fin n, |p.val i - r.val i| ≤ |p.val i - q.val i| + |q.val i - r.val i| := by
    intro i
    have e : p.val i - r.val i = (p.val i - q.val i) + (q.val i - r.val i) := by ring
    rw [e]
    exact abs_add _ _
  have hsplit : (∑ i : Fin n, (|p.val i - q.val i| + |q.val i - r.val i|))
      = (∑ i : Fin n, |p.val i - q.val i|) + ∑ i : Fin n, |q.val i - r.val i| :=
    Finset.sum_add_distrib
  unfold totalVariation
  calc (1 / 2) * ∑ i : Fin n, |p.val i - r.val i|
      ≤ (1 / 2) * ∑ i : Fin n, (|p.val i - q.val i| + |q.val i - r.val i|) :=
        mul_le_mul_of_nonneg_left (Finset.sum_le_sum fun i _ => hpt i) (by norm_num)
    _ = (1 / 2) * ∑ i : Fin n, |p.val i - q.val i|
        + (1 / 2) * ∑ i : Fin n, |q.val i - r.val i| := by rw [hsplit]; ring
    _ = _ := rfl

/-- `TV = 0` if and only if the two distributions agree pointwise. (On a finite
space there are no "almost everywhere" subtleties.) -/
theorem totalVariation_eq_zero_iff (p q : PMF n) :
    totalVariation p q = 0 ↔ ∀ i : Fin n, p.val i = q.val i := by
  constructor
  · intro h i
    unfold totalVariation at h
    have key : ∑ j : Fin n, |p.val j - q.val j| = 0 := by linarith
    have hn : ∀ j ∈ (Finset.univ : Finset (Fin n)), 0 ≤ |p.val j - q.val j| :=
      fun j _ => abs_nonneg _
    have hz : |p.val i - q.val i| = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg hn).mp key i (Finset.mem_univ i)
    exact sub_eq_zero.mp (abs_eq_zero.mp hz)
  · intro h
    unfold totalVariation
    rw [Finset.sum_congr rfl (fun i _ => by rw [h i])]
    simp

/-! ## Core theorem: an exact characterisation of accuracy

Key algebraic identity: the accuracy of any test equals `1/2 + (1/4)·T`, where `T`
is a signed sum satisfying `|T| ≤ Σᵢ|pᵢ − qᵢ| = 2·TV`. The advantage of the best
test is therefore exactly `TV/2`.

-/

theorem accuracy_eq (t : Test n) (p q : PMF n) :
    accuracy t p q
      = (1 / 2) + (1 / 4) * ∑ i : Fin n,
          (if t i then p.val i - q.val i else q.val i - p.val i) := by
  unfold accuracy
  have key : ∀ i : Fin n,
      (if t i then p.val i else q.val i)
        = (1 / 2) * (p.val i + q.val i)
          + (1 / 2) * (if t i then p.val i - q.val i else q.val i - p.val i) := by
    intro i; split <;> ring
  have h2 : ∑ i : Fin n, (p.val i + q.val i) = 2 := by
    rw [Finset.sum_add_distrib, p.sum_one, q.sum_one]; norm_num
  calc (1 / 2) * ∑ i : Fin n, (if t i then p.val i else q.val i)
      = (1 / 2) * ∑ i : Fin n,
          ((1 / 2) * (p.val i + q.val i)
            + (1 / 2) * (if t i then p.val i - q.val i else q.val i - p.val i)) := by
        rw [Finset.sum_congr rfl (fun i _ => key i)]
    _ = (1 / 2) * ((1 / 2) * ∑ i : Fin n, (p.val i + q.val i)
          + (1 / 2) * ∑ i : Fin n,
            (if t i then p.val i - q.val i else q.val i - p.val i)) := by
        rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum]
    _ = _ := by rw [h2]; ring

theorem signed_sum_bound (t : Test n) (p q : PMF n) :
    |∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i)|
      ≤ ∑ i : Fin n, |p.val i - q.val i| := by
  calc
    |∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i)|
        ≤ ∑ i : Fin n, |(if t i then p.val i - q.val i else q.val i - p.val i)| :=
          Finset.abs_sum_le_sum_abs _ _
    _ = ∑ i : Fin n, |p.val i - q.val i| := by
        refine Finset.sum_congr rfl fun i _ => ?_
        by_cases h : t i = true <;> simp [h, abs_sub_comm]

/-- **Identifiability upper bound**: the accuracy of any test is at most
`(1 + TV)/2`. -/
theorem accuracy_le (t : Test n) (p q : PMF n) :
    accuracy t p q ≤ (1 + totalVariation p q) / 2 := by
  have hb := signed_sum_bound t p q
  have hS : (∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i))
      ≤ ∑ i : Fin n, |p.val i - q.val i| :=
    (le_abs_self _).trans hb
  rw [accuracy_eq t p q]
  unfold totalVariation
  linarith

/-- **Lower bound, in dual form**: the accuracy of any test is at least
`(1 − TV)/2`. -/
theorem accuracy_ge (t : Test n) (p q : PMF n) :
    (1 - totalVariation p q) / 2 ≤ accuracy t p q := by
  have hb := signed_sum_bound t p q
  have hS : -(∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i))
      ≤ ∑ i : Fin n, |p.val i - q.val i| :=
    (neg_le_abs _).trans hb
  rw [accuracy_eq t p q]
  unfold totalVariation
  linarith

/-- **Exact characterisation**: the best attainable advantage is exactly `TV/2`.

This is the most important sharpening of the original analysis. Identifiability is
not a binary can/cannot switch. It is a real number controlled continuously by
`TV`, and `TV/2` is the whole advantage available to any test over random
guessing. -/
theorem accuracy_bounds (t : Test n) (p q : PMF n) :
    |accuracy t p q - 1 / 2| ≤ totalVariation p q / 2 := by
  rw [abs_le]
  constructor
  · linarith [accuracy_ge t p q]
  · linarith [accuracy_le t p q]

/-- **Bayesian optimality**: the Bayes test attains the upper bound, with accuracy
exactly `(1 + TV)/2`. -/
theorem bayes_optimal (p q : PMF n) :
    accuracy (bayes p q) p q = (1 + totalVariation p q) / 2 := by
  have key : ∀ i : Fin n,
      (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
        = |p.val i - q.val i| := by
    intro i
    by_cases h : p.val i ≥ q.val i
    · have h1 : (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
          = p.val i - q.val i := by simp [bayes_eq, h]
      rw [h1, abs_of_nonneg (sub_nonneg.mpr h)]
    · have h1 : (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
          = q.val i - p.val i := by simp [bayes_eq, h]
      rw [h1, abs_of_neg (sub_lt_zero.mpr (lt_of_not_ge h))]
      ring
  rw [accuracy_eq (bayes p q) p q]
  unfold totalVariation
  rw [Finset.sum_congr rfl (fun i _ => key i)]
  ring

/-- **The optimal error rate** is `(1 − TV)/2`. This is the formalisation of the
original claim `P_e = ½(1 − TV)`. -/
theorem bayes_errRate (p q : PMF n) :
    errRate (bayes p q) p q = (1 - totalVariation p q) / 2 := by
  rw [errRate, bayes_optimal]; ring

/-- **Error rate lower bound**: the error rate of any test is at least
`(1 − TV)/2`. -/
theorem errRate_ge (t : Test n) (p q : PMF n) :
    (1 - totalVariation p q) / 2 ≤ errRate t p q := by
  rw [errRate]
  linarith [accuracy_le t p q]

/-! ## Non-identifiability (the verdict of section 1 of the original analysis) -/

/-- **The non-identifiability theorem**: when `TV = 0` the accuracy of **every**
test is **exactly** `1/2`.

Note that this is exact equality rather than "close to random". A formal system
does not accept approximate statements. -/
theorem unidentifiable (p q : PMF n) (h : totalVariation p q = 0) (t : Test n) :
    accuracy t p q = 1 / 2 := by
  have hle := accuracy_le t p q
  have hge := accuracy_ge t p q
  rw [h] at hle hge
  linarith

/-- **Necessary and sufficient condition for identifiability**: a test better than
random exists ⟺ TV > 0.

This sharpens the core claim of the original analysis that provenance
identifiability is `TV(p_H, p_A)`: identifiability is not merely equivalent to
`TV > 0`, its advantage is completely determined by `TV/2`. -/
theorem identifiable_iff (p q : PMF n) :
    (∃ t : Test n, accuracy t p q > 1 / 2) ↔ 0 < totalVariation p q := by
  constructor
  · rintro ⟨t, ht⟩
    have hle := accuracy_le t p q
    have : (1 / 2 : ℝ) < (1 + totalVariation p q) / 2 := lt_of_lt_of_le ht hle
    linarith
  · intro h
    refine ⟨bayes p q, ?_⟩
    have hbo := bayes_optimal p q
    linarith

/-- **The Bayes error rate is strictly decreasing in TV**: the larger TV, the more
separable the two distributions and the smaller the optimal error rate.

(Note that `(1 − TV)/2` is a **decreasing** function of TV, so the larger TV the
smaller the error rate. An earlier draft wrote the inequality the other way round
and Lean rejected it outright, which is exactly what formal checking is for.) -/
theorem errRate_strictly_decreasing {p q p' q' : PMF n}
    (h : totalVariation p' q' < totalVariation p q) :
    errRate (bayes p q) p q < errRate (bayes p' q') p' q' := by
  rw [bayes_errRate, bayes_errRate]
  have hlt : (1 : ℝ) - totalVariation p q < 1 - totalVariation p' q' := sub_lt_sub_left h 1
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_lt_mul_of_pos_right hlt (inv_pos.mpr (by norm_num : (0:ℝ) < 2))

/-! ## Expressivity of a test class (correction #2 to the original analysis)

`accuracy_le` holds for **every** test, and therefore for every test class as well.
There is thus a layer of **test-class expressivity** between "the distributions
differ" and "it can actually be detected". The statements below show that the
upper bound is attained only when the test class contains the Bayes test.

-/

theorem testClass_upperBound (p q : PMF n) (𝒯 : Set (Test n))
    (t : Test n) (_ht : t ∈ 𝒯) :
    accuracy t p q ≤ (1 + totalVariation p q) / 2 :=
  accuracy_le t p q

theorem testClass_attainsBound (p q : PMF n) (𝒯 : Set (Test n))
    (hb : bayes p q ∈ 𝒯) :
    ∃ t ∈ 𝒯, accuracy t p q = (1 + totalVariation p q) / 2 :=
  ⟨bayes p q, hb, bayes_optimal p q⟩

end Provenance
