/-
# Coverage and marginal gain: formalising "the human contributes a little and it is worth a lot"

This is the **coverage** part of section 3 of the original analysis:

    F(S) = ∑_z w_z · min(1, ∑_{i∈S} 1[z ∈ C_i])

On a finite space this file rewrites that expression using **indicator functions**,
equivalent to `min(1,·)` when the count is an integer, and proves:

* `coverage_mono` - the coverage function is monotone: the more samples, the more complete the coverage;
* `submodular_union` - **submodularity** (in the equivalent form `F(S∪T) + F(S∩T) ≤ F(S) + F(T)`);
* `diminishing_returns` - **diminishing returns**;
* `single_sample_marginal` - **the core theorem**: if a human sample covers a state `z` that is
  currently uncovered, its **standalone marginal gain is at least `w_z`**.

`single_sample_marginal` is the strict formalisation of "a tiny share of a large
corpus, worth a great deal": **value is decided by the hole it fills, not by the
share of the total.**

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {m n : ℕ}

/-- The set of world states covered by sample `i` (one sample may cover several
states). -/
def cover (C : Fin n → Finset (Fin m)) (S : Finset (Fin n)) : Finset (Fin m) :=
  S.biUnion C

/-- Coverage value: the sum of the weights of all states in `X`. -/
def covVal (w : Fin m → ℝ) (X : Finset (Fin m)) : ℝ :=
  ∑ z : Fin m, w z * (if z ∈ X then 1 else 0)

/-- The coverage function `F(S) = covVal(w, ⋃_{i∈S} C_i)`. -/
def coverage (w : Fin m → ℝ) (C : Fin n → Finset (Fin m)) (S : Finset (Fin n)) : ℝ :=
  covVal w (cover C S)

/-! ## Set identities for indicator functions -/

/-- `covVal(w, A ∪ B) = covVal(w, A) + covVal(w, B \ A)`. -/
theorem covVal_union (w : Fin m → ℝ) (A B : Finset (Fin m)) :
    covVal w (A ∪ B) = covVal w A + covVal w (B \ A) := by
  have key : ∀ z : Fin m,
      w z * (if z ∈ A ∪ B then 1 else 0)
        = w z * (if z ∈ A then 1 else 0)
          + w z * (if z ∈ B \ A then 1 else 0) := by
    intro z
    by_cases hA : z ∈ A <;> by_cases hB : z ∈ B <;>
      simp [hA, hB, Finset.mem_union, Finset.mem_sdiff]
  unfold covVal
  rw [Finset.sum_congr rfl (fun z _ => key z), Finset.sum_add_distrib]

/-- `1[A ∪ B] = 1[A] + 1[B] − 1[A ∩ B]`. -/
theorem covVal_union_inter (w : Fin m → ℝ) (A B : Finset (Fin m)) :
    covVal w (A ∪ B) = covVal w A + covVal w B - covVal w (A ∩ B) := by
  have key : ∀ z : Fin m,
      w z * (if z ∈ A ∪ B then 1 else 0)
        = w z * (if z ∈ A then 1 else 0)
          + w z * (if z ∈ B then 1 else 0)
          - w z * (if z ∈ A ∩ B then 1 else 0) := by
    intro z
    by_cases hA : z ∈ A <;> by_cases hB : z ∈ B <;>
      simp [hA, hB, Finset.mem_union, Finset.mem_inter]
  unfold covVal
  rw [Finset.sum_congr rfl (fun z _ => key z),
      ← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]

/-- `covVal` is non-negative when the weights are non-negative. -/
theorem covVal_nonneg {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z) (X : Finset (Fin m)) :
    0 ≤ covVal w X := by
  unfold covVal
  exact Finset.sum_nonneg fun z _ => by
    by_cases hz : z ∈ X
    · rw [if_pos hz]; exact mul_nonneg (hw z) (by norm_num)
    · rw [if_neg hz]; simp

/-- A lower bound for `covVal`: the weight of any element of `X` is at most its
total value.

This is a direct application of "one term ≤ the sum, the remaining terms being
non-negative". -/
theorem covVal_ge {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z) {X : Finset (Fin m)} (hz : z ∈ X) :
    w z ≤ covVal w X := by
  have hpos : ∀ u ∈ (Finset.univ : Finset (Fin m)),
      0 ≤ w u * (if u ∈ X then 1 else 0) := by
    intro u _
    by_cases hu : u ∈ X
    · rw [if_pos hu]; exact mul_nonneg (hw u) (by norm_num)
    · rw [if_neg hu]; simp
  have h1 : w z * (if z ∈ X then 1 else 0)
      ≤ ∑ u : Fin m, w u * (if u ∈ X then 1 else 0) :=
    Finset.single_le_sum hpos (Finset.mem_univ z)
  unfold covVal
  rw [if_pos hz] at h1
  linarith

/-! ## Basic properties of the cover operator -/

theorem cover_mono {C : Fin n → Finset (Fin m)} {S T : Finset (Fin n)}
    (hST : S ⊆ T) : cover C S ⊆ cover C T := by
  intro z hz
  rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
  exact Finset.mem_biUnion.mpr ⟨i, hST hi, hzi⟩

theorem cover_union (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    cover C (S ∪ T) = cover C S ∪ cover C T := by
  ext z
  constructor
  · intro hz
    rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
    rcases Finset.mem_union.mp hi with hi | hi
    · exact Finset.mem_union_left _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
    · exact Finset.mem_union_right _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
  · intro hz
    rcases Finset.mem_union.mp hz with hz | hz
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_union_left _ hi, hzi⟩
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_union_right _ hi, hzi⟩

/-- **One-sided containment under intersections**:
`cover C (S ∩ T) ⊆ cover C S ∩ cover C T`.

Note that only this direction holds. The converse fails, because the samples
witnessing `z ∈ cover C S` and `z ∈ cover C T` need not be the same one.
`submodular_union` needs only this direction. -/
theorem cover_inter_subset (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    cover C (S ∩ T) ⊆ cover C S ∩ cover C T := by
  intro z hz
  rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
  have hi' := Finset.mem_inter.mp hi
  exact Finset.mem_inter.mpr
    ⟨Finset.mem_biUnion.mpr ⟨i, hi'.1, hzi⟩, Finset.mem_biUnion.mpr ⟨i, hi'.2, hzi⟩⟩

theorem cover_insert (C : Fin n → Finset (Fin m)) (h : Fin n) (S : Finset (Fin n)) :
    cover C (insert h S) = cover C S ∪ C h := by
  ext z
  constructor
  · intro hz
    rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
    rcases Finset.mem_insert.mp hi with rfl | hi
    · exact Finset.mem_union_right _ hzi
    · exact Finset.mem_union_left _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
  · intro hz
    rcases Finset.mem_union.mp hz with hz | hz
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_insert_of_mem hi, hzi⟩
    · exact Finset.mem_biUnion.mpr ⟨h, Finset.mem_insert_self h S, hz⟩

/-! ## Monotonicity and submodularity -/

/-- **Monotonicity**: enlarging the sample set does not decrease the coverage
value (weights non-negative). -/
theorem coverage_mono {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S T : Finset (Fin n)} (hST : S ⊆ T) :
    coverage w C S ≤ coverage w C T := by
  have hcov : cover C S ⊆ cover C T := cover_mono hST
  have key : ∀ z : Fin m,
      w z * (if z ∈ cover C S then 1 else 0)
        ≤ w z * (if z ∈ cover C T then 1 else 0) := by
    intro z
    by_cases hS : z ∈ cover C S
    · rw [if_pos hS, if_pos (hcov hS)]
    · by_cases hT : z ∈ cover C T
      · rw [if_neg hS, if_pos hT]; linarith [hw z]
      · rw [if_neg hS, if_neg hT]
  unfold coverage covVal
  exact Finset.sum_le_sum fun z _ => key z

/-- **Submodularity** (in equivalent form):
`F(S∪T) + F(S∩T) ≤ F(S) + F(T)`.

Proof: first expand `F(S∪T)` with the indicator identity, then use
`cover C (S∩T) ⊆ cover C S ∩ cover C T` together with non-negative weights to
absorb the difference. -/
theorem submodular_union {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    coverage w C (S ∪ T) + coverage w C (S ∩ T)
      ≤ coverage w C S + coverage w C T := by
  have hunion : cover C (S ∪ T) = cover C S ∪ cover C T := cover_union C S T
  have hsub : cover C (S ∩ T) ⊆ cover C S ∩ cover C T := cover_inter_subset C S T
  have hmono : covVal w (cover C (S ∩ T)) ≤ covVal w (cover C S ∩ cover C T) := by
    unfold covVal
    exact Finset.sum_le_sum fun z _ => by
      by_cases h1 : z ∈ cover C (S ∩ T)
      · rw [if_pos h1, if_pos (hsub h1)]
      · by_cases h2 : z ∈ cover C S ∩ cover C T
        · rw [if_neg h1, if_pos h2]; linarith [hw z]
        · rw [if_neg h1, if_neg h2]
  unfold coverage
  rw [hunion, covVal_union_inter]
  linarith

-- `ha` is kept in the statement to record the intended setting (both `a` and
-- `b` are new) even though the proof never needs it; dropping it would
-- strengthen the theorem, which is a claim change rather than a cleanup.
-- The option must sit above the doc comment: a `/-- ... -/` has to be
-- immediately followed by the declaration it documents.
set_option linter.unusedVariables false in
/-- **Diminishing returns**: taking in `a` and then `b` yields no more total gain
than taking them in the reverse order.

This means "the sample obtained first is worth more", so marginal value decreases
as the set grows. It is the theoretical basis for the strategy of "spending a small
budget on high-value human data".

Note that the degenerate case `a = b` must be treated separately, where the
inequality degenerates to monotonicity. -/
theorem diminishing_returns {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {a b : Fin n}
    (ha : a ∉ S) (hb : b ∉ S) :
    coverage w C (insert a (insert b S)) - coverage w C (insert b S)
      ≤ coverage w C (insert a S) - coverage w C S := by
  by_cases hab : a = b
  · rcases hab with rfl
    have hmono : coverage w C S ≤ coverage w C (insert a S) :=
      coverage_mono hw (Finset.subset_insert a S)
    have h1 : (insert a (insert a S) : Finset (Fin n)) = insert a S :=
      Finset.insert_eq_of_mem (Finset.mem_insert_self a S)
    rw [h1]
    linarith
  · have hinter : insert a S ∩ insert b S = S := by
      ext x
      constructor
      · intro hx
        have hx' := Finset.mem_inter.mp hx
        have h1 := Finset.mem_insert.mp hx'.1
        have h2 := Finset.mem_insert.mp hx'.2
        by_cases hxS : x ∈ S
        · exact hxS
        · have h1' : x = a := h1.resolve_right hxS
          have h2' : x = b := h2.resolve_right hxS
          exact absurd (h1'.symm.trans h2') hab
      · intro hx
        exact Finset.mem_inter.mpr
          ⟨Finset.mem_insert_of_mem hx, Finset.mem_insert_of_mem hx⟩
    have h2 : S ∪ insert b S = insert b S := by
      ext x
      constructor
      · intro hx
        rcases Finset.mem_union.mp hx with hx | hx
        · exact Finset.mem_insert_of_mem hx
        · exact hx
      · intro hx
        exact Finset.mem_union_right _ hx
    have hsub := submodular_union hw C (insert a S) (insert b S)
    have hun : insert a S ∪ insert b S = insert a (insert b S) := by
      rw [Finset.insert_union a S (insert b S), h2]
    rw [hun, hinter] at hsub
    linarith

/-! ## Core theorem: the marginal contribution of one sample -/

/-- **The single-sample marginal theorem** (the strict form of "a little goes a
long way").

If sample `h` covers a state `z` not already covered by `S`, then

    w_z  ≤  F(S ∪ {h}) − F(S)

That is: **the value the sample provides on its own is at least the weight of the
hole it fills.** -/
theorem single_sample_marginal {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {h : Fin n} {z : Fin m}
    (hz : z ∉ cover C S) (hzc : z ∈ C h) :
    w z ≤ coverage w C (insert h S) - coverage w C S := by
  have hunion : cover C (insert h S) = cover C S ∪ C h := cover_insert C h S
  rw [coverage, coverage, hunion, covVal_union]
  have hge : w z ≤ covVal w (C h \ cover C S) :=
    covVal_ge hw (Finset.mem_sdiff.mpr ⟨hzc, hz⟩)
  linarith

/-- **Corollary (independence of quantity)**: the lower bound `w_z` on the
single-sample marginal gain does not depend on the sample's share of a large
corpus.

If sample `h` is a very small part of the full sample set but covers an
**uncovered** state of weight `w_z`, its marginal contribution is still bounded
below by `w_z`.

This rules out the claim "value ∝ share of the total" inside Lean. However small
the share, as long as it fills a hole of weight `w_z`, the marginal gain is
`≥ w_z`. -/
theorem marginal_independent_of_share {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {h : Fin n} {z : Fin m}
    (hz : z ∉ cover C S) (hzc : z ∈ C h) :
    w z ≤ coverage w C (insert h S) - coverage w C S :=
  single_sample_marginal hw hz hzc

end Provenance
