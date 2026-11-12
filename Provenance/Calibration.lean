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
one below and one above the output's surprisal, that give opposite signs.
`minContribution` contains no term for the human input, so the sign is set by
the fitted bar, not by the output and not by the collaboration. -/

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

/-! ### Partial identification: the identified set is exactly an interval

`sign_not_identified` says one output does not pin down a sign. The accurate
positive statement is an interval-identification result in the sense of
Manski: if the bar is known only to lie in `[tauLo, tauHi]`, the values the
estimator can report form **exactly** the interval `[1 - tauHi/s, 1 - tauLo/s]`
— membership is `identifiedSet_subset`, sharpness is `identifiedSet_covers`,
and the width is `interval_width`. The sign is identified exactly when the
output's surprisal lies outside the bar range (`sign_identified_above`,
`sign_identified_below`); strictly inside it, two admissible midpoints give
opposite signs (`sign_not_identified_of_straddle`). The dual statement,
`estimator_recovers_truth`, marks the other end of the boundary: with the bar
calibrated in distribution (`tau = s·(1 − phi)` for the true `phi`) the
estimator recovers `phi` exactly. Out of distribution, only the interval
remains. -/

/-- Every admissible calibration reports within the interval. -/
theorem identifiedSet_subset {s tauLo tauHi tau : ℝ} (hs : 0 < s)
    (hlo : tauLo ≤ tau) (hhi : tau ≤ tauHi) :
    1 - tauHi / s ≤ minContribution s tau ∧ minContribution s tau ≤ 1 - tauLo / s := by
  have h1 : tau / s ≤ tauHi / s := (div_le_div_iff_of_pos_right hs).mpr hhi
  have h2 : tauLo / s ≤ tau / s := (div_le_div_iff_of_pos_right hs).mpr hlo
  unfold minContribution
  constructor <;> linarith

/-- **The interval is sharp**: every point of it is reported by some admissible
calibration, namely the bar `tau = s·(1 − z)`. So the identified set is not
merely contained in the interval — it *is* the interval. -/
theorem identifiedSet_covers {s tauLo tauHi : ℝ} (hs : 0 < s) {z : ℝ}
    (hzlo : 1 - tauHi / s ≤ z) (hzhi : z ≤ 1 - tauLo / s) :
    ∃ tau : ℝ, tauLo ≤ tau ∧ tau ≤ tauHi ∧ minContribution s tau = z := by
  have hne : s ≠ 0 := ne_of_gt hs
  have h1 : tauLo / s ≤ 1 - z := by linarith
  have h2 : 1 - z ≤ tauHi / s := by linarith
  have h1' : tauLo ≤ (1 - z) * s := by
    have hmul := mul_le_mul_of_nonneg_right h1 (le_of_lt hs)
    rwa [div_mul_cancel₀ tauLo hne] at hmul
  have h2' : (1 - z) * s ≤ tauHi := by
    have hmul := mul_le_mul_of_nonneg_right h2 (le_of_lt hs)
    rwa [div_mul_cancel₀ _ hne] at hmul
  refine ⟨s * (1 - z), by rw [mul_comm]; exact h1', by rw [mul_comm]; exact h2', ?_⟩
  unfold minContribution
  rw [mul_div_cancel_left₀ _ hne]
  ring

/-- The width of the identified set is the bar's uncertainty divided by the
surprisal: the lower the output's surprisal, the wider the interval of values
consistent with it. -/
theorem interval_width (s tauLo tauHi : ℝ) (hs : 0 < s) :
    (1 - tauLo / s) - (1 - tauHi / s) = (tauHi - tauLo) / s := by
  have hne : s ≠ 0 := ne_of_gt hs
  field_simp

/-- If the output's surprisal clears the whole bar range, every admissible
calibration reports a positive contribution: the sign is identified. -/
theorem sign_identified_above {s tauLo tauHi tau : ℝ} (hs : 0 < s)
    (hclear : tauHi < s) (_hlo : tauLo ≤ tau) (hhi : tau ≤ tauHi) :
    0 < minContribution s tau :=
  (signOf_pos s tau hs).mpr (lt_of_le_of_lt hhi hclear)

/-- If the output's surprisal undercuts the whole bar range, every admissible
calibration reports a negative contribution: the sign is identified, and it is
negative. -/
theorem sign_identified_below {s tauLo tauHi tau : ℝ} (hs : 0 < s)
    (hclear : s < tauLo) (hlo : tauLo ≤ tau) (_hhi : tau ≤ tauHi) :
    minContribution s tau < 0 :=
  (signOf s tau hs).mpr (lt_of_lt_of_le hclear hlo)

/-- **Strictly inside the bar range the sign is not identified**: two
admissible midpoint calibrations straddle the surprisal and give opposite
signs. Together with `sign_identified_above` and `sign_identified_below` this
says the sign is identified exactly off the open interval `(tauLo, tauHi)`. -/
theorem sign_not_identified_of_straddle {s tauLo tauHi : ℝ} (hs : 0 < s)
    (hlo : tauLo < s) (hhi : s < tauHi) :
    ∃ tau₁ tau₂ : ℝ, tauLo ≤ tau₁ ∧ tau₁ ≤ tauHi ∧ tauLo ≤ tau₂ ∧ tau₂ ≤ tauHi ∧
      0 < minContribution s tau₁ ∧ minContribution s tau₂ < 0 := by
  refine ⟨(tauLo + s) / 2, (s + tauHi) / 2, by linarith, by linarith, by linarith,
    by linarith, ?_, ?_⟩
  · exact (signOf_pos s _ hs).mpr (by linarith)
  · exact (signOf s _ hs).mpr (by linarith)

/-- **The dual statement: calibrated in distribution, the estimator is exact.**
If the bar equals `s·(1 − phi)` — the value the source's own model assigns to
the true contribution `phi` — the estimator recovers `phi` exactly. The
boundary of the framework is sharp: in-distribution calibration gives a point
answer; out of distribution only the interval of `identifiedSet_subset` and
`identifiedSet_covers` remains. -/
theorem estimator_recovers_truth {s tau phi : ℝ} (hs : 0 < s)
    (h : tau = s * (1 - phi)) :
    minContribution s tau = phi := by
  unfold minContribution
  rw [h, mul_div_cancel_left₀ _ (ne_of_gt hs)]
  ring

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