/-
# The verification floor, derived

The paper's verification-budget model carries a floor: the residual miss rate
cannot be pushed below `T = λ·(1−TV)/2`, a fixed fraction of the Bayes error of
the two hypotheses. In the text that floor is a **modelling assumption**, and
the text says so. This file derives a floor from an explicit observation model
instead of postulating one.

The model is the weakest possible: **one observation, one verifier, a
false-positive budget**. The verifier inspects a single observation drawn from
either the certified (good) distribution `p` or the candidate (bad)
distribution `q`, and rejects a set `S` of observations. With a
false-positive budget of `α`, its miss rate obeys

    miss ≥ 1 − α − TV(p, q)        (floor_from_detection)

which is Le Cam's two-point lemma read as a one-sided (Neyman–Pearson) budget
statement: `mass_sub_le_tv`, applied to the complement, is exactly this
inequality. The floor is therefore a **theorem of the observation model**, not
a postulate.

Two further facts complete the picture.

* `floor_tight`: the verifier that rejects exactly where the bad distribution
  dominates (`posSet q p`) has miss rate **exactly** `1 − FP − TV`. The derived
  floor is the operating line of the optimal verifier, not a loose bound.
* `bayes_fp_add_miss` / `bayes_balanced_miss`: along that operating line,
  `FP + miss = 1 − TV`, so a balanced verifier (`FP = miss`) sits exactly at
  the Bayes error `(1−TV)/2`. The floor anchored at the Bayes error in the
  text is the **balanced single-observation operating point** of this model.

## What this file does not claim

The bound is about verifiers acting on **one** observation. A verifier that
sees several independent draws is a test on the product space, where `TV` is
larger and the floor is lower; nothing here bounds that regime. What the file
does say about repetition is `floor_under_rounds_and`: rounds that all act on
the **same** observation compose into a single test on that observation, and
inherit its floor verbatim. Repetition only escapes the floor when it buys
genuinely new observations, which is precisely the regime change the text
describes as moving to a different observation layer.
-/

import Mathlib.Tactic
import Provenance.HypothesisTest

open Finset
open scoped BigOperators

namespace Provenance
namespace VerifyFloor

variable {n : ℕ}

/-! ## Conventions

* `p` — the certified (good) distribution; `q` — the candidate (bad) one.
* A verifier is identified with its **rejection set** `S`: the observations it
  flags for review.
* False-positive rate: good mass flagged, `mass p S`.
* Miss rate: bad mass accepted, `mass q (univ \ S)`. -/

/-- The false-positive rate of a verifier with rejection set `S`. -/
abbrev fpRate (p : PMF n) (S : Finset (Fin n)) : ℝ := mass p S

/-- The miss rate of a verifier with rejection set `S`: the bad mass it lets
through. -/
abbrev missRate (q : PMF n) (S : Finset (Fin n)) : ℝ := mass q (Finset.univ \ S)

/-- **The verification floor, derived.** Any verifier acting on a single
observation with false-positive rate at most `α` accepts at least the fraction
`1 − α − TV(p, q)` of the bad distribution.

This is the one-sided form of the two-point lemma: `mass_sub_le_tv` with the
distributions swapped bounds the rejected bad mass by `FP + TV`, and the
complement identity turns that into a lower bound on the accepted bad mass. -/
theorem floor_from_detection (p q : PMF n) (S : Finset (Fin n)) {α : ℝ}
    (hfp : fpRate p S ≤ α) :
    1 - α - totalVariation p q ≤ missRate q S := by
  have hswap := mass_sub_le_tv q p S
  rw [totalVariation_comm] at hswap
  have hcompl := mass_add_compl q S
  linarith

/-- **The floor is attained.** Rejecting exactly where the bad distribution
dominates (`posSet q p`, the Neyman–Pearson rejection set) gives a miss rate of
exactly `1 − FP − TV`: the floor is the operating line of the optimal
verifier. -/
theorem floor_tight (p q : PMF n) :
    missRate q (posSet q p) = 1 - fpRate p (posSet q p) - totalVariation p q := by
  have h := mass_posSet_eq_tv q p
  rw [totalVariation_comm] at h
  have hcompl := mass_add_compl q (posSet q p)
  linarith

/-- **The operating line is one-dimensional.** For the Neyman–Pearson rejection
set the two error rates sum to `1 − TV`: lowering the false-positive rate
raises the miss rate one-for-one, and conversely. -/
theorem bayes_fp_add_miss (p q : PMF n) :
    fpRate p (posSet q p) + missRate q (posSet q p) = 1 - totalVariation p q := by
  have h := mass_posSet_eq_tv q p
  rw [totalVariation_comm] at h
  have hcompl := mass_add_compl q (posSet q p)
  linarith

/-- **The floor of the text is the balanced operating point.** A verifier on
the Neyman–Pearson line whose two error rates are equal has miss rate exactly
`(1 − TV)/2`, the Bayes error of the two hypotheses. The floor `λ·(1−TV)/2`
assumed in the verification-budget model is therefore the balanced
single-observation point of this derived family, with `λ = 1` at full balance
and `λ < 1` for verifiers willing to trade false positives for misses. -/
theorem bayes_balanced_miss (p q : PMF n)
    (h : fpRate p (posSet q p) = missRate q (posSet q p)) :
    missRate q (posSet q p) = (1 - totalVariation p q) / 2 := by
  have hsum := bayes_fp_add_miss p q
  linarith

/-- **Rounds on the same observation cannot beat the floor.** A verifier built
by conjoining two rounds that both act on the same single observation rejects
the intersection of the two rejection sets — still a set of observations of
that one draw — so the floor applies verbatim. The same holds for any other
Boolean combination, with the corresponding set in place of `S₁ ∩ S₂`. -/
theorem floor_under_rounds_and (p q : PMF n) (S₁ S₂ : Finset (Fin n)) {α : ℝ}
    (hfp : fpRate p (S₁ ∩ S₂) ≤ α) :
    1 - α - totalVariation p q ≤ missRate q (S₁ ∩ S₂) :=
  floor_from_detection p q _ hfp

/-- The disjunctive form: flagging when either round flags is again a single
test on the same observation, with the same floor. -/
theorem floor_under_rounds_or (p q : PMF n) (S₁ S₂ : Finset (Fin n)) {α : ℝ}
    (hfp : fpRate p (S₁ ∪ S₂) ≤ α) :
    1 - α - totalVariation p q ≤ missRate q (S₁ ∪ S₂) :=
  floor_from_detection p q _ hfp

end VerifyFloor
end Provenance
