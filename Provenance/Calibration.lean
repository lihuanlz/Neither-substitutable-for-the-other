import Mathlib.Data.Real.Basic
import Mathlib.Tactic

/-!
# Calibration non-identifiedness in minimum-contribution estimators

A widely used estimator of "how much of this output is attributable to the
human" reports a minimum *necessary* contribution when the human input is
unavailable. Writing `s` for the mean per-token unconditional surprisal of the
output and `tau` for the fitted plausibility bar, the estimator reduces to

  phiHat s tau = 1 - tau / s

which is Equation (10) of the source, divided through by `I(y)`.

Two properties of this expression are proved below.

1. The human does not occur in it. The reported number is a function of the
   output alone: `reported_ignores_human` and `human_cannot_move_reported`.

2. Its sign is decided by where the fitted bar `tau` falls relative to `s`, not
   by anything about the collaboration. `sign_not_identified` exhibits, for
   every output, two calibrations giving opposite signs. Since the bar is
   fitted out of distribution, the sign is not identified by the data.

Consequently the quantity cannot be a proportion of anything:
`estimator_not_a_proportion` refutes non-negativity outright and
`unbounded_below` shows there is no lower bound, so the `[0,1]` reading of the
primary measure does not survive into the estimation variant.
-/

/-- Minimum necessary human contribution, in reduced form.

`s` is the mean per-token unconditional surprisal of the output; `tau` is the
fitted plausibility bar (the source's `-log tau` per token). -/
noncomputable def minContribution (s tau : ℝ) : ℝ := 1 - tau / s

/-- A collaboration scenario.

The `human` field records the human's actual contribution. It is deliberately
present so that its absence from `reported` can be stated as a theorem. -/
structure Scenario where
  /-- mean per-token unconditional surprisal of the output -/
  s : ℝ
  /-- fitted plausibility bar -/
  tau : ℝ
  /-- the human's actual (signed) contribution -/
  human : ℝ

/-- What the estimator reports for a scenario. -/
noncomputable def reported (c : Scenario) : ℝ := minContribution c.s c.tau

/-! ### The estimator is a function of the output alone -/

/-- The reported value does not depend on the human's actual contribution. -/
theorem reported_ignores_human (s tau h₁ h₂ : ℝ) :
    reported ⟨s, tau, h₁⟩ = reported ⟨s, tau, h₂⟩ := rfl

/-- Equivalently: no choice of human contribution moves the reported number. -/
theorem human_cannot_move_reported (s tau h₁ h₂ : ℝ) :
    reported ⟨s, tau, h₁⟩ - reported ⟨s, tau, h₂⟩ = 0 := by
  rw [reported_ignores_human]
  ring

/-! ### The sign is set by the calibration, not by the collaboration -/

/-- `minContribution` is negative exactly when the fitted bar exceeds the
output's surprisal. -/
theorem signOf (s tau : ℝ) (hs : 0 < s) :
    minContribution s tau < 0 ↔ s < tau := by
  unfold minContribution
  constructor
  · intro h
    have h2 : (1 : ℝ) < tau / s := by linarith
    have hx : 1 * s < tau := (lt_div_iff₀ hs).mp h2
    simpa using hx
  · intro h
    have hgt : tau / s > (1 : ℝ) := by
      have hx : 1 * s < tau := by linarith [h]
      exact (lt_div_iff₀ hs).mpr hx
    linarith

/-- `minContribution` is positive exactly when the fitted bar is below the
output's surprisal. -/
theorem signOf_pos (s tau : ℝ) (hs : 0 < s) :
    0 < minContribution s tau ↔ tau < s := by
  unfold minContribution
  constructor
  · intro h
    have h2 : tau / s < (1 : ℝ) := by linarith
    have hx : tau < 1 * s := (div_lt_iff₀ hs).mp h2
    simpa using hx
  · intro h
    have h3 : tau / s < (1 : ℝ) := by
      have hx : tau < 1 * s := by linarith [h]
      exact (div_lt_iff₀ hs).mpr hx
    linarith

/-- **Main statement.** For every output there are two calibrations of the bar,
one below and one above the output's surprisal, that give opposite signs. The
sign is therefore not determined by the output-plus-human pair. -/
theorem sign_not_identified (s : ℝ) (hs : 0 < s) :
    ∃ tau₁ tau₂ : ℝ,
      0 < tau₁ ∧ tau₁ < s ∧ s < tau₂ ∧
        0 < minContribution s tau₁ ∧ minContribution s tau₂ < 0 := by
  refine ⟨s / 2, 2 * s, by positivity, by linarith, by linarith, ?_, ?_⟩
  · have h : (s / 2) / s = 1 / 2 := by
      rw [div_eq_iff hs.ne']
      ring
    rw [minContribution, h]
    norm_num
  · have h : (2 * s) / s = 2 := by
      rw [div_eq_iff hs.ne']
    rw [minContribution, h]
    norm_num

/-- The two calibrations differ by a factor of four, and the resulting reports
are exactly `+1/2` and `-1` regardless of the output. -/
theorem sign_not_identified_exact (s : ℝ) (hs : 0 < s) :
    minContribution s (s / 2) = 1 / 2 ∧ minContribution s (2 * s) = -1 := by
  constructor
  · have h : (s / 2) / s = 1 / 2 := by
      rw [div_eq_iff hs.ne']
      ring
    rw [minContribution, h]
    norm_num
  · have h : (2 * s) / s = 2 := by
      rw [div_eq_iff hs.ne']
    rw [minContribution, h]
    norm_num

/-- **Headline.** The report is invariant under the human's actual contribution,
yet its sign can be flipped by refitting the bar. The sign is therefore not
identified by the collaboration. -/
theorem sign_not_identified_in_context (s : ℝ) (hs : 0 < s) (h : ℝ) :
    ∃ tau₁ tau₂ : ℝ,
      0 < reported ⟨s, tau₁, h⟩ ∧ reported ⟨s, tau₂, h⟩ < 0 := by
  obtain ⟨tau₁, tau₂, _, _, _, hpos, hneg⟩ := sign_not_identified s hs
  exact ⟨tau₁, tau₂, hpos, hneg⟩

/-! ### The quantity is not a proportion -/

/-- The estimator is strictly below 1 whenever both inputs are positive. -/
theorem lt_one (s tau : ℝ) (hs : 0 < s) (ht : 0 < tau) :
    minContribution s tau < 1 := by
  rw [minContribution]
  have h : 0 < tau / s := div_pos ht hs
  linarith

/-- The estimator has no lower bound: for every `M < 1` some output, against
some calibration, reports below `M`. The witness is the output with surprisal
`1` and a bar just above it. -/
theorem unbounded_below (M : ℝ) (hM : M < 1) :
    ∃ s tau : ℝ, 0 < s ∧ 0 < tau ∧ minContribution s tau < M := by
  refine ⟨1, 2 - M, by norm_num, ?_, ?_⟩
  · linarith
  · rw [minContribution, div_one]
    linarith

/-- **The `[0,1]` reading fails.** The estimator is not a non-negative quantity,
so it is not a proportion of the output's information content. -/
theorem estimator_not_a_proportion (s : ℝ) (hs : 0 < s) :
    ¬ (∀ tau : ℝ, 0 < tau → 0 ≤ minContribution s tau) := by
  intro hall
  obtain ⟨tau₁, tau₂, _, _, hlt, _, hneg⟩ := sign_not_identified s hs
  have ht : 0 < tau₂ := lt_trans hs hlt
  exact (not_lt_of_ge (hall tau₂ ht)) hneg

/-! ### Exact instances -/

example : minContribution 4 1 = 3 / 4 := by norm_num [minContribution]
example : minContribution 1 (1 / 2) = 1 / 2 := by norm_num [minContribution]
example : minContribution 4 6 = -1 / 2 := by norm_num [minContribution]
example : minContribution 1 2 = -1 := by norm_num [minContribution]

/-- An output with mean per-token surprisal `1`. A bar at `0.5` reads as
substantial human contribution; a bar at `2` reads as negative. The human's
actual contribution is the same in both cases. -/
example (h : ℝ) :
    reported ⟨1, 1 / 2, h⟩ = 1 / 2 ∧ reported ⟨1, 2, h⟩ = -1 := by
  constructor <;> rw [reported, minContribution] <;> norm_num