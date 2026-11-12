/-
# Bridge: the support floor connects the two vocabularies

`Provenance.Contamination` and `Provenance.Tagged` were deliberately left
unconnected: one works over distributions on a finite observation space, the
other over sets of floor values, and the text listed the missing map between
them as an open seam. This file builds the map and proves it preserves the one
quantity both sides call the floor.

The map in the corpus-to-distribution direction is the **empirical
distribution**: a finite set of observations maps to the uniform distribution
on it (`empirical`). The quantity the map must preserve is the **support
floor**: the lowest floor any observation with positive mass reaches
(`supportFloor`).

The bridge itself is two theorems.

* `supportFloor_empirical` / `tagged_floor_eq_supportFloor`: the empirical
  distribution of a corpus certifies, as its support floor, exactly the floor
  the corpus certifies under `Tagged.floorOf` — for every floor assignment and
  any provenance tags.
* `supportFloor_mix` / `mix_empirical_eq_union_floor`: mixing two empirical
  distributions with a nondegenerate weight (`Contamination`'s operation) has
  the union of the two supports as its support, so the support floor of the
  mixture is the minimum of the two floors — which is precisely the floor of
  the union of the two corpora (`Tagged`'s operation, through
  `Finset.min'_union`).

So the two modules now compute in one vocabulary: contamination-as-mixing and
contamination-as-union are the same operation seen from two sides, and the
quantity they both preserve is the floor.

## What the bridge does not say

The preserved quantity is the **floor**. `Contamination`'s other result — that
mixing scales the *identifiability signal* by exactly `π`
(`totalVariation_mix`) — is about the TV distance between distributions, not
about floors, and is not implied by anything here: two mixtures can certify
the same support floor and still differ in TV. Provenance detectability and
floor certification remain different measurements; they now merely share a
carrier.
-/

import Mathlib.Tactic
import Provenance.Tagged
import Provenance.Contamination

open Finset
open scoped BigOperators

namespace Provenance
namespace Bridge

variable {n : ℕ}

/-! ## The support floor -/

/-- The support of a distribution: the observations with positive mass. -/
noncomputable def support (p : PMF n) : Finset (Fin n) :=
  Finset.univ.filter fun i => 0 < p.val i

theorem mem_support {p : PMF n} {i : Fin n} :
    i ∈ support p ↔ 0 < p.val i := by
  simp [support]

/-- The floor a distribution certifies over a floor assignment `f`: the lowest
floor on its support. This is the distributional shadow of `Tagged.floorOf`. -/
noncomputable def supportFloor (p : PMF n) (hs : (support p).Nonempty)
    (f : Fin n → ℝ) : ℝ :=
  ((support p).image f).min' (hs.image f)

/-- Congruence of `min'` across equal sets: the two `Nonempty` proofs never
matter, by proof irrelevance. -/
theorem min'_eq_of_finset_eq {s t : Finset ℝ} {hs : s.Nonempty} {ht : t.Nonempty}
    (h : s = t) : s.min' hs = t.min' ht := by
  subst h
  rfl

/-- `min'` of a union, with arbitrary nonemptiness proofs. -/
theorem min'_union' {s t : Finset ℝ} (hs : s.Nonempty) (ht : t.Nonempty)
    (hst : (s ∪ t).Nonempty) : (s ∪ t).min' hst = min (s.min' hs) (t.min' ht) := by
  have heq : (s ∪ t).min' hst = (s ∪ t).min' (hs.mono Finset.subset_union_left) := rfl
  rw [heq]
  exact Finset.min'_union hs ht

/-! ## The empirical distribution of a corpus -/

/-- The empirical distribution of a nonempty set of observations: uniform on
the set. -/
noncomputable def empirical (D : Finset (Fin n)) (hD : D.Nonempty) : PMF n where
  val := fun i => if i ∈ D then (D.card : ℝ)⁻¹ else 0
  nonneg := by
    intro i
    show 0 ≤ (if i ∈ D then (D.card : ℝ)⁻¹ else 0)
    by_cases hi : i ∈ D
    · rw [if_pos hi]
      exact inv_nonneg.mpr (Nat.cast_nonneg _)
    · rw [if_neg hi]
  sum_one := by
    have hcard : (D.card : ℝ) ≠ 0 := by
      have hc : 0 < D.card := Finset.card_pos.mpr hD
      exact_mod_cast ne_of_gt hc
    show (∑ i : Fin n, (if i ∈ D then (D.card : ℝ)⁻¹ else 0)) = 1
    rw [← Finset.sum_filter, Finset.filter_mem_eq_inter, Finset.inter_comm,
      Finset.inter_univ, Finset.sum_const, nsmul_eq_mul, mul_inv_cancel₀ hcard]

/-- The support of the empirical distribution is the corpus itself. -/
theorem support_empirical (D : Finset (Fin n)) (hD : D.Nonempty) :
    support (empirical D hD) = D := by
  have hpos : (0 : ℝ) < (D.card : ℝ)⁻¹ :=
    inv_pos.mpr (Nat.cast_pos.mpr (Finset.card_pos.mpr hD))
  ext i
  simp only [support, Finset.mem_filter, Finset.mem_univ, true_and]
  show 0 < (if i ∈ D then (D.card : ℝ)⁻¹ else 0) ↔ i ∈ D
  by_cases hi : i ∈ D
  · rw [if_pos hi]
    exact ⟨fun _ => hi, fun _ => hpos⟩
  · rw [if_neg hi]
    exact ⟨fun h => absurd h (lt_irrefl 0), fun h => absurd h hi⟩

/-- **The map preserves the floor.** The support floor of the empirical
distribution is the corpus floor: the lowest floor any member reaches. -/
theorem supportFloor_empirical (D : Finset (Fin n)) (hD : D.Nonempty)
    (hs : (support (empirical D hD)).Nonempty) (f : Fin n → ℝ) :
    supportFloor (empirical D hD) hs f = (D.image f).min' (hD.image f) :=
  min'_eq_of_finset_eq (congrArg (Finset.image f) (support_empirical D hD))

/-- Erasing tags from a tagged corpus built over observations gives the image
of the floor assignment. -/
theorem erase_image_eq (D : Finset (Fin n)) (f : Fin n → ℝ)
    (src : Fin n → Tagged.Source) :
    Tagged.erase (D.image fun i => (⟨f i, src i⟩ : Tagged.Item)) = D.image f := by
  ext b
  constructor
  · intro hb
    rcases Finset.mem_image.mp hb with ⟨i, hiD, hbi⟩
    rcases Finset.mem_image.mp hiD with ⟨j, hjD, rfl⟩
    exact Finset.mem_image.mpr ⟨j, hjD, hbi⟩
  · intro hb
    rcases Finset.mem_image.mp hb with ⟨j, hjD, hjf⟩
    subst hjf
    show f j ∈ (D.image fun i => (⟨f i, src i⟩ : Tagged.Item)).image Tagged.Item.floor
    exact Finset.mem_image.mpr
      ⟨(⟨f j, src j⟩ : Tagged.Item), Finset.mem_image.mpr ⟨j, hjD, rfl⟩, rfl⟩

/-- **The tagged and distributional floors agree.** For any floor assignment
and any provenance tags, `Tagged.floorOf` on the tagged corpus equals the
support floor of its empirical distribution. -/
theorem tagged_floor_eq_supportFloor (D : Finset (Fin n)) (hD : D.Nonempty)
    (f : Fin n → ℝ) (src : Fin n → Tagged.Source)
    (hs : (support (empirical D hD)).Nonempty) :
    Tagged.floorOf (D.image fun i => (⟨f i, src i⟩ : Tagged.Item)) (hD.image _)
      = supportFloor (empirical D hD) hs f := by
  rw [supportFloor_empirical D hD hs f]
  exact min'_eq_of_finset_eq (erase_image_eq D f src)

/-! ## Mixtures and unions -/

/-- The support of a nondegenerate mixture is the union of the supports:
mixing keeps every observation either side carries. -/
theorem support_mix (p q : PMF n) {π : ℝ} (h : MixWeight π) (h0 : 0 < π)
    (h1 : π < 1) :
    support (mix p q π h) = support p ∪ support q := by
  ext i
  simp only [support, Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_union]
  show 0 < (1 - π) * p.val i + π * q.val i ↔ (0 < p.val i ∨ 0 < q.val i)
  have hp0 : 0 ≤ p.val i := p.nonneg i
  have hq0 : 0 ≤ q.val i := q.nonneg i
  have hw0 : (0 : ℝ) < 1 - π := by linarith [h.2]
  constructor
  · intro hm
    by_contra hcon
    push_neg at hcon
    obtain ⟨hpz, hqz⟩ := hcon
    rw [le_antisymm hpz hp0, le_antisymm hqz hq0] at hm
    simp at hm
  · rintro (hp | hq)
    · exact add_pos_of_pos_of_nonneg (mul_pos hw0 hp) (mul_nonneg (le_of_lt h0) hq0)
    · exact add_pos_of_nonneg_of_pos (mul_nonneg (le_of_lt hw0) hp0) (mul_pos h0 hq)

/-- **Mixing computes the minimum of the floors.** The support floor of a
nondegenerate mixture is the minimum of the two support floors — the
distributional form of the corpus-union law `Finset.min'_union`. -/
theorem supportFloor_mix (p q : PMF n) {π : ℝ} (h : MixWeight π) (h0 : 0 < π)
    (h1 : π < 1)
    (hp : (support p).Nonempty) (hq : (support q).Nonempty)
    (hm : (support (mix p q π h)).Nonempty) (f : Fin n → ℝ) :
    supportFloor (mix p q π h) hm f
      = min (supportFloor p hp f) (supportFloor q hq f) := by
  have hset : (support (mix p q π h)).image f
      = (support p).image f ∪ (support q).image f := by
    rw [support_mix p q h h0 h1, Finset.image_union]
  unfold supportFloor
  refine le_antisymm ?_ ?_
  · refine le_min ?_ ?_
    · apply Finset.min'_le
      rw [hset]
      exact Finset.mem_union_left _ (Finset.min'_mem _ (hp.image f))
    · apply Finset.min'_le
      rw [hset]
      exact Finset.mem_union_right _ (Finset.min'_mem _ (hq.image f))
  · have hmem : ((support (mix p q π h)).image f).min' (hm.image f)
        ∈ (support p).image f ∪ (support q).image f := by
      rw [← hset]
      exact Finset.min'_mem _ (hm.image f)
    rcases Finset.mem_union.mp hmem with hb | hb
    · exact min_le_of_left_le (Finset.min'_le _ _ hb)
    · exact min_le_of_right_le (Finset.min'_le _ _ hb)

/-- **The two vocabularies agree.** Mixing the empirical distributions of two
corpora (the `Contamination` operation, nondegenerate weight) and reading the
support floor gives exactly the floor of the union of the two corpora (the
`Tagged`/`Corpus` operation), for every floor assignment. -/
theorem mix_empirical_eq_union_floor (D₁ D₂ : Finset (Fin n))
    (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty) {π : ℝ} (h : MixWeight π)
    (h0 : 0 < π) (h1 : π < 1) (f : Fin n → ℝ)
    (hm : (support (mix (empirical D₁ h₁) (empirical D₂ h₂) π h)).Nonempty) :
    supportFloor (mix (empirical D₁ h₁) (empirical D₂ h₂) π h) hm f
      = ((D₁ ∪ D₂).image f).min' ((h₁.mono Finset.subset_union_left).image f) := by
  have hs₁ : (support (empirical D₁ h₁)).Nonempty := by
    rw [support_empirical]
    exact h₁
  have hs₂ : (support (empirical D₂ h₂)).Nonempty := by
    rw [support_empirical]
    exact h₂
  have hu : (D₁.image f ∪ D₂.image f).Nonempty := (h₁.image f).mono Finset.subset_union_left
  have hfin : ((D₁ ∪ D₂).image f).min' ((h₁.mono Finset.subset_union_left).image f)
      = min ((D₁.image f).min' (h₁.image f)) ((D₂.image f).min' (h₂.image f)) :=
    calc ((D₁ ∪ D₂).image f).min' ((h₁.mono Finset.subset_union_left).image f)
        = (D₁.image f ∪ D₂.image f).min' hu :=
          min'_eq_of_finset_eq (Finset.image_union D₁ D₂)
      _ = min ((D₁.image f).min' (h₁.image f)) ((D₂.image f).min' (h₂.image f)) :=
          min'_union' (h₁.image f) (h₂.image f) hu
  rw [supportFloor_mix _ _ h h0 h1 hs₁ hs₂ hm f,
    supportFloor_empirical D₁ h₁ hs₁ f, supportFloor_empirical D₂ h₂ hs₂ f]
  exact hfin.symm

end Bridge
end Provenance
