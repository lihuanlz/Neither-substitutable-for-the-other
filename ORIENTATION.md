# Orientation

This repository is a Lean formalization. This file is not. It exists for readers
who want the usable part and have no intention of opening a `.lean` file.

The theorems are the floor of the argument, not its opening. They settle
disputes that prose leaves open. They do not tell you what to do on a Tuesday
afternoon. Both halves are here, in that order.

Every claim below is backed by a machine-checked theorem in `Provenance/`, named
inline. Nothing in this file is asserted on its own authority.

---

## 1. Four separations

Most of the damage done by over-reading AI output comes from collapsing one of
these four pairs. Each one has a theorem behind it.

### 1.1 Something either beats what you already have, or it is worth exactly zero

`Corpus.floorOf_insert_ge` and `Corpus.floorOf_insert_lt` split all cases in
two. An item that does not strictly beat the incumbent floor leaves the
certifiable bound numerically unchanged. Not approximately unchanged, not
slightly reduced. Unchanged.

There is no middle setting, and there is no partial credit. `Refinement`'s
`no_gain_without_floor_drop` says the same thing about gain rather than bound.

The working form: *does this beat what we already had?* is the only question.
Anything softer than that question will produce a softer answer.

### 1.2 Bulk does not buy what one good item buys

`Corpus.floor_determines_bound` fixes the attainable bound to the floor alone,
regardless of corpus size, composition, recency, or provenance.
`Corpus.noise_cannot_beat_signal` says the same from the other direction:
material that fails to improve the floor adds nothing, however much of it there
is. `Fragmentation.marginal_agent_pure_waste` is the headcount case: the
N-th member earns exactly zero and costs strictly more each time.

This is why `floor_determines_bound` is not a statement about corpora being
small. It is a statement about there being one number in the corpus that matters,
and about not being able to tell which one it is without something outside the
corpus.

### 1.3 More inference stops paying. Moving the floor does not.

`Refinement.ai_total_gain_bounded` caps the machine side at `log(e0/Φ)`,
independent of steps. `Refinement.human_gain_unbounded` shows the other side
has no such cap. `Refinement.ai_budget_grows_when_floor_drops` puts the
direction on it: if Φ does not fall, no amount of additional machine strength
converts into additional budget.

The reading that gets people into trouble is "the machine is getting better, so
the human contribution matters less." The theorem is about a different
dependency. The machine's usable budget is downstream of a floor move. Strength
spent without a floor move is not converted into anything.

### 1.4 A score from a judge is a measurement, and its reliability is knowable

`HypothesisTest.power_le_tv` puts an upper bound on the power of any test, and
`HypothesisTest.no_threshold_escapes_tv` says no threshold test escapes that
bound. `Calibration.sign_not_identified` is the sharper one: the *sign* of an
estimated quantity depends on a bar fitted outside the distribution being
scored.

So a difference reported by an automatic judge is a measurement with a stated
reliability, not a fact. Two things follow, both practical:

- Get a second measurement of a different shape before believing a small
  difference. A different model scoring the same artefacts is not a different
  shape; a human reading them is.
- When the two disagree about sign, the correct output is "indeterminate," not
  the larger number. This is not hedging. It is the finding.

---

## 2. Reading a headline result

The four separations above are not academic. This is the procedure applied to a
real published result, worked end to end.

The subject is *IdeaScientist: Orchestrating Agents for Grounded Scientific
Ideation* (Liu et al., arXiv:2610.04074v2, October 2026). Its own headline: on
a 27B open backbone it outperforms the strongest open-source autoresearch
baseline by 14.0%.

**Is the system real?** Yes. Its advantage on cross-domain novelty is roughly
50 points over the baselines on that axis, far beyond any plausible judge noise.
Its best-ever claim is not in doubt.

**What is the number measuring?** A score assigned by an LLM judge on
novelty and six peer-review dimensions. On their own figure, two human
annotators agree with each other at r = 0.39 on individual proposals. The
judges correlate with the human average at r = 0.37 to 0.59. That is the
reliability figure for the instrument, and it belongs next to the 14.0%.

**Does a second measurement agree?** On the single most important comparison,
no. The LLM judge ranks IdeaScientist above DeepScientist by 14 points. Blind
human pairwise evaluation of the same two systems, on matched papers, gives
IdeaScientist a 43% win rate. The sign of the paper's headline quantity flips
between two instruments. Section 1.4 says what to do with that, and the paper
does something reasonable: it reports the disagreement rather than burying it.

**Does it generate things the literature does not contain?** Partly, and the
paper measures this itself with a good instrument. They let a second process
derive candidate mechanisms from the prior literature while blind to the
proposal, then asked whether any candidate reaches the proposal's mechanism.
On a four-level scale where `trivial combination` is 0 and `surprising` is 1,
their system scores about 0.36, i.e. the "routine extension" level. Most of the
time, an independent process reading the same literature gets most of the way
there.

**Where is the genuine increment?** Cross-domain retrieval. Same-domain
retrieval scores 0.363 on in-domain novelty; cross-domain retrieval scores 0.670.
That is not re-derivation. It is the one result in the paper that is neither a
judge artefact nor a re-derivation, and it is the result worth building on.

**Three things it does not establish.**

1. Whether staged decomposition beats a single agent given equal compute. The
   pipeline spends roughly 190k output tokens per proposal; the baselines run
   their own native loops and were not held to any budget. Their own sweep shows
   that raising the turn budget lifts the score, so decomposition and compute
   are confounded. One more arm settles it.
2. Whether the human-applied part of the pipeline matters. The problem statement
   fed to the system is reconstructed from a real paper with results masked. A
   human decided the problem was worth solving and handed over the framing. This
   is not a flaw; it is the regime the framework calls favourable, and the
   regime it calls hard is untouched.
3. Whether the corpus can be exhausted. More items certify more only if one of
   them beats the floor. No vault-size ablation exists, which is an odd omission
   for a claim the theory predicts will come out flat.

**The summary line.** This is a competent piece of engineering presented as a
result about scientific discovery. The engineering has value. The framing
overstates it. The increment that survives scrutiny is cross-domain transfer, and
that one is worth a week of anyone's time.

---

## 3. What this framework does not settle

Stated here because a reader who finds these gaps has found something real.

**Who moves the floor is not in any theorem.** `ai_budget_grows_when_floor_drops`
has hypotheses on positivity and one strict inequality between two floors. There
is no hypothesis naming a source. The claim that only a human can move it lives
in the docstring, not in the statement. Anyone relying on the asymmetry as a
result about agents is relying on prose.

**New layers cannot be represented.** `Evidence` is a `Finset ℝ`, `Coalition` is
a `Finset ℝ`, and `reach` is the minimum. Everything is a comparison of depth on
one scale. Moving a mechanism from one domain to another is not "deeper" on that
scale, it is a different scale. Cross-domain transfer, which is the live result
in the worked example above, is outside what the model can say anything about.
Not refuted, not supported. Silent.

**The max-type merge is an assumption.** `Fragmentation` takes the coalition
result as the best individual with every other member contributing zero. That
is a stronger claim than a discounted merge and it is not proven here. The file
says so and names it as a falsification point. Take it at face value: if two
people together beat the better of them, that assumption is wrong.

**Corpus as a set.** No recency, no duplication, no weighting. Nothing says the
strongest item is reachable or weighted up when found.

**No empirical result.** Every theorem here is about the model, not about
anything measured. An experiment program that would test it has been written
down, including the corpus-construction tooling, but it is not published from
this repository and has not been run.

---

## 4. Checking any of it

```powershell
lake build
python tools\audit_axioms.py                     # axiom dependencies for all 164 declarations
python tools\check_metadata.py                   # citation files and README agreement
python tools\contamination_budget.py --verify    # the arithmetic still matches Contamination.lean
```

The axiom audit resolves every declaration against `Classical.choice`,
`Quot.sound` and `propext`, and nothing else. It runs in CI on every push. A
passing build only says the kernel accepted the proofs; the audit is what stops
a claim from being quietly weakened by a `sorry`.

For the formal record, see the citation block in [`README.md`](README.md).

---

## 5. One habit worth forming

The framework is a set of prohibitions: do not read headcount as capability, do
not read corpus size as coverage, do not read a judge's number as a fact, do not
read provenance as evidence.

Prohibitions are half of it. The other half came out of the worked example above
and is not in any theorem: when two instruments disagree about sign, go get a
third one of a different shape, and report indeterminate if it does not settle
it. That is a procedure, not a prohibition, and it is the part that survives
contact with a headline result.

---

## Reference

The one work cited above, in full, so it can be checked rather than taken on
trust:

Liu, J., Tao, R., Liao, Y., Jin, C., Sun, K., Yang, X., Zhang, X., Chen, X.,
Huang, Z., Zhang, L., Yang, Y., He, Y., Xuan, W., Wanga, R., Kumar, A.,
Diab, M. T., Yih, W. & Dong, X. L. *IdeaScientist: Orchestrating Agents for
Grounded Scientific Ideation*. arXiv:2610.04074v2 (2026).
https://doi.org/10.48550/arXiv.2610.04074
