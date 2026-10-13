# Fragmentation: working note

This note expands §5 of the paper. It is not part of the typeset article and it
makes no new claim. Its purpose is to state the fragmentation argument at the
level of detail that §5 has to compress, so that the load-bearing assumption is
visible rather than buried.

Section references are to `paper/manuscript.md`. Theorem names are in
`Provenance/Fragmentation.lean` and can be checked with `grep`.

## The claim

Fragmentation is the claim that two separate routes to more research output
both close, and that neither of them closes because of a tuning parameter:

* adding people to a collaboration,
* holding an increment back to merge it with a later one.

What remains open is changing the layer itself, which is the human direction
of §2 and the only one in this model with no bound.

## Coordinates

A member is described by the layer `a` it reaches on its own. A lower `a` is a
better layer, because `a` is the ratio of residual to target and the target is
where you want to get. So:

```lean
abbrev Coalition := Finset ℝ
def reach (D : Coalition) (hD : D.Nonempty) : ℝ := D.min' hD
def gain (Φ : ℝ) (D : Coalition) (hD : D.Nonempty) : ℝ := Real.log (Φ / reach D hD)
def totalIndividual (Φ : ℝ) (D : Coalition) : ℝ := D.sum fun a => Real.log (Φ / a)
def Admissible (Φ : ℝ) (D : Coalition) : Prop := ∀ a ∈ D, 0 < a ∧ a ≤ Φ
```

`reach D` is a `min'` in layer coordinates and a maximum in gain coordinates.
The paper calls this a `max`-type coalition. Both descriptions are the same
statement, and the choice of `min'` here is the one place where a careless
reading flips the argument, so it is worth stating twice.

`gain` is what the coalition actually produces. `totalIndividual` is the sum of
what each member would have produced alone. The gap between them is what
collaboration spends.

## Route 1: headcount

The key step is `add_member_same_reach`:

```lean
theorem add_member_same_reach {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hnew : a ∉ D) (hreach : reach D hD ≤ a) :
    reach (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = reach D hD
```

Read the hypothesis before reading the conclusion. `hreach` says the new
member's layer is not better than the one the coalition already reaches. Given
that, the coalition's layer does not move.

From there `marginal_agent_pure_waste` gives both halves at once:

```lean
theorem marginal_agent_pure_waste ... :
    gain Φ (insert a D) ... = gain Φ D hD
      ∧ totalIndividual Φ (insert a D) = totalIndividual Φ D + Real.log (Φ / a)
```

The coalition gain is unchanged. The sum of individual gains rises by exactly
`log(Φ/a)`, which is strictly positive because `Admissible` puts `a` in
`(0, Φ]`. So the marginal member contributes nothing and costs something, and
that is a theorem rather than a remark about diminishing returns.

`waste_nonneg` and `headcount_adds_waste_only` make the accounting global: the
merge never beats the best member, and extra headcount only ever adds to the
gap.

## Route 2: time

```lean
def holdValue (vBig d : ℝ) (covered : ℝ → Prop) : ℝ :=
  if covered d then 0 else vBig
```

`covered : ℝ → Prop` is the predicate that the window has been superseded. The
paper's "coverage is absorbing, once superseded always superseded" is the
assumption that the real predicate has this shape. Under it:

* `holdValue_eq_zero_of_covered`: holding until expiry is worth exactly zero,
* `publish_dominates_when_covered`: publishing the small result now strictly
  dominates waiting,
* `holdValue_antitone`: the value of waiting does not increase with the delay.

There are two outcomes, superseded or not, and no third. That exhausts the
choice, which is why the argument is a dichotomy rather than an estimate.

## Where the two meet

```lean
theorem fragmentation_squeeze ... :
    gain Φ (insert a D) ... = gain Φ D hD
      ∧ holdValue vBig d covered = 0
```

This is the conjunction §5 quotes. It is worth noticing that it is a
conjunction of two already-proved statements and adds no new content. Its
weight is rhetorical: the paper claims both routes close, and here they do, in
one line, under the same hypotheses.

## The load-bearing assumption

Everything in Route 1 is conditional on `hreach`. If a new member reaches a
layer strictly better than the current best, `add_member_same_reach` does not
apply, the coalition gain rises, and the saturation claim is not what is
happening. The model does not say that no member ever does this. It says that
if the best member is already in the coalition, further members do not.

The other assumption is the shape of the coalition itself. `reach` takes the
best member and nothing else. If real collaboration were superadditive, so that
two people together reach a layer neither reaches alone, then the joint result
would not be the best individual and `add_member_same_reach` would be false in
its natural reading. Complementary expertise is a plausible mechanism for
exactly that, which is why §5 states the assumption rather than leaving it to
intuition. It is recorded again as a seam in §8.

## What is not decided here

* **Articulability.** Whether a tacit piece of knowledge can be written down at
  all is not representable in this model, so no filter on it can be a theorem.
* **Reachability and weighting.** The corpus is a set. Nothing says the best
  layer is actually reached, or that it is weighted up once found.
* **Positivity of Φ.** `Φ > 0` is assumed throughout the logarithmic
  decomposition and is not proved anywhere in the repository.

The first two are commitments of the model. The third is a premise the whole
currency rests on.

## How to falsify it

The claim is testable without deciding whether the formal layer is right.

The failure mode for Route 1 is a study in which team size predicts outcome
once the best member's contribution is held fixed, with the residual
predictive. Under the model that residual is zero.

The failure mode for Route 2 is a regime in which holding an increment back
raises its eventual value, which needs the window to be reopened after
expiry. The model assumes coverage is absorbing, so reopening is not available.

The failure mode for the coalition assumption is direct: two teams, matched on
the best member, where the weaker member still moves the joint result. That is
the observation §5 asks for and the one most likely to be produced by a
genuinely complementary pair.

## Cross-references

* §2 supplies the unbounded direction that `scale_by_new_layers_not_by_headcount`
  delegates to via `human_gain_unbounded`.
* §6 gives the data-axis version of the same shape, where the floor rather than
  the headcount is what saturates.
* §8 records the `max`-type coalition as a falsifiable assumption, alongside the
  positivity of Φ and the observational status of the 2026 evidence.
