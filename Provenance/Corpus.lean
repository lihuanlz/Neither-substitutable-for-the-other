/-
# Corpus as filter: why absorption volume and usable knowledge come apart

This file formalises the corpus-side consequence of the refinement framework.

The intuition being formalised is deflationary. A research corpus grows
monotonically: every preprint, every talk slide, every notebook eventually
becomes training material, so the raw quantity of available knowledge is not
the thing in doubt. What is in doubt is how much of that quantity is usable.

The sharp statement is **dilution invariance**. Only the single best item in a
corpus - the one certifying the lowest floor - determines the attainable bound.
Everything else in the corpus, however numerous, however recent, however
competently written, contributes exactly nothing to that bound. A corpus that
is ninety-nine parts filler and one part signal certifies precisely what the one
part certifies.

Two consequences matter for how the AI-for-science debate is framed.

* `selection_filter_caps_gain`. If every published item is bounded below by `c`,
  then no amount of further publication certifies a floor below `c`. Corpus
  growth is unbounded; the floor it can certify is not. This is the formal
  content of a corpus carrying a selection filter, and it is why "everything
  eventually becomes training material" and "everything eventually becomes
  usable" come apart.
* `uninformative_corpus_gains_nothing`. Absorbing a corpus that fails to lower
  the floor yields gain exactly zero. This is the corpus-side instance of
  `Refinement.no_gain_without_floor_drop`.

## Modelling honesty

Two things are deliberately not formalised here, and the omissions are the
point rather than an oversight.

First, "corpus" is modelled as a set of floor values, one per item. Whether a
given real artefact is articulable at all is not representable at this level,
so the tacit-knowledge filter cannot be stated as a theorem. The results below
concern the floor a corpus *does* certify, conditional on an item existing.

Second, the corpus is a set. Real corpora are streams with recency,
duplication, and re-weighting. Nothing here says the best item is reachable, or
that it is weighted up when found. These are modelling commitments, stated as
such, not results.
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement

namespace Provenance

namespace Corpus

noncomputable section
open Classical

/-
## 1. The floor certified by a corpus
-/

/-- The floor-certifying items of a corpus.

Each element records the residual floor that absorbing that one item would
certify. Items are identified with the floors they reach: two items reaching
the same floor are indistinguishable to this framework, which is the intended
coarsening and the reason corpus *size* can never appear in a result here. -/
abbrev Evidence := Finset ℝ

/-- The floor certified by a corpus: the best, that is, lowest, floor any
single item in it reaches.

The `Nonempty` argument is a proof obligation, not data; by proof irrelevance
`floorOf` does not depend on how it is discharged. -/
def floorOf (D : Evidence) (hD : D.Nonempty) : ℝ := D.min' hD

/-- **The certified floor understates every item.** -/
theorem floorOf_le_of_mem {D : Evidence} (hD : D.Nonempty) {a : ℝ} (ha : a ∈ D) :
    floorOf D hD ≤ a := Finset.min'_le D a ha

/-- **The certified floor is attained.**

Some item in the corpus reaches it. This is what makes the floor a
certification rather than an unachieved infimum, and it is what licenses the
characterisation in `floorOf_eq_iff`. -/
theorem mem_floorOf {D : Evidence} (hD : D.Nonempty) : floorOf D hD ∈ D :=
  Finset.min'_mem D hD

set_option linter.unusedVariables false in
/-- **The floor is characterised by being attained and undercutting nothing.**

A bound `c` is the certified floor exactly when it is reached by some item and
no item in the corpus sits below it. The positivity hypothesis on `c` states
the domain a floor is taken over; it is not an ingredient of the proof. -/
theorem floorOf_eq_iff {D : Evidence} (hD : D.Nonempty) {c : ℝ} (hc : 0 < c) :
    floorOf D hD = c ↔ c ∈ D ∧ ∀ a ∈ D, c ≤ a := by
  constructor
  · intro h
    have h' : D.min' hD = c := by simpa only [floorOf] using h
    refine ⟨h' ▸ Finset.min'_mem D hD, ?_⟩
    intro a ha
    have hle := Finset.min'_le D a ha
    rwa [h'] at hle
  · rintro ⟨hcD, hall⟩
    have hmin : D.min' hD = c :=
      le_antisymm (Finset.min'_le D c hcD) (Finset.le_min' D hD c hall)
    exact hmin

/-
## 2. Dilution invariance
-/

/-- **Adding a corpus can only help through its own best item.**

The certified floor of the union is the better of the two floors. Neither the
size of either corpus nor the number of items in them appears anywhere on the
right-hand side. -/
theorem floorOf_union_le_left {D₁ D₂ : Evidence} (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty)
    (h : floorOf D₁ h₁ ≤ floorOf D₂ h₂) :
    floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left) = floorOf D₁ h₁ := by
  simp only [floorOf, Finset.min'_union h₁ h₂]
  exact min_eq_left h

/-- The symmetric case: when the second corpus is the better one, it alone
determines the floor of the union. -/
theorem floorOf_union_le_right {D₁ D₂ : Evidence} (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty)
    (h : floorOf D₂ h₂ ≤ floorOf D₁ h₁) :
    floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left) = floorOf D₂ h₂ := by
  simp only [floorOf, Finset.min'_union h₁ h₂]
  exact min_eq_right h

/-- **A corpus cannot be beaten by a corpus it does not improve on.**

A strictly weaker second corpus leaves the floor exactly where it was. -/
theorem floorOf_union_eq_of_lt {D₁ D₂ : Evidence} (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty)
    (h : floorOf D₂ h₂ < floorOf D₁ h₁) :
    floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left) = floorOf D₂ h₂ :=
  floorOf_union_le_right h₁ h₂ (le_of_lt h)

/-- **Absorbing any amount of non-improving material changes nothing.**

`D₂` is arbitrary in size, so this covers corpus growth in a single statement:
add `n` items, none of which beats the existing floor, and the floor stays
put. -/
theorem floorOf_union_self_mono {D₁ D₂ : Evidence} (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty)
    (hall : ∀ a ∈ D₂, floorOf D₁ h₁ ≤ a) :
    floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left) = floorOf D₁ h₁ := by
  refine floorOf_union_le_left h₁ h₂ ?_
  exact le_trans (hall (floorOf D₂ h₂) (mem_floorOf h₂)) le_rfl

/-- **Inserting an item that does not beat the floor is exactly free.**

Not "approximately free" and not "nearly free": the certified floor is
unchanged, so every bound derived from it is unchanged too. This is the
single-item form of dilution invariance. -/
theorem floorOf_insert_ge {D : Evidence} {a : ℝ} (hD : D.Nonempty) (ha : floorOf D hD ≤ a) :
    floorOf (insert a D) (Finset.insert_nonempty a D) = floorOf D hD := by
  simp only [floorOf, Finset.min'_insert a D hD]
  exact min_eq_left ha

/-- **Inserting an item that beats the floor takes it over completely.**

The new item dominates and the previous floor is discarded outright. -/
theorem floorOf_insert_lt {D : Evidence} {a : ℝ} (hD : D.Nonempty) (ha : a < floorOf D hD) :
    floorOf (insert a D) (Finset.insert_nonempty a D) = a := by
  simp only [floorOf, Finset.min'_insert a D hD]
  exact min_eq_right ha.le

/-
## 3. Consequences for the attainable bound
-/

/-- **The AI bound, restated over a corpus.**

The corpus's residual floor caps the attainable gain, and the cap inherits the
step-independence of `Refinement.ai_total_gain_bounded`. -/
theorem ai_gain_bounded_by_corpus {e0 : ℝ} {D : Evidence} (he0 : 0 < e0) (hD : D.Nonempty)
    (hf : 0 < floorOf D hD) {eN : ℝ} (heN : 0 < eN) (hle : floorOf D hD ≤ eN) :
    Real.log (e0 / eN) ≤ Real.log (e0 / floorOf D hD) :=
  ai_total_gain_bounded he0 hf heN hle

set_option linter.unusedVariables false in
/-- **The bound is a function of the floor alone.**

Two corpora certifying the same floor are indistinguishable to the framework,
however different their size, composition, recency, or provenance. The
positivity hypotheses state the domain the logarithmic bound is taken on. -/
theorem floor_determines_bound {e0 : ℝ} {D₁ D₂ : Evidence} (he0 : 0 < e0)
    (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty) (hf₁ : 0 < floorOf D₁ h₁) (hf₂ : 0 < floorOf D₂ h₂)
    (h : floorOf D₁ h₁ = floorOf D₂ h₂) :
    Real.log (e0 / floorOf D₁ h₁) = Real.log (e0 / floorOf D₂ h₂) := by
  rw [h]

set_option linter.unusedVariables false in
/-- **Diluted corpus, undiluted bound.**

A corpus that fails to improve on the floor leaves the attainable bound exactly
where it was, no matter how much of it is added. The positivity hypotheses
state the domain the logarithmic bound is taken on. -/
theorem noise_cannot_beat_signal {e0 : ℝ} {D₁ D₂ : Evidence} (he0 : 0 < e0)
    (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty) (hf₁ : 0 < floorOf D₁ h₁) (hf₂ : 0 < floorOf D₂ h₂)
    (hle : floorOf D₂ h₂ ≤ floorOf D₁ h₁) :
    Real.log (e0 / floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left))
      = Real.log (e0 / floorOf D₂ h₂) := by
  rw [floorOf_union_le_right h₁ h₂ hle]

/-- **A corpus that fails to lower the floor pays exactly zero.**

This is `Refinement.no_gain_without_floor_drop` instantiated at the corpus: the
gain from switching corpora is identically zero when the floor is unchanged. -/
theorem uninformative_corpus_gains_nothing {D₁ D₂ : Evidence}
    (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty) (hf₁ : 0 < floorOf D₁ h₁) (hf₂ : 0 < floorOf D₂ h₂)
    (h : floorOf D₁ h₁ = floorOf D₂ h₂) :
    Real.log (floorOf D₁ h₁ / floorOf D₂ h₂) = 0 :=
  no_gain_without_floor_drop hf₁ hf₂ h

/-
## 4. Selection filters bound what a corpus can ever certify
-/

set_option linter.unusedVariables false in
/-- **A corpus bounded below by `c` cannot certify below `c`.**

If every item in the corpus reaches at least `c`, the certified floor is at
least `c`. This is the formal statement of a selection filter: no quantity of
additional material drawn from the same filtered stream moves the floor past
the filter's own threshold.

The positivity hypothesis on `c` is retained even though the conclusion does
not need it, because it is the domain condition a selection floor is stated
on. -/
theorem selection_floor_blocks_better_floor {D : Evidence} {c : ℝ} (hD : D.Nonempty)
    (hc : 0 < c) (hall : ∀ a ∈ D, c ≤ a) : c ≤ floorOf D hD :=
  hall (floorOf D hD) (mem_floorOf hD)

set_option linter.unusedVariables false in
/-- **Corpus size cannot beat the selection floor.**

For every cardinality, a corpus of exactly that size whose items are all
bounded below by `c` still certifies a floor at or above `c`. Read
contrapositively: no corpus, however large, certifies a floor below `c` if none
of its items does.

The cardinality is retained as an explicit premise to make the quantification
readable; the conclusion does not depend on it. -/
theorem corpus_size_cannot_beat_selection_floor {n : ℕ} {c : ℝ} (hc : 0 < c)
    {D : Evidence} (hcard : D.card = n) (hD : D.Nonempty) (hall : ∀ a ∈ D, c ≤ a) :
    c ≤ floorOf D hD :=
  selection_floor_blocks_better_floor hD hc hall

/-- **The selection floor caps the attainable gain uniformly in the residual.**

The bound holds for every achievable residual error, so no amount of additional
filtered material relaxes it. -/
theorem selection_filter_caps_gain {e0 : ℝ} {D : Evidence} {c : ℝ} (he0 : 0 < e0) (hc : 0 < c)
    (hD : D.Nonempty) (hall : ∀ a ∈ D, c ≤ a) {eN : ℝ} (heN : 0 < eN)
    (hle : floorOf D hD ≤ eN) :
    Real.log (e0 / eN) ≤ Real.log (e0 / c) := by
  have hfloor : c ≤ floorOf D hD := selection_floor_blocks_better_floor hD hc hall
  have hpos : 0 < floorOf D hD := lt_of_lt_of_le hc hfloor
  have hlog : Real.log c ≤ Real.log (floorOf D hD) :=
    (Real.log_le_log_iff hc hpos).mpr hfloor
  have hlogE : Real.log c ≤ Real.log eN :=
    hlog.trans ((Real.log_le_log_iff hpos heN).mpr hle)
  rw [Real.log_div (ne_of_gt he0) (ne_of_gt heN),
      Real.log_div (ne_of_gt he0) (ne_of_gt hc)]
  linarith [hlogE]

set_option linter.unusedVariables false in
/-- **Dilution and selection compose.**

When *both* corpora are drawn from the same filtered stream, absorbing the
second cannot move the union below the filter's threshold, whatever the first
corpus certified. The hypothesis on `D₁` is not redundant: without it the first
corpus may already sit below `c` and the conclusion is false. -/
theorem selection_filter_survives_dilution {D₁ D₂ : Evidence} {c : ℝ} (hc : 0 < c)
    (h₁ : D₁.Nonempty) (h₂ : D₂.Nonempty) (hall₁ : ∀ a ∈ D₁, c ≤ a) (hall₂ : ∀ a ∈ D₂, c ≤ a) :
    c ≤ floorOf (D₁ ∪ D₂) (h₁.mono Finset.subset_union_left) := by
  refine selection_floor_blocks_better_floor (h₁.mono Finset.subset_union_left) hc ?_
  intro a ha
  rcases Finset.mem_union.mp ha with h | h
  · exact hall₁ a h
  · exact hall₂ a h

end
end Corpus
end Provenance