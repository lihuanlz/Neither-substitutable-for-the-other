# A person's value is not something you can measure

> This article is not about how to detect AI-generated content.
> It is about something else: **why a detection result should not be used to measure a person.**

![Two field observers scan two birds with an instrument, and the instrument returns an identical outline for both](figures/anime/anime_01_cryptic_species.jpg)

Ecologists are looking for a bird that hides too well. Forty surveys, and they still have not heard it. They do not conclude from that the forest is empty.

---

## 1 · It never sees the whole picture

The detection rate climbs with the number of surveys and approaches 1. It never arrives.
Ecologists call this imperfect detection, and MacKenzie and colleagues put it in a textbook in 2002.

Today we treat an AI's output as the observation itself.

> A model's output is not an observation. It is a **channel with a resolution limit**.

![The identifiability ceiling: any detector's excess accuracy over chance is exactly TV/2](figures/fig1_ceiling.png)

The best detector available has an excess accuracy over chance of **exactly TV/2**.
That is not engineering falling short. It is a bound from Le Cam's two-point lemma, a classical result about telling two hypotheses apart, and the bound is **attained**, not merely approached.

In panel (a), TV = 0.40. The best available accuracy is **70%**.
Panel (c) is worse: at TV = 0.05 the ceiling on accuracy is **52.5%**. That is close to a coin toss.

![Verification rounds against the residual miss rate: geometric decay, clipped by a floor](figures/fig5_verification_floor.png)

What if you check more often? The residual does fall, as `(1−q)ᴺ`, and then it hits a floor and **stops**.

> The optimal number of rounds is `N* ≤ N₀`, and the formula for `N₀` contains **no term for reviewer reliability**.

At these parameters the ceiling sits at **3.474 rounds**. Hire someone more reliable than the last reviewer and you still cannot buy the next round.
Across the parameter grid we scanned, in **83.97%** of cases the thing holding progress back is the detector itself, not the person.

---

## 2 · It measures the wrong thing

Suppose you really do get a reading.

![Two currencies: the human contribution moves the coverage, the machine contribution compresses the residual](figures/fig3_layers.png)

What a person contributes and what a machine contributes are **not the same currency**.

| | What moves | Ceiling |
|---|---|---|
| **Human contribution** (refinement) | moves **the target itself**, Φ | no ceiling |
| **Machine contribution** (compression) | compresses **the remaining distance**, eₜ | log(e₀/Φ) |

No exchange rate turns the first into the second.

![An observer climbs a staircase of layers while a small robot beside her compresses orbs of light on a single layer, with a broken exchange arrow between them](figures/anime/anime_04_two_currencies.jpg)

---

## 3 · Influence is not value

Even if we only ask how much something moved, that is not what it is worth.

![The same person pushing the same ball with the same force: on one side it climbs toward morning light and sharpens, on the other it falls into a vortex and breaks into noise](figures/anime/anime_03_direction_matters.jpg)

**Figure 5(b) is the one worth remembering.**

![Influence and value are separable: the same |Δ| gives both +M and −M; refine and blur report the same number](figures/fig4_separable.png)

Push a claim **toward the truth**, or push it **away from the truth**. KL, mutual information and total variation return **exactly the same number** in both cases.

> The ruler measures how far you moved, not whether you moved in the right direction.

---

## 4 · It cannot fix the direction either

This is the one that bites hardest.

The leading information-theoretic measure, `φ = I(x;y)/I(y)`, is **entirely unsigned**. Every quantity inside it is a surprisal, and only the difference between two of them is used.
Its estimator, `φ̂ = 1 − τ̄/s̄`, is worse. τ̄ is not measured from this collaboration at all. It is **fitted from outside**.

![The same output reported as −0.099 and +0.169 under two calibrations](figures/fig6_sign_not_identified.png)

Same output, s̄ = 0.50.

- Calibration A (Llama-3, τ̄ = 0.5496) → **−0.099**, almost nobody was involved
- Calibration B (Mixtral, τ̄ = 0.4155) → **+0.169**, someone was involved

Not one character of the data changed. **The sign is your choice.**

A ruler that cannot fix a sign has no business grading a person.

---

## 5 · So

We have not given you an answer.

What we have given is this:

> **This question should not be answered with data.**

And it is not just talk.

> **153 Lean 4 theorems. Zero `sorry`, and no axioms beyond `Classical.choice`, `Quot.sound` and `propext`.**

The formalization is not decoration. It falsified an inequality we had written down wrong, forced a floor term into the model, and reversed two monotonicity directions we had assumed were right.

A modelling error that survives a theorem prover will probably not survive a collaborator.

---

## Coda

Not finding the bird does not mean the forest is empty.
By the same token, not finding open ground does not mean the forest is full.

An honest detector should say:

> **"I saw nothing here."**

not "there is nothing here".

---

*Technical detail, the 153 theorems and the 12 modules: see the full paper `manuscript.md` and the Lean 4 sources under `Provenance/`.*
