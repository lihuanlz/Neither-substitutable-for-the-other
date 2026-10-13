# Two saturating operators: non-substitutability of human and machine contribution in AI-assisted discovery

**Authors.** Huan Li ([ORCID 0009-0004-2695-6825](https://orcid.org/0009-0004-2695-6825))
**Affiliations.** Independent Researcher
**Correspondence.** Huan Li, lihuanlz@163.com
**DOI.** [10.5281/zenodo.23321578](https://doi.org/10.5281/zenodo.23321578)

---

## Abstract

Humans and AI systems are usually placed on one capability curve and asked who is ahead. That framing has no formal content, and it produces the wrong policy advice. The two parties act on different variables, and each saturates on a different axis.

We formalize the alternative. A machine, holding the hypothesis space fixed, compresses the residual toward a floor it cannot pass: the total gain is bounded by `log(e₀/Φ)` and does not improve with more inference steps. A human, holding the hypothesis space fixed, moves the floor itself, and the gain from doing so is unbounded. Two further saturations fall out of the same currency. Headcount saturates immediately — under a max-type coalition the N+1th member's gain is exactly zero while its cost is exactly `log(Φ/a)` [Eq. 13]. And corpus size saturates too: dilution invariance says only the single item certifying the lowest floor determines the attainable bound, and a corpus whose published items are all bounded below by `c` can never certify a floor below `c` [Eq. 15], whatever its length.

Three layers of content-level and system-level mathematics sit underneath, and they are what make the claim checkable rather than rhetorical. Total variation is the exact maximal discriminability available to any detector, so verification effort has a floor that no amount of reviewer diligence lowers. The truth is an equivalence class induced by the observation protocol, which splits human and machine contribution into two currencies with no monotone exchange rate between them. And the sign of the leading information-theoretic measure of human contribution is not identified: the same output is reported as −0.099 under one calibration and +0.169 under another.

All 153 theorems and 20 worked examples are machine-checked in Lean 4 (v4.15.0) against Mathlib, with zero `sorry` and zero admitted axioms beyond `Classical.choice`, `Quot.sound` and `propext`.

---

## 1. The claim

The useful question about AI in science is not whether the machine has become good at the work. It is which part of the work it is good at, and what that leaves unclaimed. Answering that requires separating two operations that are routinely run together and priced in the same currency.

A machine that has been shown a mechanism hypothesis compresses the distance between the current estimate and the best estimate the protocol can certify. That is a bounded operation: the floor is set by the protocol, and no amount of sampling, ensembling, or calibration crosses it.

A human who notices that the mechanism should be measured at a different resolution changes which estimates are attainable at all. That operation moves the floor, and there is no ceiling on how far it can be moved.

The two operations are not two points on a shared scale. They act on different variables, and this is why the standard question — how much of the work can be handed over — has no answer that stays stable under refinement. More of the machine's operation cannot move the quantity the human's operation acts on. The bottleneck relocates from speed to layer selection and verification, and it does not stay there.

Three consequences follow, and each is a theorem rather than a position.

- **Within a fixed hypothesis space, the machine's total contribution has a hard ceiling** that does not depend on how many steps were taken.
- **Under a max-type coalition, additional people add cost and no reach.** The N+1th member's gain is exactly zero.
- **Under corpus growth, only floor-lowering material counts.** Everything else is absorbed and pays nothing.

Each has a stated falsification condition, given in §8.

## 2. Two operators, two saturation axes

Work through the layer machinery first, since the other two sections borrow its currency.

Fix an observation protocol at resolution α. It induces an equivalence relation `~_α` on states; the true state is not a point `s*` but the class `[s*]_α` of states the protocol cannot resolve. Within a layer α, the attainable estimates form a reachable set `R_α`, and the certified coverage of the true state within its class is

**Φ(α) = inf { d(ŝ, [s*]_α) : ŝ ∈ R_α }.**  [Eq. 11]

The reachable set must be restricted for this to be non-degenerate. Without that restriction one may take `ŝ ∈ [s*]_α`, obtain `Φ(α) = 0`, and every logarithmic decomposition below collapses to a triviality. We state this as a modelling commitment rather than a theorem, and return to it in §8.

Error then decomposes multiplicatively into a ceiling term and a within-layer term:

**log(1/e) = log(1/Φ) + log(Φ/e).**  [Eq. 12]

The two summands are not commensurable, and the asymmetry is exact.

*Refinement contribution* is human work that moves the certified coverage itself, `log(Φ(α)/Φ(β))`. It changes the target. Its gain is unbounded above: for any target `M ≥ 0` there are two layers with `Φ(β) ≤ Φ(α)` and `log(Φ(α)/Φ(β)) = M` (`human_gain_unbounded`).

*Within-layer compression* is machine work that moves the residual to that target, `log(e_{t−1}/e_t)`. It changes the distance to the target. Its total is bounded: if `e_N ≥ Φ` then

**log(e₀/e_N) ≤ log(e₀/Φ),**  [Eq. 13]

independently of how many steps produced `e_N` (`ai_total_gain_bounded`). This is stronger than the observation that per-step marginal gain vanishes. The per-step sum converges to a finite limit that the layer itself fixes.

`saturation_duality` places the two side by side and is the formal content of non-substitutability. Both sides saturate; the axes are different. No reweighting converts one into the other, because the bound on one side contains no variable appearing in the other. Separately, the convexity of scaling-law cost makes partial automation a long-run cost-minimizing equilibrium rather than a transitional state [17], which is an economic reason to expect the split to persist rather than close.

## 3. The content layer: what the machine's ceiling is made of

Section 2 assumed a floor. This section derives it, for the case where the two competing hypotheses are concrete distributions.

### 3.1 The best possible detector is already characterized

Let `p` and `q` be two distributions on a finite outcome space, and `TV(p,q)` their total variation distance. Any procedure returning a binary call from a sample of `p` or `q` is a statistical test. Neyman–Pearson theory already answers how far such a test can go: maximal excess accuracy over chance is exactly `TV(p,q)/2`, and minimal error probability exactly `(1 − TV(p,q))/2` [5,6]. Both bounds are attained. This is Le Cam's two-point lemma, and it is the floor `Φ` in the general case.

Two corollaries matter in practice. Reweighting, post-processing, ensembling and threshold tuning are already contained in the optimum, because the ROC geometry is fixed by `p` and `q` alone [7]. And the two-sided form `|TP − FP| ≤ TV` is the identity `J ≤ TV` for Youden's index `J = Se + Sp − 1`, not a modelling assumption [8,9].

One common error deserves a note, because it has the form of a theorem and is false. The inequality `mass(p,S) + mass(q,S) ≥ 1 + TV` fails at `S` the whole space when `p = q`, where it reads `2 ≥ 1`. The correct identity is `TP + FN = 1`.

The consequence for AI-assisted biology is severe. As a generator's output distribution converges to the reference distribution, `TV → 0` and every attainable advantage goes with it. This is conditional on a convergence assumption that Silva et al. state explicitly and, to their credit, decline to claim has already occurred [10]; conditional on it, no architecture and no quantity of calibration data changes the conclusion. Their impossibility is not a new obstruction: it follows from classical results in statistical decision theory, and the contribution of their argument is to show that the generator-cooperation requirement, not the classifier, is what makes the obstruction bite [10].

The empirical literature has paid this bill twice. Recursive paraphrase attacks drove a strong watermarked-model detector from 99.8% true-positive rate at a 1% false-positive operating point down to 9.7%, and a statistical detector from 96.5% AUROC to 25.2%, that is, to chance [11]. A single adversary suffices to defeat any watermark of a given detectability [12]. These are not failures of effort. They are the bound becoming visible.

### 3.2 Verification effort has a floor

The natural next move is to ask whether verification escapes the bound. Repeatedly checking a candidate should accumulate evidence the way repeated surveys accumulate detection probability. It accumulates, up to a floor.

Suppose a reviewer of reliability `p` inspects a candidate, a machine checks it with per-round detection probability `q`, and `N` rounds cost `c` each. The naive residual miss rate `(1 − q)^N` decays geometrically to zero, which cannot be right: a genuinely zero residual would give the verifier perfect discriminability and hence `TV = 0`. The corrected model adds an irreducible floor,

**miss rate(N) = max[ (1 − q)^N , λ·TV ].**  [Eq. 14]

Minimizing `R(N) = p·c + A·max[(1 − q)^N, T] + c·N` with `A = (1 − p)L`, `L` the loss scale and `T = λ·TV`, gives an interior optimum `N* = min(N_c, N_0)` where `N_c` is the unconstrained residual and

**N* ≤ N_0 = ln(1/(λ·TV)) / ln(1/(1 − q)),**  [Eq. 15]

a bound containing no `p`. Raising `TV` does not make review safer; it makes review cheaper, because distributions further apart saturate the verifier sooner and therefore need fewer rounds.

Dorner and colleagues prove related results in a different register, and the convergence is not ours. They show that the per-instance accuracy of verifier-driven test-time scaling is characterized by the geometry of the verifier's ROC curve, that rejection sampling and best-of-N share one large-compute limit set by the ROC slope at the origin, and that high-compute performance cannot be predicted from low-compute observations [13, Propositions 2, 3 and 7, Theorem 1]. Three differences remain. They characterize accuracy *at a given compute* `C` and never optimize over the budget, so no finite optimal round count appears in their analysis; in the regime that matters their compute cost `C(F)` diverges as `F` approaches zero. Their free parameters are the generator's initial accuracy `π` and the ROC curve, with no parameter anywhere for the reliability of a human reviewer. And their plateau depends jointly on `π` and `T′(0)`, whereas `T = λ·TV` is the separability of the two hypotheses and is independent of who performs the verification.

### 3.3 An instantiation

Cryptic sister species give the cleanest field demonstration. Two species may be separable by one fixed nucleotide, by one courtship call, or by nothing a given survey protocol can register. The first case is a fact about the organisms, the last a fact about the protocol, and the literature is careful to say which. Where two species differ only in features the protocol cannot register, they are not "the same species"; they are operationally equivalent for that survey. The same structure recurs across modern biology. Environmental DNA surveys trade sequence-discriminating power against a contamination-driven false-positive rate and a detection-driven false-negative rate. Homology modelling can leave a backbone well constrained while a functionally critical loop is not, and a confidence metric does not make the unconstrained region less so.

## 4. The system layer: why the two currencies are separate

### 4.1 Truth is an equivalence class

Under an observation protocol with equivalence relation `~_α`, the true state is the class `[s*]_α`, not a point. This is standard in representation learning, where observability is characterized by a quotient `H/ker(Π)` [14,15] and by observation-induced equivalence in statistical experiments [16], and in survey design, where occupancy is a latent state and detection the observation model [1]. We take no novelty claim for the quotient itself. The consequence is unglamorous: a resolution limit is not fixed by acquiring more of the same observable, only by changing the observable.

### 4.2 The sign of a credit measure is not identified

The sharpest formal statement concerns the measures now proposed for human contribution. The leading operational proposal is information-theoretic: human contribution is the proportion `φ = I(x;y)/I(y)` of the self-information of the output shared with the human input, with `I(x;y) = I(y) − I(y∣x)` and `I(y) = −log p_θ(y)` [18, Definition 1]. The measure is carefully validated. It tracks engineered levels of human input across four domains and six models, and agrees with pairwise human annotation on 95.9% of 1,500 pairs.

It is also, by construction, entirely unsigned. Every quantity entering it is a surprisal, `I(y) ≥ 0` and `I(y∣x) ≥ 0`, and their difference is the only quantity used. There is no notion of direction in the definition and no hypothesis class in which the ratio would be well-posed.

We should be exact about what follows, because it is less dramatic than it first appears. The authors do not claim otherwise. Their limitations section states that the framework measures *informational* contribution, that "informational contribution should not be directly equated with creativity or originality," that it is not "a normative judgment about creative value or authorship," and that human editing may carry creative input it does not capture [18]. Their results are reported over settings in which measured human contribution ranges down to minimal or negligible human contribution [18, section 5.5]. The measure is not wrong for its stated purpose. What the separability result adds is a theorem where they supply a sentence: the caveat is an axiom-level property of the whole class, so the measure cannot be extended into credit accounting or originality adjudication by recalibration. Only a signed definition does that.

Rewriting their estimator exposes a sharper problem than the negatives. Their Equation (10), `φ̂ = (I(y) + N log τ)/I(y)`, reduces to

**φ̂ = 1 − τ̄/s̄,**  [Eq. 16]

where `τ̄ = −log τ` is the plausibility bar and `s̄ = I(y)/N` the mean per-token unconditional surprisal. Two consequences follow. `φ̂` is a function of the output alone — the human input does not appear — and it is unbounded below as `y` grows more predictable, so the `[0,1]` reading does not survive in the estimation variant. And its sign is `φ̂ < 0 ⟺ s̄ < τ̄`, where `τ̄` is fitted rather than measured: the authors set `−log τ` to the empirical mean plus one standard deviation of conditional surprisal over 2,500 WildChat prompts, giving 0.5496 for Llama-3 and 0.4155 for Mixtral [18, §A.5].

The only sign this framework can report is therefore set by a nuisance parameter estimated out of distribution. The same output is evidence of contribution under one calibration and evidence against it under another. `sign_not_identified` exhibits two calibrations that flip the reported sign for any output; `sign_not_identified_exact` pins the witnesses to bars at half and one-and-a-half times the output's mean surprisal. The apparent sign is a property of the calibration, not of the collaboration.

More generally, every reflection-invariant measure — KL, mutual information, total variation, Jensen–Shannon — has this blind spot as a property of the class rather than of an implementation. An author who moves a claim toward the truth and one who moves it toward an equally plausible falsehood produce identical mutual information with the text. `influence_value_separable` makes this exact: for any `M > 0` there are processes with identical `|influence|` between two states whose signed value is `+M`, and processes with the same `|influence|` whose value is `−M`.

This also refutes the natural first attempt at a within-layer sensitivity function, `H(x) = |δΦ/δx|`. Taking an absolute value identifies refinement with coarsening, so the instrument cannot distinguish an author who sharpened a mechanism model from one who blurred it, and reports zero for both.

The fix is a signed definition fixed in advance, on order-preserving, additive, unit-fixing maps over a signed domain rather than arbitrary monotone transforms. Under that restriction the impossibility sharpens: when the floor binds, reviewers of different reliability produce *identical* optimal verification effort, and no monotone exchange rate between human bits and machine rounds survives. When it does not bind, the two are exponentially but not linearly related, `exp(d·N*) = A·d/c`. "Fully incommensurable" overstates that second regime; "not linearly convertible" is exact.

## 5. Saturation on the human axis: headcount

Section 2 saturates the human operator in one direction — the floor, across layers. It says nothing about the other direction, people. The obvious hope is that more researchers compress that axis, the way more inference steps compress the machine's. They do not.

Model a collaboration as the set of layers its members reach independently, with the joint result taken as the best of them. This is a `max`-type coalition, and it is a stronger claim than a discounted merge: it asserts that the merge is *exactly* the best individual and that every other member contributes exactly zero.

Under that model, `add_member_same_reach` and `gain_eq_best_member` give the reach and the gain of the coalition as those of its best member. The consequence is the theorem the topic turns on:

**marginal_agent_pure_waste: gain(Φ, D ∪ {a}) = gain(Φ, D), and totalIndividual(Φ, D ∪ {a}) = totalIndividual(Φ, D) + log(Φ/a).**  [Eq. 17]

The N+1th person earns exactly zero and costs exactly `log(Φ/a)`. Define the waste as the difference, `waste = totalIndividual − gain`. Then `waste_nonneg` and `headcount_adds_waste_only` say the merge never produces more than the best individual, and headcount only adds waste.

The time axis behaves the same way. Holding an increment back is not an option in the usual sense: let `holdValue vBig d covered` be `0` if the window is superseded by the time `d` arrives and `vBig` otherwise. Coverage is absorbing — once superseded, always superseded — so `holdValue_antitone` says the value of waiting is non-increasing in the delay, and `publish_dominates_when_covered` says that once superseded, publishing the small result immediately strictly dominates. There are two outcomes, "not yet superseded" and "already superseded", and no third.

`fragmentation_squeeze` closes both routes at once, and `scale_by_new_layers_not_by_headcount` names the remaining exit: scale by changing the layer, which is the unbounded direction of §2.

The `max` assumption is the load-bearing part, and it is falsifiable in one move. If real collaboration is superadditive — if two people together reach a layer neither reaches alone, as complementary expertise plausibly suggests — then `add_member_same_reach` fails immediately. We state the assumption because leaving it to intuition invites exactly the recombination story the model denies.

## 6. Saturation on the data axis: the corpus

The same structure reappears on the data side, and it bears directly on a common claim about the AI era: that unread knowledge will in time become training material and therefore will not be lost.

The quantity in doubt is not the size of the corpus, which grows without bound, but how much of it is usable. Model a corpus as the set of floors its individual items certify, with the certified floor the best one on offer.

**floorOf(D) = min D.**  [Eq. 18]

Then the floor is determined entirely by the best item. `floorOf_union_le_left` and `floorOf_union_le_right` say that adding a corpus changes the joint floor only through that corpus's own best item, and `floorOf_union_self_mono` covers arbitrary growth: add `n` items, none of which beats the existing floor, and the floor stays put. `floor_determines_bound` says two corpora certifying the same floor are indistinguishable whatever their size, composition or recency. This is **dilution invariance**, and it says that a corpus which is ninety-nine parts filler and one part signal certifies precisely what the one part certifies. `uninformative_corpus_gains_nothing` is `no_gain_without_floor_drop` at the corpus level: switching corpora without lowering the floor pays exactly zero.

The selection version is the sharper half. If every published item is bounded below by `c`, then

**selection_filter_caps_gain: log(e₀/e_N) ≤ log(e₀/c) for every achievable residual e_N,**  [Eq. 19]

uniformly in the residual. `corpus_size_cannot_beat_selection_floor` reads this contrapositively: no corpus, however large, certifies a floor below `c` if none of its items does. Corpus growth is unbounded; the floor it can certify is not.

So the two halves of the usual claim come apart. Everything articulable does eventually enter the corpus. Whether it enters the usable part is settled by whether it lowers the floor, and that is a property of the item, not of its volume.

Two things are deliberately left out, and the omissions are the point. Whether a given artefact is articulable at all is not representable at this level, so the tacit-knowledge filter cannot be stated as a theorem. And the corpus is modelled as a set; nothing here says the best item is reachable, or that it is weighted up once found. Those are commitments, recorded in §8.

## 7. What the 2026 evidence supports, and what it does not

The formal claims above make predictions, and the empirical literature of 2026 bears on them unevenly. We separate what is supported from what is merely consistent.

**Support for the two-axis claim.** A study of 41.3 million papers, of which roughly 311,000 were AI-augmented under an LM classifier scoring F1 = 0.875, found that AI-augmented work produces 3.02× the papers, 4.84× the citations, and reaches project-leader status 1.37 years earlier — while collective topic volume contracts 4.63% and researcher-to-researcher interaction falls 22%, with more than 70% of 200-odd subfields contracting [19]. Output rising while interaction falls is the signature of one axis saturating while the other does not.

**Support for the missing human operation.** The operation this project performs is the construction of null hypotheses, counter-examples and non-identifiability witnesses. An evaluation of 121,640 preprints by 6,749 responding scientists found that non-reasoning models collapse into a narrow "hivemind" of similar ideas, that reasoning models roam wider, and that **no model class spontaneously proposes a null hypothesis**, a move human researchers make freely; an analysis of 39 million papers from 2010 to 2025 further finds that null claims are sharply suppressed and ideas contract after the release of ChatGPT [20]. A companion benchmark shows LLM judges rating model-generated research questions as highly novel while domain experts prefer author-anchored questions [21], which is what a missing human filter looks like from the inside.

**The boundary of verification.** The verification layer itself has largely saturated. An autonomous system resolved nine open Erdős problems in one sweep, including one open for 56 years, and proved 44 previously unproved OEIS conjectures, all machine-checked, at an inference cost in the hundreds of dollars [22]. A separate effort produced roughly 13 million lines of Lean formalizing Fermat's Last Theorem, against about 2.5 million lines for all of Mathlib. Read against §6, this is what a saturated verification layer looks like: the volume is no longer the constraint, while the third-party assessment of that same effort records code far longer than necessary, not in a form suitable for reuse, whose statements repackage the literature rather than translate it [23]. The translation and reuse layers did not saturate with the verification layer.

**Where the evidence stops.** None of the above is causal. The 2026 corpus study uses an LM classifier whose 12.5% error rate enters every proportion reported, and paper-level tool use is correlated with output without random assignment and without excluding self-selection. It is observational. It is consistent with the two-operator claim and it does not establish it.

## 8. Modelling commitments

Three seams separate the formal layer from the empirical layer. They are of different kinds and should not be conflated.

**The floor's positivity is assumed, not proved.** `Φ > 0` requires the reachable set to be a proper restriction, and no theorem here establishes that. At the type level there is no representation of unbounded reachability, so this stays a modelling commitment. The entire logarithmic decomposition depends on it.

**The coalition is `max`-type.** Stated in §5 and falsifiable there. Real superadditive collaboration would falsify `add_member_same_reach` outright.

**The empirical record is observational.** Stated in §7. The three seams are respectively an unprovable premise, a falsifiable assumption, and a limitation of identification strategy. Reporting only the first two would overstate what has been shown.

Two further commitments attach to §6: articulability is not represented, and the corpus is a set rather than a stream with recency and re-weighting.

## 9. Formalization

All results are stated and proved in Lean 4 (toolchain `leanprover/lean4:v4.15.0`) against Mathlib, on finite probability spaces, across twelve modules: total variation and its properties; Bayesian-optimal detection and error rate; contamination as repeated TV mixing; coverage monotonicity, submodularity and diminishing marginal returns; a hypothesis-testing module consolidating mass-sum identities and the TV bounds; a refinement module separating layer-crossing from within-layer gains; a value module establishing the separability lemma; a verification-budget module; an incommensurability module fixing the utility class; a calibration module proving the sign of the minimum-contribution estimator is not identified; a fragmentation module formalizing coalition and holding-window saturation; and a corpus module formalizing dilution invariance and selection filters. Finite probability spaces are modelled as `structure PMF (n : ℕ)`; total variation is the maximum over events of the absolute mass difference, with the two-sided bounds proved by summation over a partition rather than by appeal to the general theory.

The formalization is not decoration. It falsified the confusion-matrix inequality in §3.1, forced the residual term in §3.2 to carry a TV floor, reversed two monotonicity directions we had asserted, and turned the separability claim into a theorem. It also caught one of our own claims as false on first attempt: the composition of a selection filter with corpus dilution requires a hypothesis on the first corpus as well, because otherwise the first corpus may already sit below the threshold.

---

## Figure legends

**Figure 1 | The two operators.** (a) The observation protocol induces an equivalence class `[s*]_α`; certified coverage Φ(α) is a property of the class, not of a point. (b) Refinement (human, cross-layer) moves Φ itself and has unbounded gain; within-layer compression (machine) reduces the residual `e_t` to Φ and is capped at `log(e₀/Φ)`. (c) The two curves have different shapes, which is what makes them non-convertible.

**Figure 2 | The identifiability ceiling.** (a) Every test of two hypotheses `p` and `q` is bounded by Le Cam's two-point lemma: the excess accuracy over chance is exactly `TV(p,q)/2`, and the error rate is exactly `(1 − TV)/2`. Both bounds are attained, so no detector can exceed the curve. (b) The two-sided form `|TP − FP| ≤ TV` is the identity `J ≤ TV` for Youden's index `J = Se + Sp − 1`; the geometry is fixed by `p` and `q` alone, leaving threshold choice no freedom. (c) As a generator's distribution converges to the reference distribution, `TV → 0` and attainable advantage → 0, independently of detector architecture.

**Figure 3 | Verification effort has a floor.** Residual miss rate as a function of the number of verification rounds. Geometric decay `(1 − q)^N` (dotted) is clipped at the floor `T = λ·TV` (dashed), giving the maximum of the two (solid). The cost-minimizing budget `N*` is the smaller of the unconstrained optimum `N_c` and the `p`-independent cap `N_0 = ln(1/(λ·TV))/ln(1/(1−q))` (vertical markers). Increasing reviewer reliability `p` lowers `N*` only while the floor is slack; once `T ≥ x_c`, `N*` is pinned at `N_0` and further reviewer quality buys nothing. Parameters: TV = 0.09, q = 0.5, λ = 1, where `N_c = 3.793` and `N_0 = 3.474`, and the floor is the active constraint in 83.97% of the scanned parameter combinations.

**Figure 4 | The sign of a credit measure is not identified.** The estimated contribution `φ̂ = 1 − τ̄/s̄` plotted as the plausibility bar `τ̄` moves through its plausible range. The estimator is a function of the output alone and the bar is fitted out of distribution, so the same output crosses zero: Llama-3 reports `−0.099` at `τ̄ = 0.5496` and Mixtral reports `+0.169` at `τ̄ = 0.4155`. The sign-flipping witnesses are pinned at `τ = s/2` and `τ = 3s/2`.

**Figure 5 | Influence and value are separable.** For any `M > 0` there exist processes with identical `|influence|` between two states α and β whose signed value is `+M`, and processes with the same `|influence|` whose value is `−M`. The horizontal coordinate (magnitude of change) is identical across all four cases; the vertical coordinate (signed contribution) is not determined by it. Any reflection-invariant measure — KL, mutual information, total variation, Jensen–Shannon — is blind to this split.

**Figure 6 | Headcount saturates immediately.** (a) Coalition gain is flat in the number of members while the summed individual gain grows linearly; the band between them is pure waste. (b) The marginal gain of every member after the best one is exactly zero. (c) Under a max-type coalition the best member alone sets the outcome, for every candidate floor.

**Figure 7 | Corpus growth saturates too.** (a) The certified floor is set by the single best item, not by how many items exist: adding items that do not lower the floor leaves it pinned at `c = 0.20`. (b) Dilution invariance: the floor a corpus certifies stays constant as items are absorbed one by one, so 99 filler items and 1 signal item certify exactly what the signal item certifies. (c) For a fixed corpus size of 100 items the certified floor is `0.20` when the corpus holds 1, 50 or 100 good items, and `0.40` when it holds none. The green line marks a selection floor that no amount of growth can cross.

---

## Visual summary (for a general audience)

A four-panel illustrated series accompanies this article. All four panels use the same character and the same palette so that they read as a single sequence.

**VS1 | Two birds, one signal.** A field ecologist sights two songbirds through an instrument. The instrument returns a glowing outline for each, and the two outlines are identical; a dashed line joins them. The two organisms differ. The measurement does not. This is total variation distance equal to the sum of the mass the protocol cannot resolve, and it sets the ceiling on every detector that will ever be pointed at them.

**VS2 | Survey harder, resolve no further.** Four superimposed copies of the ecologist scan the same valley in sequence. Every scan beam travels a long way and is then clipped by a luminous horizontal barrier. Two bird silhouettes sit above the barrier, at a fixed separation, no matter how many scans are added. This is the verification floor: residual miss rate decays as `(1 − q)^N` and is then cut off at `λ·TV`, so the optimal number of rounds is capped at a value that contains no term for reviewer reliability.

**VS3 | Same push, opposite direction.** The character appears twice in identical pose, moving an identical glowing sphere with identical effort. On the left the sphere climbs toward a warm dawn and sharpens into precision. On the right the sphere falls into a dark vortex and dissolves into noise. Magnitude is held constant; only direction changes. Every unsigned measure — mutual information, KL, total variation — assigns both cases the same number.

**VS4 | Two currencies, no exchange rate.** The ecologist climbs a staircase of stacked glass layers, each layer a further resolution, her hand trailing light across each one. Beside her, a small robot compresses a cluster of glowing orbs along a single flat layer toward a fixed amber target. Between the staircase and the flat layer, an exchange arrow has broken into drifting fragments. Refinement moves the target and is unbounded; compression moves the residual and is capped at `log(e₀/Φ)`. No monotone rate converts one into the other.

---

## Methods

The mathematical development was carried out in Lean 4 against Mathlib and organized as twelve modules, listed in §9. Prose specifications live alongside the proofs as docstrings in the sources themselves, so the statement of every theorem, its hypotheses, and the modelling commitments behind it are read from the same artifact that is typechecked. The public repository builds in a clean container: `lake update`, `lake exe cache get`, `lake build`. A CI workflow runs the build, an axiom audit over every declaration in the package, and a consistency check against the manuscript.

The axiom audit is the substantive gate. It enumerates the axioms reachable from each of the package's declarations and fails on anything beyond `Classical.choice`, `Quot.sound` and `propext`. In particular it fails on `sorryAx`, which is how an incomplete proof would otherwise pass unnoticed.

Provenance search was conducted against the published literature on AI-text detection impossibility, information-theoretic measures of human contribution, verifier-robustness theory, and observation quotients in representation learning. Every digital object identifier reported here was resolved at the time of writing; where an identifier could not be resolved, none is given. Full texts rather than abstracts were read for references 10, 13, 17, 18, 20, 21 and 23, including appendices. Two corrections resulted from reading the sources rather than their summaries. The agreement rate of reference 18 is 95.93% of 1,500 pairs; a figure of 97.4% circulating in secondary coverage does not appear in the paper and is not used here. The large-compute limit of reference 13 is `T′(0)·π / (T′(0)·π + 1 − π)`, depending jointly on the generator's initial accuracy and the ROC slope, as stated in its Proposition 2.

---

## References

1. MacKenzie, D. I., Nichols, J. D., Lachman, G. B., Droege, S., Royle, J. A. & Langtimm, C. A. Estimating site occupancy rates when detection probabilities are less than one. *Ecology* **83**, 2248–2255 (2002). https://doi.org/10.1890/0012-9658(2002)083[2248:ESORWD]2.0.CO;2
2. Royle, J. A. & Dorazio, R. J. *Inference and Change of Detection in a Changing World* (Princeton University Press, 2008).
3. Tyre, J. C., Tenhumberg, B., Field, S. A., Niejalke, D., Parris, K. & Possingham, H. P. Improving precision and reducing bias in biological surveys: estimating false-negative error rates. *Ecological Applications* **13**, 1790–1801 (2003).
4. MacKenzie, D. I., Nichols, J. D., Hines, J. E., Knutson, M. G. & Franklin, A. B. Estimating site occupancy, colonization, and local extinction when a species is detected imperfectly. *Ecology* **84**, 2200–2207 (2003). https://doi.org/10.1890/02-3090
5. Neyman, J. & Pearson, E. S. On the two problem of the most powerful tests of statistical hypotheses and the principles of scientific inference. *Philosophical Transactions of the Royal Society A* **231**, 289–337 (1933).
6. Le Cam, L. *Statistical Methods for Researchers* (University of California Press, 1990).
7. Cover, T. M. & Thomas, J. A. *Elements of Information Theory*, 2nd ed. (Wiley, 2006).
8. Peirce, C. S. The logic of scientific judgment. *Journal of Analytical Chemistry* **18**, 389–395 (1884).
9. Youden, W. J. Index for rating diagnostic tests. *Cancer* **3**, 32–35 (1950). https://doi.org/10.1002/1097-0142(1950)3:1<32::AID-CNCR2820030106>3.0.CO;2-3
10. Silva, D. W. *Indistinguishable by Design: On the Impossibility of AI Text Detection Without Generator Cooperation*. Preprint, Zenodo (2026). https://doi.org/10.5281/zenodo.18714018
11. Sadasivan, V., Dubey, S., Cantor, E. & Wiecek, B. Can AI-generated text be reliably detected? Preprint, arXiv:2303.11156 (2023). https://doi.org/10.48550/arXiv.2303.11156
12. Kirchenbauer, J. et al. A watermark for large language models. *Proceedings of the 58th International Conference on Machine Learning* (2021). https://doi.org/10.48550/arXiv.2301.10226
13. Dorner, F. E., Chen, Y., Cruz, A. F. & Yang, F. ROC-n-reroll: how verifier imperfection affects test-time scaling. Preprint, arXiv:2507.12399 (2025; rev. 2026). https://doi.org/10.48550/arXiv.2507.12399
14. Ishii, K., Gautam, B. P., Wu, J. & Saher, J. Platonic projection structures: operator-induced observability in representation learning. *Entropy* **28**, 768 (2026). https://doi.org/10.3390/e28070768
15. Rada, M. *Resolution Geometry of Observation Systems*. Preprint, Zenodo (2026). https://doi.org/10.5281/zenodo.21928119
16. Jiao, Y., Ho, P.-H., Peng, L. & Miao, Y. Task-aware identifiability: observation quotients, statistical geometry, and representation accessibility. Preprint, arXiv:2601.21584 (2026). https://doi.org/10.48550/arXiv.2601.21584
17. Li, W., Aboutorabi, A., Lyu, H., Qian, K., Fleming, M., Goehring, B. C. & Thompson, N. Economics of human and AI collaboration: when is partial automation more attractive than full automation? Preprint, arXiv:2603.29121 (2026). https://doi.org/10.48550/arXiv.2603.29121
18. Xie, Y., Qi, T., Yi, J., Yang, X., Whalen, R., Huang, J., Ding, Q., Xie, Y., Xie, X. & Wu, F. Measuring human contribution in AI-assisted content generation. In *Proceedings of the 64th Annual Meeting of the Association for Computational Linguistics* (ACL, 2026), pp. 6168–6190. https://doi.org/10.18653/v1/2026.acl-long.279
19. Hao, Q., Xu, F., Li, Y. & Evans, J. Artificial intelligence tools expand scientists' impact but contract science's focus. *Nature* **649**, 1237–1243 (2026). https://doi.org/10.1038/s41586-025-09922-y
20. Bao, H., Wu, S., Liu, X., Li, S., Cao, S. & Evans, J. Contemporary AI lacks the imagination to diverge or negate in science. Preprint, arXiv:2606.08251 (2026). https://doi.org/10.48550/arXiv.2606.08251
21. Sinhahajari, S., Majumder, N. & Poria, S. On the limits of LLM-as-judge for scientific novelty assessment. Preprint, arXiv:2606.12071 (2026). https://doi.org/10.48550/arXiv.2606.12071
22. Tsoukalas, T. et al. Advancing mathematics research with AI-driven formal proof search. Preprint, arXiv:2605.22763 (2026). https://doi.org/10.48550/arXiv.2605.22763
23. Asher, J. *Formalize everything, now!* (2026). https://justinasher.me/formalize-everything-now

---

## Acknowledgements

TODO: to be supplied.

## Author contributions

The author conceived the work, developed the formalization, produced the
figures and the Word build, and wrote the paper.

## Competing interests

TODO: to be supplied.

## Code availability

All proofs, module sources and the axiom-audit and consistency-check scripts are in the public repository accompanying this article. The build reproduces from a clean container using the pinned toolchain and the vendored Mathlib revision.