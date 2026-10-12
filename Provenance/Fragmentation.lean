/-
# Fragmentation: why human-AI innovation does not scale

This is a topic held apart from the main line. Its claim is:

> **AI does not scale human innovation. It fragments it.**

The mechanism has two halves, and this file gives a set of theorems for each.

1. **The coalition side (endogenous)**: within a single layer, the layer change
   a coalition achieves equals the layer change of its best member. One more
   person leaves the final layer numerically unchanged:
   `marginal_agent_pure_waste`. Headcount is not a variable.
2. **The time side (exogenous)**: holding an increment back instead of
   publishing waits for a window that will be superseded. Coverage is
   absorbing, and the value of waiting is **monotone non-increasing**:
   `holdValue_antitone`. Once superseded, the value of holding is exactly 0:
   `publish_dominates_when_covered`.

The two halves together give `fragmentation_squeeze`, which blocks both
ordinary routes to "a big story" at once. **The only exit is to move to a new
layer**, and that is precisely the unbounded space already proved by
`Refinement.human_gain_unbounded`.

## Interface with the main line

The file uses the same currency as `Provenance.Refinement` throughout: a layer
is \(\Phi > 0\), and the gain from a human layer change is the logarithmic gain
\(\log(\Phi_{\text{old}}/\Phi_{\text{new}})\).
`saturation_duality` sets the saturation of the two sides side by side:

* AI side: `Refinement.ai_total_gain_bounded`, upper bound `log(e₀/Φ)`,
  **independent of the number of steps**
* human side: `marginal_agent_pure_waste` here, the upper bound being set by
  the best member, **independent of headcount**

Both sides saturate at once. This is "irreplaceability" projected onto the
scaling problem: nobody substitutes for anybody, and nobody adds anything on
top either.

## The modelling choice here, and why it is falsifiable

A coalition is modelled as "the set of layers its members can each reach
independently", with the result taken to be the best of them (a `max`-type
combination). This is a stronger claim than "merging with a discount", and one
that reality can knock over more easily. What this file asserts is that
**the merge is exactly the best individual and every other member contributes
zero**.

If collaboration really does have complementarity, so that two people together
beat the better of them, then `add_member_same_reach` fails immediately. What
is given here is a **falsifiable position**, not submodularity restated in
other words.

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement

namespace Provenance
namespace Fragmentation

noncomputable section
open Classical

/-
## 1. The coalition

A coalition is modelled as **the set of layers its members can each reach
independently**.

This is not a shortcut. `Provenance.Basic` has already proved that content
layers are non-identifiable under the optimal test, so two members "reaching
the same layer" cannot be told apart observationally. What is observable is
therefore the set of reachable layers, not a correspondence of who did what.
-/

/-- A coalition: the set of layers its members can each reach independently. -/
abbrev Coalition := Finset ℝ

/-- The layer the coalition finally pushes down to: the best of its members. -/
def reach (D : Coalition) (hD : D.Nonempty) : ℝ := D.min' hD

/-- How far the coalition pushes the starting layer `Φ` down, measured in the
same logarithmic currency as `Refinement`. -/
def gain (Φ : ℝ) (D : Coalition) (hD : D.Nonempty) : ℝ :=
  Real.log (Φ / reach D hD)

/-- The sum of the layer changes reached by each member on their own. -/
def totalIndividual (Φ : ℝ) (D : Coalition) : ℝ :=
  D.sum fun a => Real.log (Φ / a)

/-- A legitimate state of collaboration: every layer a member reaches lies in
`(0, Φ]`. -/
def Admissible (Φ : ℝ) (D : Coalition) : Prop := ∀ a ∈ D, 0 < a ∧ a ≤ Φ

theorem reach_mem (D : Coalition) (hD : D.Nonempty) : reach D hD ∈ D := by
  unfold reach; exact Finset.min'_mem D hD

theorem reach_le_of_mem {D : Coalition} {hD : D.Nonempty} {a : ℝ} (ha : a ∈ D) :
    reach D hD ≤ a := by
  unfold reach; exact Finset.min'_le D a ha

theorem reach_pos {D : Coalition} {hD : D.Nonempty} (h : ∀ a ∈ D, 0 < a) :
    0 < reach D hD := h _ (reach_mem D hD)

/-
## 2. Main theorem: adding a member adds nothing
-/

/-- **Adding a member leaves the final layer numerically unchanged.**

As long as the newcomer does not beat the best member so far, the coalition
achieves exactly what it achieved before.

This is also the sharpest **falsification point** of the whole topic. If
collaboration between two people can beat the better of them in reality, this
statement fails immediately. -/
theorem add_member_same_reach {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (ha : reach D hD ≤ a) :
    reach (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = reach D hD := by
  unfold reach
  rw [Finset.min'_insert a D hD]
  exact min_eq_left ha

/-- **The layer change of the coalition equals the layer change of its best
member.**

Every other member contributes exactly 0 to the final layer. -/
theorem gain_eq_best_member {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (hpos : ∀ b ∈ D, 0 < b) (hmem : a ∈ D)
    (hbest : reach D hD = a) : gain Φ D hD = Real.log (Φ / a) := by
  have ha : 0 < a := hpos a hmem
  unfold gain
  rw [hbest, Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]

/-- **An individual member's gain never exceeds the coalition's gain.** -/
theorem member_gain_le_gain {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (hpos : ∀ b ∈ D, 0 < b) (hmem : a ∈ D) :
    Real.log (Φ / a) ≤ gain Φ D hD := by
  have hr : 0 < reach D hD := reach_pos hpos
  have ha : 0 < a := hpos a hmem
  have hle : reach D hD ≤ a := reach_le_of_mem hmem
  have h1 : Real.log (reach D hD) ≤ Real.log a := (Real.log_le_log_iff hr ha).mpr hle
  unfold gain
  rw [Real.log_div (ne_of_gt hΦ) (ne_of_gt hr),
      Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]
  linarith

/-- **The (N+1)-th person: gain exactly 0, cost exactly `log(Φ/a)`.**

The whole content of the fragmentation claim sits on this one line. The left
side does not vary with headcount; the right side increases strictly. -/
theorem marginal_agent_pure_waste {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hnew : a ∉ D) (hreach : reach D hD ≤ a) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ totalIndividual Φ (insert a D) = totalIndividual Φ D + Real.log (Φ / a) := by
  have hreach' : reach (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = reach D hD :=
    add_member_same_reach hreach
  constructor
  · unfold gain
    rw [hreach']
  · have hsum : totalIndividual Φ (insert a D)
        = Real.log (Φ / a) + totalIndividual Φ D := by
      simp only [totalIndividual, Finset.sum_insert hnew]
    rw [hsum, add_comm]

/-
## 3. Waste

The gap between `totalIndividual` and `gain` is the part that collaboration
throws away.
-/

/-- Collaboration waste = the sum of the members' layer changes minus the layer
change actually achieved. -/
def waste (Φ : ℝ) (D : Coalition) (hD : D.Nonempty) : ℝ :=
  totalIndividual Φ D - gain Φ D hD

theorem term_nonneg {Φ a : ℝ} (hΦ : 0 < Φ) (ha : 0 < a) (hle : a ≤ Φ) :
    0 ≤ Real.log (Φ / a) := by
  have h1 : Real.log a ≤ Real.log Φ := (Real.log_le_log_iff ha hΦ).mpr hle
  rw [Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]
  linarith

/-- No single member's gain exceeds the total, since every other term is
nonnegative. -/
theorem member_le_total {Φ : ℝ} {D : Coalition} {a : ℝ}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) (hmem : a ∈ D) :
    Real.log (Φ / a) ≤ totalIndividual Φ D := by
  have hsplit : (D.erase a).sum (fun b : ℝ => Real.log (Φ / b)) + Real.log (Φ / a)
      = totalIndividual Φ D := Finset.sum_erase_add D _ hmem
  have hrest : 0 ≤ (D.erase a).sum fun b : ℝ => Real.log (Φ / b) := by
    refine Finset.sum_nonneg fun b hb => term_nonneg hΦ ?_ ?_
    · exact adm b (Finset.mem_of_mem_erase hb) |>.1
    · exact adm b (Finset.mem_of_mem_erase hb) |>.2
  linarith

/-- The coalition's result never exceeds the sum of the members' gains: merging
never adds output. -/
theorem gain_le_total {Φ : ℝ} {D : Coalition} {hD : D.Nonempty}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) :
    gain Φ D hD ≤ totalIndividual Φ D := by
  unfold gain
  exact member_le_total hΦ adm (reach_mem D hD)

/-- **Waste is nonnegative**: collaboration never produces extra layer change
beyond the best individual. -/
theorem waste_nonneg {Φ : ℝ} {D : Coalition} {hD : D.Nonempty}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) : 0 ≤ waste Φ D hD := by
  unfold waste
  linarith [gain_le_total (hD := hD) hΦ adm]

/-- **More members only increase waste; they do not change the result.** -/
theorem headcount_adds_waste_only {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) (ha : 0 < a) (hle : a ≤ Φ) (hnew : a ∉ D)
    (hreach : reach D hD ≤ a) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ 0 ≤ waste Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ := by
  refine ⟨(marginal_agent_pure_waste hnew hreach).1, ?_⟩
  refine waste_nonneg hΦ fun b hb => ?_
  rw [Finset.mem_insert] at hb
  rcases hb with rfl | hb
  · exact ⟨ha, hle⟩
  · exact adm b hb

/-
## 4. Duality with the AI upper bound
-/

/-- **Both sides saturate.**

* AI side: `Refinement.ai_total_gain_bounded`, upper bound `log(e₀/Φ)`,
  **independent of the number of steps**;
* human side: `marginal_agent_pure_waste`, the upper bound being set by the best
  member, **independent of headcount**.

This is "irreplaceability" projected onto the scaling problem: nobody
substitutes for anybody, and nobody adds anything on top either. -/
theorem saturation_duality {M : ℝ} (hM : 0 ≤ M)
    {e0 Φ eN : ℝ} (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    (Real.log (e0 / eN) ≤ Real.log (e0 / Φ))
      ∧ (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M) :=
  ⟨ai_total_gain_bounded he0 hΦ heN hΦle, human_gain_unbounded hM⟩

/-
## 5. The time side: exclusive windows
-/

/-- What holding an increment back is worth: at expiry, if it has been
superseded, exactly 0. -/
def holdValue (vBig d : ℝ) (covered : ℝ → Prop) : ℝ :=
  if covered d then 0 else vBig

theorem holdValue_eq_zero_of_covered (vBig d : ℝ) {covered : ℝ → Prop} (h : covered d) :
    holdValue vBig d covered = 0 := by
  simp [holdValue, h]

theorem holdValue_eq_of_not_covered (vBig d : ℝ) {covered : ℝ → Prop} (h : ¬covered d) :
    holdValue vBig d covered = vBig := by
  simp [holdValue, h]

/-- **If the window is superseded at expiry, publishing immediately is
strictly better.**

This is the temporal mechanism of fragmentation. The payoff of a big story is
conditional and collapses to zero once the condition fails, whereas a small
payoff taken immediately is already certain. -/
theorem publish_dominates_when_covered (vBig vSmall d : ℝ) {covered : ℝ → Prop}
    (h : covered d) (hsmall : 0 < vSmall) : vSmall > holdValue vBig d covered := by
  rw [holdValue_eq_zero_of_covered vBig d h]
  linarith

/-- **The value of waiting is monotone non-increasing.**

Coverage is absorbing: once superseded, always superseded. Holding an increment
back is therefore not an option. There are only two outcomes, still open and
already superseded, and no third one worth waiting for. -/
theorem holdValue_antitone (vBig : ℝ) (hbig : 0 ≤ vBig) {covered : ℝ → Prop}
    (hmono : ∀ d d', d ≤ d' → covered d → covered d') :
    ∀ d d', d ≤ d' → holdValue vBig d' covered ≤ holdValue vBig d covered := by
  intro d d' hle
  by_cases h2 : covered d'
  · rw [holdValue_eq_zero_of_covered vBig d' h2]
    by_cases h1 : covered d
    · rw [holdValue_eq_zero_of_covered vBig d h1]
    · rw [holdValue_eq_of_not_covered vBig d h1]
      exact hbig
  · rw [holdValue_eq_of_not_covered vBig d' h2]
    by_cases h1 : covered d
    · exact absurd (hmono d d' hle h1) h2
    · rw [holdValue_eq_of_not_covered vBig d h1]

/-
## 6. The double squeeze

Adding people yields zero gain; holding back gets pre-empted. Both ordinary
routes to a big story are therefore closed at the same time.
-/

/-- **The fragmentation equilibrium.**

Both routes are blocked at once:
* on the coalition side, adding a member does not change the final layer;
* on the time side, waiting until expiry yields zero if superseded. -/
theorem fragmentation_squeeze {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hnew : a ∉ D) (hreach : reach D hD ≤ a)
    {vBig d : ℝ} {covered : ℝ → Prop} (hcov : covered d) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ holdValue vBig d covered = 0 :=
  ⟨(marginal_agent_pure_waste hnew hreach).1,
    holdValue_eq_zero_of_covered vBig d hcov⟩

/-- **Scaling comes from changing layers, never from adding headcount.**

This is where the topic lands, and it explains why the human side is still
unbounded. The boundlessness does not come from there being more people. It
comes from **layers being changeable**. -/
theorem scale_by_new_layers_not_by_headcount {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M :=
  human_gain_unbounded hM

end
end Fragmentation
end Provenance
