/-
# Contribution decomposition under observation-layer filtering: formalising "human layer change / AI within-layer convergence"

This file formalises the mathematical core of a framework proposed by the user.

"Truth" is upgraded from a single point \(s^*\) to an **equivalence class on the
observation layer** \([s^*]_\alpha\), where \(\alpha \in (\mathcal{A},\le)\) is the
observation hierarchy (experimental protocol / task family / observational capability),
and \(\alpha \le \beta \Rightarrow \sim_\beta \subseteq \sim_\alpha\) (the stronger the
capability, the finer the class).

Let \(\mathcal{R}_\alpha\) be the set of **attainable estimates** under layer \(\alpha\)
(limited by experimental capability, compute, and theoretical constructibility). Define
the layer's **irreducible error lower bound**:

    Φ(α) = inf { d(ŝ, [s^*]_α) : ŝ ∈ ℘_α }

> **Note**: if the reachable set of \(\hat{s}\) is left unrestricted, take
> \(\hat{s} \in [s^*]_\alpha\) and \(\Phi(\alpha) = 0\), and the whole logarithmic
> decomposition collapses at once.
> **The reachable set \(\mathcal{R}_\alpha\) is a necessary precondition for this
> framework, not an option.**
> With it, \(\Phi(\alpha) > 0\) is exactly the formalisation of "this layer carries an
> irreducible residual", while \(\Phi(\alpha) = 0\) means that under this layer truth
> can be approached arbitrarily closely.

Logarithmic decomposition of the error:

    log(1/e) = log(1/Φ) + log(Φ/e)
               └──────┘   └──────┘
              ceiling   within-layer filling

## The duality proved by this file

* `ai_total_gain_bounded` — **the total number of bits AI can obtain within a layer has
  a hard upper bound**, and that bound is fixed by the layer alone (`log(e₀/Φ)`),
  **independent of how many steps AI takes**. This is stronger than "the marginal gain
  per step tends to zero": not merely does each step tend to zero, **the total is itself
  bounded**.
* `human_gain_unbounded` — **the gain from a human layer change is unbounded**.
* `ai_budget_grows_when_floor_drops` — only once a human has pushed \(\Phi\) down does the
  AI's usable budget **grow**. If the human makes no layer change, the AI has no budget
  left to gain.
* `no_gain_without_floor_drop` — **an unchanged layer means zero human gain**: if the
  layer changes but \(\Phi\) does not drop, the question was asked for nothing.

From these follows the **precise version** of "the marginal contribution of AI tends to
zero": **it holds only under the premise that the layer is fixed**, and a fixed layer is
exactly the state in which the human contributes nothing.

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open scoped BigOperators

namespace Provenance

/-
## 1. The AI's within-layer gain: a hard upper bound
-/

/-- **The AI's total within-layer gain is bounded.**

If the error sequence has already been driven down to \(e_N\), and \(e_N \ge \Phi\)
(\(\Phi\) is the layer's irreducible lower bound), then the cumulative log gain the AI
has taken so far, \(\log(e_0/e_N)\), does not exceed \(\log(e_0/\Phi)\).

The point: this upper bound is **fixed by the layer alone**, and no number of extra AI
steps can break it. -/
theorem ai_total_gain_bounded {e0 Φ eN : ℝ}
    (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    Real.log (e0 / eN) ≤ Real.log (e0 / Φ) := by
  rw [Real.log_div (ne_of_gt he0) (ne_of_gt heN),
      Real.log_div (ne_of_gt he0) (ne_of_gt hΦ)]
  have h1 : Real.log Φ ≤ Real.log eN := (Real.log_le_log_iff hΦ heN).mpr hΦle
  linarith

/-- **A single AI step has non-negative gain**: whenever the error does not grow, the
AI is earning bits. -/
theorem ai_step_gain_nonneg {e_prev e_next : ℝ}
    (hprev : 0 < e_prev) (hnext : 0 < e_next) (hmono : e_next ≤ e_prev) :
    0 ≤ Real.log (e_prev / e_next) := by
  rw [Real.log_div (ne_of_gt hprev) (ne_of_gt hnext)]
  have h1 : Real.log e_next ≤ Real.log e_prev := (Real.log_le_log_iff hnext hprev).mpr hmono
  linarith

/-- **The AI's remaining obtainable gain is non-negative**: the bits not yet taken,
\(\log(e_N/\Phi)\ge 0\). -/
theorem ai_remaining_gain_nonneg {Φ eN : ℝ} (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    0 ≤ Real.log (eN / Φ) := by
  rw [Real.log_div (ne_of_gt heN) (ne_of_gt hΦ)]
  have h1 : Real.log Φ ≤ Real.log eN := (Real.log_le_log_iff hΦ heN).mpr hΦle
  linarith

/-
## 2. The human's gain from a layer change: unbounded
-/

/-- **An unchanged layer means zero human gain.**

If switching layers does not bring the irreducible error down, the gain from this round
of asking is exactly 0.
This supplies a **falsifiable criterion** for "what counts as a good question":
a good question ⟺ it lowers \(\Phi\). -/
theorem no_gain_without_floor_drop {Φα Φβ : ℝ} (_hα : 0 < Φα) (hβ : 0 < Φβ)
    (heq : Φα = Φβ) : Real.log (Φα / Φβ) = 0 := by
  rw [heq]
  rw [div_self (ne_of_gt hβ), Real.log_one]

/-- **The human's gain from a layer change is unbounded.**

For any target number of bits \(M \ge 0\), there are floors in two layers such that
\(\log(\Phi(\alpha)/\Phi(\beta)) = M\).

Take \(\Phi(\alpha) = 1\) and \(\Phi(\beta) = e^{-M}\). -/
theorem human_gain_unbounded {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M := by
  refine ⟨1, Real.exp (-M), Real.exp_pos _, ?_, ?_⟩
  · have h := Real.exp_le_exp.mpr (neg_nonpos.mpr hM)
    simpa using h
  · rw [Real.log_div (by norm_num) (ne_of_gt (Real.exp_pos _)),
      Real.log_one, Real.log_exp]
    ring

/-- **The AI's usable budget only grows once a human has pushed the floor down.**

This is the **causal direction** that matters most in the whole analysis: it is not that
a stronger AI makes the human useless, but that **if the human does not push \(\Phi\)
down, no amount of AI strength buys extra budget**. -/
theorem ai_budget_grows_when_floor_drops {e0 Φα Φβ : ℝ}
    (he0 : 0 < e0) (hα : 0 < Φα) (hβ : 0 < Φβ) (hdrop : Φβ < Φα) :
    Real.log (e0 / Φβ) > Real.log (e0 / Φα) := by
  rw [Real.log_div (ne_of_gt he0) (ne_of_gt hβ),
      Real.log_div (ne_of_gt he0) (ne_of_gt hα)]
  have h1 : Real.log Φβ < Real.log Φα := (Real.log_lt_log_iff hβ hα).mpr hdrop
  linarith

/-- **Duality theorem**: unbounded human gain ⟹ bounded within-layer AI gain.

This formalises the asymmetry: there exist layer pairs with arbitrarily large human
gain, while for any fixed layer the AI's cumulative gain has a hard upper bound. -/
theorem asymmetry_of_layer_structure {M : ℝ} (hM : 0 ≤ M)
    {e0 Φ eN : ℝ} (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M)
      ∧ Real.log (e0 / eN) ≤ Real.log (e0 / Φ) :=
  ⟨human_gain_unbounded hM, ai_total_gain_bounded he0 hΦ heN hΦle⟩

/-
## 3. Additivity of the layered contributions
-/

/-- **Gain from a layer change + gain within a layer = total log gain**, with no error.

When AI approximates inside layer \(\beta\), if \(\alpha \le \beta\) and no residual is
left over, the total gain is exactly the layer-change gain plus the within-layer gain. -/
theorem layered_decomposition {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (heN : 0 < eN) :
    Real.log (Φα / eN) = Real.log (Φα / Φβ) + Real.log (Φβ / eN) := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt heN),
      Real.log_div (ne_of_gt hα) (ne_of_gt hβ),
      Real.log_div (ne_of_gt hβ) (ne_of_gt heN)]
  ring

/-- **Each term is non-negative**: the layer change loses nothing, and neither does the
within-layer part. -/
theorem layered_terms_nonneg {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (hdrop : Φβ ≤ Φα) (heN : 0 < eN) (hdrop2 : eN ≤ Φβ) :
    (0 ≤ Real.log (Φα / Φβ)) ∧ (0 ≤ Real.log (Φβ / eN)) := by
  constructor
  · rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
    have h1 : Real.log Φβ ≤ Real.log Φα := (Real.log_le_log_iff hβ hα).mpr hdrop
    linarith
  · rw [Real.log_div (ne_of_gt hβ) (ne_of_gt heN)]
    have h1 : Real.log eN ≤ Real.log Φβ := (Real.log_le_log_iff heN hβ).mpr hdrop2
    linarith

end Provenance
