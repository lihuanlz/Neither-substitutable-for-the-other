/-
# Provenance-tagged evidence: what a contaminated corpus certifies

`Provenance.Corpus` identifies an item with the floor it reaches. Two items
reaching the same floor are deliberately indistinguishable there, which is what
lets corpus *size* disappear from every result in that file. The coarsening is
correct for the question that file asks, and it is exactly what blocks the
question this file asks: **which side of a corpus a floor came from.**

An item is never just a floor. It is a floor plus a provenance. Once that
provenance is carried, the central result is a negative one, and it is stated as
a theorem rather than an observation:

> **The floor of a corpus does not read provenance.**

A machine-generated item that undercuts the human floor takes the bound over
completely, and a human item reaching the same floor would have done exactly
the same. Nothing in `floorOf` inspects `src`, and no result in this file can
distinguish the two cases, because there is nothing to inspect.

That is the formal content of "contamination of a corpus". It is stronger than
the prose version: not that contaminated items are often harmful, but that
removing the source of an item does not change the certified bound at all.

## What is deliberately not here

`Provenance.Contamination` mixes a human and a machine source in probability
space and shows the identifiability signal attenuates by exactly `π`. That is
contamination of an **evidence channel**, with an external detector still doing
the estimation. This file is about contamination of a **corpus**, where the
floor itself is the estimate and the source label rides along on the item.

No theorem below connects the two. The two files use incompatible carriers,
`PMF n` and `Finset ℝ`, and nothing here bridges them. Such a bridge would need
a map from a tagged corpus to a distribution, which does not exist yet. See the
modelling note below.

## What a provenance label is not

The label says who wrote an item, not whether it is correct. A confident wrong
answer from a machine and a confident wrong answer from a person are tagged
differently and weigh identically, which is `source_irrelevant` seen from the
other side. Nothing here is a claim about truth; it is a claim about how much
the source matters to the bound.

## A note on the proofs

Two results below go through `le_antisymm` and elementwise comparison rather
than by rewriting with `Finset.min'_insert`. Rewriting the set also moves the
`Nonempty` proof that `min'` is applied to, and `rw` cannot abstract through
that dependency. Every `min'` and `min'_le` is applied with explicit arguments
for the same reason: with all underscores the element order is not determined.

-/

import Mathlib.Tactic
import Provenance.Corpus

namespace Provenance
namespace Tagged

noncomputable section
open Classical

/-- Where an item came from. -/
inductive Source where
  /-- Produced by a person. -/
  | human
  /-- Produced by a machine. -/
  | ai
  deriving DecidableEq, Repr

/-- One item of evidence: the floor it would certify, and where it came from. -/
structure Item where
  /-- The residual floor this item reaches. -/
  floor : ℝ
  /-- Its provenance. -/
  src : Source
  deriving DecidableEq

/-- A corpus of provenance-tagged items. -/
abbrev Corpus := Finset Item

/-- **Drop the tags.** A tagged corpus projects onto the ordinary corpus of
floor values that `Provenance.Corpus` works on. This is the map that makes the
two files comparable at all. -/
def erase (D : Corpus) : Corpus.Evidence := D.image Item.floor

/-- The erasure of a nonempty corpus is nonempty. -/
theorem erase_nonempty {D : Corpus} (hD : D.Nonempty) : (erase D).Nonempty :=
  hD.image Item.floor

/-- The floor a tagged corpus certifies: the lowest floor any single item in it
reaches, tags ignored. -/
def floorOf (D : Corpus) (hD : D.Nonempty) : ℝ := (erase D).min' (erase_nonempty hD)

/-- **The floor undercuts every item.** -/
theorem floorOf_le_of_mem {D : Corpus} (hD : D.Nonempty) {i : Item} (hi : i ∈ D) :
    floorOf D hD ≤ i.floor :=
  Finset.min'_le (erase D) i.floor (Finset.mem_image.mpr ⟨i, hi, rfl⟩)

/-- **The floor is attained by an item of the corpus.** -/
theorem floorOf_attained {D : Corpus} (hD : D.Nonempty) :
    ∃ i ∈ D, floorOf D hD = i.floor := by
  have hm : floorOf D hD ∈ erase D := Finset.min'_mem (erase D) (erase_nonempty hD)
  rcases Finset.mem_image.mp hm with ⟨i, hiD, hfl⟩
  exact ⟨i, hiD, hfl.symm⟩

/-- **Erasing the tags recovers the ordinary corpus floor.** The tagged
construction adds no content to `Provenance.Corpus`; it adds a coordinate that
the floor is proved not to read. -/
theorem floorOf_eq_erase {D : Corpus} (hD : D.Nonempty) :
    floorOf D hD = Corpus.floorOf (erase D) (erase_nonempty hD) := rfl

/-- **The tagged selection filter, transposed.** If every item of a tagged
corpus is bounded below by `c`, so is its certified floor. This is the
provenance-carrying shadow of `Corpus.selection_floor_blocks_better_floor`; note
that no positivity hypothesis on `c` is needed here, the conclusion follows from
the attained floor alone. -/
theorem floorOf_ge_of_items {D : Corpus} (hD : D.Nonempty) {c : ℝ}
    (hall : ∀ i ∈ D, c ≤ i.floor) : c ≤ floorOf D hD := by
  obtain ⟨i, hiD, hfl⟩ := floorOf_attained hD
  rw [hfl]
  exact hall i hiD

/-- **Adding one tagged item takes the minimum.** Both the tag and the source
are read here, and neither affects the result. -/
theorem floorOf_insert (H : Corpus) (hH : H.Nonempty) (i : Item) :
    floorOf (insert i H) (Finset.insert_nonempty i H) = min i.floor (floorOf H hH) := by
  have hDst : (erase (insert i H)).Nonempty :=
    erase_nonempty (Finset.insert_nonempty i H)
  by_cases hlt : i.floor < floorOf H hH
  · rw [min_eq_left hlt.le]
    refine le_antisymm
      (floorOf_le_of_mem (Finset.insert_nonempty i H) (Finset.mem_insert_self i H)) ?_
    refine Finset.le_min' (erase (insert i H)) hDst i.floor ?_
    intro b hb
    rcases Finset.mem_image.mp hb with ⟨j, hjD, hjb⟩
    rw [← hjb]
    rcases Finset.mem_insert.mp hjD with hij | hjH
    · subst hij
      exact le_of_eq rfl
    · exact hlt.le.trans (floorOf_le_of_mem hH hjH)
  · rw [min_eq_right (le_of_not_gt hlt)]
    have hminmem : floorOf H hH ∈ erase (insert i H) := by
      have hm : floorOf H hH ∈ erase H :=
        Finset.min'_mem (erase H) (erase_nonempty hH)
      rcases Finset.mem_image.mp hm with ⟨j, hjD, hj⟩
      exact hj ▸ Finset.mem_image.mpr ⟨j, Finset.mem_insert_of_mem hjD, rfl⟩
    refine le_antisymm
      (Finset.min'_le (erase (insert i H)) (floorOf H hH) hminmem) ?_
    refine Finset.le_min' (erase (insert i H)) hDst (floorOf H hH) ?_
    intro b hb
    rcases Finset.mem_image.mp hb with ⟨j, hjD, hjb⟩
    rw [← hjb]
    rcases Finset.mem_insert.mp hjD with hij | hjH
    · subst hij
      exact le_of_not_gt hlt
    · exact floorOf_le_of_mem hH hjH

/-- **Provenance never enters the floor.**

Two items reaching the same floor take over a corpus identically, whatever their
sources. This is the fact that makes "the item came from a machine" irrelevant to
what the corpus certifies. -/
theorem source_irrelevant {H : Corpus} (hH : H.Nonempty) {i j : Item}
    (hj : j.floor = i.floor) :
    floorOf (insert i H) (Finset.insert_nonempty i H)
      = floorOf (insert j H) (Finset.insert_nonempty j H) := by
  rw [floorOf_insert H hH i, floorOf_insert H hH j, hj]

/-- **A machine item that undercuts the human floor takes the bound over
completely.** The rest of the human corpus is discarded outright and its size
appears nowhere in the conclusion. -/
theorem machine_item_takes_over {H : Corpus} {i : Item} (hH : H.Nonempty)
    (hcut : i.floor < floorOf H hH) :
    floorOf (insert i H) (Finset.insert_nonempty i H) = i.floor := by
  rw [floorOf_insert H hH i, min_eq_left hcut.le]

/-- **Dilution does not help.** Once a machine item has undercut the human floor,
the corpus certifies strictly below it. Nothing absorbed since can pull it back
up, because a minimum is only ever lowered by what joins it. -/
theorem contamination_irreversible {H : Corpus} {i : Item} (hH : H.Nonempty)
    (hcut : i.floor < floorOf H hH) :
    floorOf (insert i H) (Finset.insert_nonempty i H) < floorOf H hH := by
  rw [machine_item_takes_over hH hcut]
  exact hcut

/-- **The same floor can be certified by a clean corpus or a contaminated one.**
No quantity computed from the corpus alone separates the two cases, because the
certified number is the same in both. -/
theorem floor_cannot_reveal_provenance (a : ℝ) :
    floorOf {⟨a, .human⟩} (by simp) = floorOf {⟨a, .ai⟩} (by simp) := rfl

/-- **A contaminated item beats a human filter, at any corpus size.** If every
human item is bounded below by `c`, a single machine item below `c` still takes
the certified floor below `c`, and no quantity of human material above `c`
prevents it. This is the corpus reading of contamination tolerance. -/
theorem machine_item_beats_human_filter {H : Corpus} (hH : H.Nonempty) {c a : ℝ}
    (hall : ∀ i ∈ H, c ≤ i.floor) (hcut : a < c) :
    floorOf (insert ⟨a, .ai⟩ H) (Finset.insert_nonempty ⟨a, .ai⟩ H) = a := by
  have hfloor : c ≤ floorOf H hH := floorOf_ge_of_items hH hall
  rw [floorOf_insert H hH _, min_eq_left (hcut.le.trans hfloor)]

end
end Tagged
end Provenance