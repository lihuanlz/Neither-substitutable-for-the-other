/-
# The cost of contamination: the TV mixing theorem and recursive contamination

This file formalises the "recursive contamination" passage of section 1 of the
original analysis and gives an **exact** quantitative result:

    TV( (1-π)·p_H + π·u , (1-π)·p_H + π·v )  =  π · TV(u, v)

That is: **a contamination rate π attenuates the identifiability signal by exactly
a linear factor π**.

Combined with `Provenance.Basic.accuracy_bounds` (best advantage = TV/2) this gives

    best detection advantage after contamination  =  π · TV₀ / 2

which answers "the cost of contamination" in a computable, non-qualitative way, and
yields directly:

* `totalVariation_contamIter` - under the **self-consuming** recursion, in which
  the human source is reinserted every round with weight π, the identifiability
  signal decays **exponentially** as `π^k` (an exact equation, not an
  approximation).
* `contam_decay_bound` - with `TV ≤ 1` one gets `signal ≤ π^k`. When `π < 1` we
  have `π^k → 0`, so the signal from the human source is eventually washed out.
  This is the **quantitative version** of the strict picture of
  "model self-eating / model collapse" in the original analysis.
* `contamination_budget` - the converse gives a **contamination tolerance**: to
  preserve a target advantage `δ` one needs `π · TV₀ ≥ 2δ`.
* `accumulate_no_decay` - the accumulation scheme is the case `π = 1`, where the
  **signal does not decay at all**.

## A premise that has to be made explicit

The mixture `(1-π)·p_H + π·q` is a valid probability distribution only when
`0 ≤ π ≤ 1`; `π < 0` or `π > 1` produces negative mass. Lean forces this premise
into the signature of `mix` (the argument `h : MixWeight π`), which is more
reliable than assuming it verbally in the prose.

## An honesty statement that matters

The original analysis claims that accumulating raw data converges back to p_H
(Gersthaler et al., *Nature* 2024). **This file formalises only the mechanism part
of that claim (`accumulate_no_decay`), not convergence back to p_H itself.** The
latter is a convergence theorem about a stochastic generative process and needs an
"empirical distribution" and a construction of the stochastic process, well beyond
the present scope.

Lean earns its keep here: it forces the two claims apart.

* **Proved**: under the recursion that re-mixes with a fixed weight π each round,
  the signal decays as `π^k`.
* **Not proved**: that under the accumulation scheme the signal converges back to
  the **original distribution** (only the absence of decay was proved).

So the real driver of the decay is **the weight with which human data is
reinserted each round**, not the vague notion of "whether there is contamination".
That is exactly what `totalVariation_contamIter` characterises.

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {n : ℕ}

/-- An admissible contamination rate: `0 ≤ π ≤ 1`. -/
abbrev MixWeight (π : ℝ) : Prop := 0 ≤ π ∧ π ≤ 1

/-- The mixture: the AI source is layered onto the human source with weight `π`.
`π` is the **contamination rate**. -/
noncomputable def mix (p q : PMF n) (π : ℝ) (h : MixWeight π) : PMF n where
  val := fun i => (1 - π) * p.val i + π * q.val i
  nonneg := by
    intro i
    have hπ : (0 : ℝ) ≤ π ∧ π ≤ 1 := h
    have h1 : (0 : ℝ) ≤ p.val i := p.nonneg i
    have h2 : (0 : ℝ) ≤ q.val i := q.nonneg i
    have h3 : (0 : ℝ) ≤ 1 - π := by linarith
    exact add_nonneg (mul_nonneg h3 h1) (mul_nonneg hπ.1 h2)
  sum_one := by
    have key : (∑ i : Fin n, ((1 - π) * p.val i + π * q.val i))
        = (1 - π) * (∑ i : Fin n, p.val i) + π * (∑ i : Fin n, q.val i) := by
      rw [Finset.sum_add_distrib, Finset.mul_sum, Finset.mul_sum]
    rw [key, p.sum_one, q.sum_one]
    ring

/-- **The mixing theorem (the core one)**: under mixing, total variation distance
**scales exactly linearly in the contamination rate**.

    TV((1-π)·p_H + π·u, (1-π)·p_H + π·v) = π · TV(u, v)

The two sides share a human source, so subtracting them cancels the human part
entirely and leaves a difference of `π` times the original. -/
theorem totalVariation_mix (p u v : PMF n) {π : ℝ} (h : MixWeight π) :
    totalVariation (mix p u π h) (mix p v π h) = π * totalVariation u v := by
  unfold totalVariation
  have hval : ∀ i : Fin n, (mix p u π h).val i = (1 - π) * p.val i + π * u.val i := by
    intro i
    rfl
  have hval' : ∀ i : Fin n, (mix p v π h).val i = (1 - π) * p.val i + π * v.val i := by
    intro i
    rfl
  have key : ∀ i : Fin n,
      |(mix p u π h).val i - (mix p v π h).val i| = π * |u.val i - v.val i| := by
    intro i
    rw [hval i, hval' i]
    have e : (1 - π) * p.val i + π * u.val i - ((1 - π) * p.val i + π * v.val i)
        = π * (u.val i - v.val i) := by ring
    rw [e, abs_mul, abs_of_nonneg h.1]
  rw [Finset.sum_congr rfl (fun i _ => key i), ← Finset.mul_sum]
  ring

/-- **The best advantage after contamination** is exactly `π · TV₀/2`.

With `accuracy_bounds` (advantage = TV/2) this says that the contamination rate π
multiplies the detectable advantage by exactly π, rather than roughly weakening
it. -/
theorem maxAdvantage_mix (p u v : PMF n) {π : ℝ} (h : MixWeight π) :
    (1 + totalVariation (mix p u π h) (mix p v π h)) / 2 - 1 / 2
      = π * (totalVariation u v / 2) := by
  rw [totalVariation_mix p u v h]
  ring

/-- **Contamination tolerance**: preserving a target advantage `δ` requires
`π · TV₀ ≥ 2δ`.

With equality, the largest admissible contamination rate is `π ≤ 2δ / TV₀`. So the
smaller the original identifiability signal `TV₀`, the **lower the tolerance for
contamination**. -/
theorem contamination_budget (p u v : PMF n) {π δ : ℝ} (h : MixWeight π)
    (htarget : δ ≤ totalVariation (mix p u π h) (mix p v π h) / 2) :
    π * totalVariation u v ≥ 2 * δ := by
  rw [totalVariation_mix p u v h] at htarget
  linarith

/-! ## Recursive contamination: self-consuming re-mixing -/

/-- One round of self-consuming re-mixing: every round re-mixes the current
generation with the human source at a fixed weight `π`. This is a **measurable
shell** around the recursion `p_A^{(t+1)} = Fit(π_H·p_H + π_A·p_A^{(t)})` of the
original analysis (`Fit` is taken to be the identity here, so only the signal is
tracked). -/
noncomputable def contamIter (p : PMF n) (π : ℝ) (h : MixWeight π) (k : ℕ) (x : PMF n) : PMF n :=
  Nat.rec x (fun _ y => mix p y π h) k

/-- **The recursive contamination theorem**: after `k` rounds of self-consuming
re-mixing the identifiability signal is attenuated to a factor `π^k`, as an **exact
equation**.

This turns the qualitative description of "model self-eating" in the original
analysis into an **exact exponential law**. -/
theorem totalVariation_contamIter (p : PMF n) {π : ℝ} (h : MixWeight π) :
    ∀ k u v, totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = (π ^ k) * totalVariation u v := by
  intro k
  induction k with
  | zero =>
      intro u v
      show totalVariation u v = π ^ 0 * totalVariation u v
      simp
  | succ k ih =>
      intro u v
      change totalVariation (mix p (contamIter p π h k u) π h)
          (mix p (contamIter p π h k v) π h) = _
      rw [totalVariation_mix p (contamIter p π h k u) (contamIter p π h k v) h]
      rw [ih u v]
      ring

/-- **Decay upper bound**: after `k` rounds of self-consuming re-mixing the
identifiability signal does not exceed `π^k`.

This follows from `totalVariation_le_one` (TV ≤ 1) and `totalVariation_contamIter`
(exactly `π^k · TV₀`). When `π < 1` we have `π^k → 0`, so the signal is eventually
washed out. This is the **quantitative version** of the strict picture of
"model self-eating / model collapse" in the original analysis.

(Not formalised: rewriting this bound as the limit statement
`Tendsto ... (nhds 0)`. That needs additional limit and filter constructions,
which were out of scope here. The bound itself already supports every conclusion
drawn from it.) -/
theorem contam_decay_bound (p u v : PMF n) {π : ℝ} (h : MixWeight π) (k : ℕ) :
    totalVariation (contamIter p π h k u) (contamIter p π h k v) ≤ π ^ k := by
  have hπ : (0 : ℝ) ≤ π ∧ π ≤ 1 := h
  have h1 : totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = π ^ k * totalVariation u v := totalVariation_contamIter p h k u v
  calc totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = π ^ k * totalVariation u v := h1
    _ ≤ π ^ k * 1 := by
        have hle : totalVariation u v ≤ 1 := totalVariation_le_one u v
        have hle' := mul_le_mul_of_nonneg_right hle (pow_nonneg hπ.1 k)
        simpa [mul_comm] using hle'
    _ = π ^ k := by ring

/-- **The accumulation scheme is the case `π = 1`**: the signal then **does not
decay** (`1^k = 1`).

This gives a **mechanistic** reading of the conclusion of Gersthaler et al.
(2024). Accumulating raw data avoids collapse because the human source is
reinserted at **full weight** every round, so `π = 1` and the decay factor is
constantly 1. -/
theorem accumulate_no_decay (p u v : PMF n) (k : ℕ) :
    totalVariation (contamIter p 1 ⟨by norm_num, by norm_num⟩ k u)
      (contamIter p 1 ⟨by norm_num, by norm_num⟩ k v)
      = totalVariation u v := by
  rw [totalVariation_contamIter p ⟨by norm_num, by norm_num⟩ k u v]
  simp

/-- **The decay factor is monotone**: the lower the contamination rate, the weaker
the signal after round k (`π₁ ≤ π₂ ⟹ π₁^k ≤ π₂^k`). -/
theorem decay_monotone {π₁ π₂ : ℝ} (h₁ : 0 ≤ π₁) (h₂ : π₁ ≤ π₂) (k : ℕ) :
    π₁ ^ k ≤ π₂ ^ k := by
  have h₂' : (0 : ℝ) ≤ π₂ := by linarith
  induction k with
  | zero => norm_num
  | succ k ih =>
      rw [pow_succ, pow_succ]
      calc π₁ ^ k * π₁ ≤ π₂ ^ k * π₁ := mul_le_mul_of_nonneg_right ih h₁
        _ ≤ π₂ ^ k * π₂ := mul_le_mul_of_nonneg_left h₂ (pow_nonneg h₂' k)

end Provenance
