/-
# Numerical validation: exact rational instances certified by Lean

Type checking only guarantees that the theorems are true. This file
**proves concrete numbers on concrete distributions**, checking the formulas
of the original analysis against the Lean theorems one by one.

Note that these are **exact equalities** (`totalVariation pA pB = 1/3`, say),
not approximations printed by `#eval`. Arithmetic on `ℝ` is not executable, so
a proof stands in for an evaluation. That is stronger than printing a number:
any mismatch fails the build outright.

Reference table:

| Instance                  | TV  | Bayes accuracy | Theory (1+TV)/2 | Bayes error rate | Theory (1−TV)/2 |
|---------------------------|-----|----------------|-----------------|------------------|-----------------|
| Identical (unidentifiable) | 0   | 1/2            | 1/2             | 1/2              | 1/2             |
| Weakly separable           | 1/6 | 7/12           | 7/12            | 5/12             | 5/12            |
| Moderately separable       | 1/3 | 2/3            | 2/3             | 1/3              | 1/3             |
| Fully separable            | 1   | 1              | 1               | 0                | 0               |

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic
import Provenance.Contamination

namespace Provenance

open Finset
open scoped BigOperators

/-! ### Explicit absolute values on `ℝ`

`norm_num` does not decide the sign of `|q : ℝ|` by itself, so every positive
rational used below is simplified by hand. -/

private theorem absHalf : |(1 / 2 : ℝ)| = 1 / 2 := abs_of_nonneg (by norm_num)
private theorem absThird : |(1 / 3 : ℝ)| = 1 / 3 := abs_of_nonneg (by norm_num)
private theorem absSixth : |(1 / 6 : ℝ)| = 1 / 6 := abs_of_nonneg (by norm_num)
private theorem absQuarter : |(1 / 4 : ℝ)| = 1 / 4 := abs_of_nonneg (by norm_num)
private theorem absEighth : |(1 / 8 : ℝ)| = 1 / 8 := abs_of_nonneg (by norm_num)
private theorem absTwelfth : |(1 / 12 : ℝ)| = 1 / 12 := abs_of_nonneg (by norm_num)



/-- Build a PMF on the four-point space out of four nonnegative numbers. -/
noncomputable def mkPMF4 (a b c d : ℝ) (h0 : 0 ≤ a) (h1 : 0 ≤ b) (h2 : 0 ≤ c) (h3 : 0 ≤ d)
    (hs : a + b + c + d = 1) : PMF 4 where
  val := fun i => match i.val with
    | 0 => a | 1 => b | 2 => c | 3 => d
    | _ => 0
  nonneg := by
    intro i
    fin_cases i <;> assumption
  sum_one := by
    simp_rw [Fin.sum_univ_succ]
    norm_num
    linarith

/-- `pA = (1/2, 1/3, 1/6, 0)`. -/
noncomputable def pA : PMF 4 :=
  mkPMF4 (1/2) (1/3) (1/6) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- A distribution at `TV = 1/3` from `pA`. -/
noncomputable def pB : PMF 4 :=
  mkPMF4 (1/6) (1/3) (1/2) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- A distribution at `TV = 1/6` from `pA`. -/
noncomputable def pC : PMF 4 :=
  mkPMF4 (1/3) (1/3) (1/3) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- A distribution entirely disjoint from `pA` (`TV = 1`). -/
noncomputable def pD : PMF 4 :=
  mkPMF4 0 0 0 1 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- An arbitrary (non-optimal) test. -/
noncomputable def t0 : Test 4 := fun i => decide (i.val = 0)

/-- A valid contamination rate `π = 1/2`. -/
noncomputable def hPi : MixWeight (1 / 2 : ℝ) := ⟨by norm_num, by norm_num⟩

/-- A valid contamination rate `π = 1` (the cumulative scheme). -/
noncomputable def hOne : MixWeight 1 := ⟨by norm_num, by norm_num⟩

/-! ## Example 1: the unidentifiable case at `TV = 0` -/

example : totalVariation pA pA = 0 := totalVariation_self pA

example : accuracy t0 pA pA = 1 / 2 := unidentifiable pA pA (totalVariation_self pA) t0

/-- At `TV = 0` even the Bayes test reaches only `1/2`. -/
example : accuracy (bayes pA pA) pA pA = 1 / 2 :=
  unidentifiable pA pA (totalVariation_self pA) (bayes pA pA)

/-! ## Example 2: the moderately separable case at `TV = 1/3` -/

example : totalVariation pA pB = 1 / 3 := by
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- Bayes accuracy = `(1 + TV)/2 = 2/3`, an instance of the original formula. -/
example : accuracy (bayes pA pB) pA pB = 2 / 3 := by
  rw [bayes_optimal]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- Bayes error rate = `(1 − TV)/2 = 1/3`, an instance of `P_e = ½(1−TV)`
from the original analysis. -/
example : errRate (bayes pA pB) pA pB = 1 / 3 := by
  rw [bayes_errRate]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- The advantage margin is exactly `TV/2 = 1/6`, an instance of
`accuracy_bounds`. -/
example : accuracy (bayes pA pB) pA pB - 1 / 2 = totalVariation pA pB / 2 := by
  rw [bayes_optimal]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## Example 3: the weakly separable case at `TV = 1/6`

Compare with Example 2: under the same test the advantage falls from `1/6` to
`1/12`. This checks correction #1 to the original analysis directly:
**identifiability varies continuously with TV rather than switching on and
off**. -/

example : totalVariation pA pC = 1 / 6 := by
  unfold totalVariation pA pC mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

example : accuracy (bayes pA pC) pA pC = 7 / 12 := by
  rw [bayes_optimal]
  unfold totalVariation pA pC mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## Example 4: the fully separable case at `TV = 1` -/

example : totalVariation pA pD = 1 := by
  unfold totalVariation pA pD mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- At full separability a **zero-error** test exists: the extreme case of
identifiability. -/
example : errRate (bayes pA pD) pA pD = 0 := by
  rw [bayes_errRate]
  unfold totalVariation pA pD mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## Example 5: the cost of contamination (checked against `Contamination`) -/

/-- At contamination rate `π = 1/2` the signal is exactly halved:
`½ · (1/3) = 1/6`. -/
example : totalVariation (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi) = 1 / 6 := by
  rw [totalVariation_mix pA pA pB hPi]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- After contamination the best advantage is exactly `π · TV₀/2 = 1/12`. -/
example : accuracy (bayes (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi))
      (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi) - 1 / 2 = 1 / 12 := by
  rw [bayes_optimal, totalVariation_mix pA pA pB hPi]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- After three rounds of self-consuming re-mixing the signal decays to
`π³ = 1/8` of its size: `1/8 · (1/3) = 1/24`.

This is a numerical instance of the **exact exponential law** behind
"recursive contamination / model autophagy" in the original analysis. -/
example : totalVariation (contamIter pA (1 / 2) hPi 3 pA) (contamIter pA (1 / 2) hPi 3 pB)
    = 1 / 24 := by
  rw [totalVariation_contamIter pA hPi 3 pA pB]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- Under the cumulative scheme, where the human source is reinserted at full
weight `π = 1` each round, the signal **does not decay at all**.

This is the mechanism behind the result of Gersthaler et al. (2024):
accumulation avoids collapse because the decay factor is `π = 1`. -/
example : totalVariation (contamIter pA 1 hOne 5 pA) (contamIter pA 1 hOne 5 pB)
    = totalVariation pA pB := by
  rw [totalVariation_contamIter pA hOne 5 pA pB]
  simp

end Provenance
