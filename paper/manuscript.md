# Non-detection is not absence: identifiability limits for AI-assisted biological discovery

**Authors.** [To be assigned]
**Affiliations.** [To be assigned]
**Correspondence.** [To be assigned]

---

## Abstract

Field biologists established a quarter century ago that failure to detect a species does not establish its absence: repeated survey raises detection probability toward — but never to — one. The limit is set by the observational protocol, not by observer diligence. AI-assisted science is repeating this error at scale, treating model and detector output as ground truth rather than as a noisy channel with a hard resolution ceiling. We formalize it. The content layer shows that total variation is the exact maximal discriminability available to any detector: the best test's advantage equals TV/2, its error rate (1 − TV)/2. The same machinery applied to verification yields a floor — residual miss rate decays as (1 − q)^N but cannot fall below a multiple of TV, so the optimal number of verification rounds is capped independently of reviewer reliability. The system layer replaces the point estimate of truth with an equivalence class induced by the observation protocol, and separates signed value from unsigned influence, proving that any reflection-invariant influence measure leaves contribution direction undetermined. All 117 theorems are machine-checked in Lean 4 with zero `sorry` and zero axioms.

---

Every field ecologist learns the same lesson early. You survey a wetland for spring peepers, hear nothing, and do not conclude the wetland is empty. Survey it forty times and you still do not, because per-visit detection probability is below one and nobody knows by how much. MacKenzie and colleagues formalized this in 2002: non-detection carries no information about absence unless detection is certain, and the remedy is a likelihood model of detection, not more effort [1]. The same argument runs through monitoring design [2], false-negative rate estimation [3], and the general theory of imperfect detection [4].

AI-assisted biology is arriving at the same shore by a different route, and it is not carrying the lesson. When a language model proposes a pathway, a detector scores it, or an automated pipeline ranks candidate structures, the output is routinely treated as the observation itself. But model output is not ground truth; it is the output of a channel. It has a resolution, and that resolution is a property of the protocol, not of how hard anyone looks.

Here we treat the model-and-detector apparatus exactly as an ecologist treats a bird survey: an observation protocol with imperfect, asymmetric detectability. Several widely held intuitions about AI-assisted discovery then fail as theorems rather than as engineering problems.

### The best possible detector is already characterized, and it is weak

Let p and q be two distributions on a finite outcome space — a "reference" and an "alternative" — and TV(p, q) their total variation distance. Any procedure returning a binary call from a sample of p or q is a statistical test. Neyman–Pearson theory already answers how much such a test can achieve: maximal excess accuracy over chance is exactly TV(p, q)/2, and minimal error probability exactly (1 − TV(p, q))/2 [5,6]. Both bounds are attained, not merely approached. This is Le Cam's two-point lemma.

Two corollaries matter for biological practice. First, any attempt to sharpen the score by reweighting, post-processing, ensembling or threshold-tuning is already contained in the optimum; the ROC geometry is fixed by p and q alone [7]. Second, the two-sided form |TP − FP| ≤ TV is a statement about the Youden index J = Se + Sp − 1, and J ≤ TV is an algebraic identity, not a modelling assumption [8,9]. One common error deserves note: mass(p, S) + mass(q, S) ≤ 1 + TV is false, failing at S the whole space when p = q, where it reads 2 ≤ 1. The correct identity is TP + FN = 1.

The most explicit formalization in this line is careful to record that its core ingredients — equivalence of optimal testing advantage with total variation, Pinsker's inequality, the data processing inequality — are classical results in statistical decision theory, some dating to the 1960s, and that its contribution is the unified end-to-end chain rather than any individual link [10]. We agree, and add machine verification of that chain.

The consequence for AI-assisted biology is severe and underappreciated. As a generator's output distribution converges to the reference distribution, TV → 0 and every attainable advantage → 0. This is conditional on a convergence assumption that Silva et al. state explicitly and, to their credit, decline to claim has already occurred [10]; conditional on it, no architecture, no ensemble and no amount of calibration data changes the conclusion. Their Theorem 4.1 — that the optimal distinguishing advantage of any detector equals total variation exactly — is therefore the two-point lemma applied to a channel whose noise level is set by the training objective.

The empirical literature has already paid this bill twice. Recursive paraphrase attacks drove a strong watermarked-model detector from 99.8% true-positive rate at a 1% false-positive operating point down to 9.7%, and a statistical detector from 96.5% AUROC to 25.2% — i.e. to chance [11]. Separately, a single adversary is sufficient to defeat any watermark of a given detectability [12]. These are not failures of engineering effort. They are the TV bound becoming visible.

### Verification effort has a floor, and the floor is not lowered by being a better reviewer

The natural next move is to ask whether *verification* escapes the bound. Repeatedly checking a candidate should, one might hope, accumulate evidence the way repeated surveys accumulate detection probability. It does — up to a floor.

Suppose a reviewer of reliability p inspects a candidate, a machine checks it with per-round detection probability q, and N rounds cost c each. The naive residual miss rate (1 − q)^N decays geometrically to zero. This cannot be right: if the residual were genuinely zero the verifier would have perfect discriminability and TV would be zero. The correct model adds an irreducible floor,

miss rate(N) = max[ (1 − q)^N , λ·TV(p, q) ],

where λ ≥ 0 absorbs the fact that some confusion between the two hypotheses is not removable by re-sampling. Minimizing total cost R(N) = p·Φ + A·max[(1 − q)^N, T] + c·N, with A = (1 − p)L, L the loss scale and T = λ·TV the floor, gives an interior optimum N\* = min(N_c, N_0) where N_c = −ln(x_c)/d with x_c = c/(A·d) the unconstrained residual, and

**N\* ≤ N_0 = ln(1/(λ·TV)) / ln(1/(1 − q)),**

a bound that contains no p.

This is the formal content of "you cannot survey your way out of imperfect detection", and it has an independent recent derivation in a different register. Dorner and colleagues prove that the per-instance accuracy of verifier-driven test-time scaling is exactly characterized by the geometry of the verifier's ROC curve, that rejection sampling and best-of-N share one large-compute limit set by the ROC slope at the origin, and that performance at high compute cannot be predicted from low-compute observations [13, Propositions 2, 3 and 7, Theorem 1]. The convergence itself is therefore not ours and we do not claim it. Three differences remain. They characterize accuracy *at a given compute* C; they never optimize over the budget, so no finite optimal number of rounds appears anywhere in their analysis, and in the regime that matters their compute cost C(F) diverges as F approaches zero. Their free parameters are the generator's initial accuracy π and the ROC curve — there is no parameter anywhere in their setup for the reliability of a human reviewer. And their plateau depends jointly on π and T′(0), whereas our floor T = λ·TV is the separability of the two hypotheses and is independent of who performs the verification, so the statement that the optimal budget contains no p is not recoverable from their result. What is new here is the explicit finite cap N\* ≤ N_0, the monotonicity of N\* in TV — distributions further apart saturate the verifier sooner and so require *less* effort — and the collapse of N\* onto the constant N_0 once the floor binds. Raising TV does not make review safer; it makes review cheaper.

Two further monotonicities close the section. N\* is non-increasing in p, but strictly so only while the floor is not binding; once T ≥ x_c the bottleneck is the content layer's separability, not the reviewer's diligence. When TV = 0 the floor vanishes and one recovers the unbounded geometric formula. TV is simultaneously the ceiling on the verification budget and its only source of constraint.

### An instantiation: when two things cannot be told apart, and what it costs

Cryptic sister species are the field's cleanest demonstration. Two species may be separable by one fixed nucleotide, by one courtship call, or by nothing a given survey protocol can register. The first case is a fact about the organisms; the last is a fact about the protocol, and the literature is careful to say which. Where two species differ only in features the protocol cannot register, they are not "the same species" — they are operationally equivalent for that survey.

The same structure recurs across modern biology. Environmental DNA surveys trade sequence-discriminating power against a contamination-driven false-positive rate and a detection-driven false-negative rate. Homology modelling can leave a backbone well constrained while a functionally critical loop is not, and a confidence metric does not make the unconstrained region less so. In ion-channel work a model may be wrong about state-dependent inactivation and right about everything else.

### Truth is an equivalence class, not a point

The second layer replaces the object that the first layer bounds. Under an observation protocol with equivalence relation ~_α, the "true" state is not a point s\* but the class [s\*]_α of states the protocol cannot resolve. This is standard in representation learning, where observability is characterized by a quotient H/ker(Π) [14,15] and by observation-induced equivalence in statistical experiments [16], and in survey design, where occupancy is a latent state and detection the observation model [1]. We take no novelty claim for the quotient itself. The practical consequence is unglamorous but decisive: a resolution limit is not fixed by acquiring more of the same observable, only by changing the observable.

What we add is the layer attached to it. Within a class, Φ(α) is the coverage the protocol can certify at resolution α, and the reachable set must be non-trivial, or Φ(α) ≡ 0 and every logarithmic decomposition degenerates. On this reading, two kinds of contribution are genuinely different objects, and they should not be added in one currency:

- **Refinement contribution** — human work that moves the certified coverage itself, log[Φ(α) / Φ(β)]. This changes the target.
- **Within-layer compression** — machine work that moves the residual to that target, log[e_{t−1} / e_t]. This changes the distance to it.

The two are not commensurable, and the reason is precise. Within a layer the attainable gain is bounded by log(e₀ / Φ), a ceiling fixed by the layer itself; human refinement gains are unbounded above. Separately, the convexity of scaling-law cost makes partial automation a long-run cost-minimizing equilibrium rather than a transitional state [17]. These are different return profiles, so no monotone exchange rate converts one into the other.

### The result that should worry anyone quantifying credit

The sharpest formal statement concerns the measures now being proposed for human contribution. The leading operational proposal is information-theoretic: human contribution is defined as the proportion φ = I(x;y)/I(y) of the self-information of the output that is shared with the human input, with I(x;y) = I(y) − I(y∣x) and I(y) = −log p_θ(y) [18, Definition 1]. The measure is carefully validated: it tracks engineered levels of human input across four domains and six models, and agrees with pairwise human annotation on 95.9% of 1,500 pairs.

It is also, by construction, entirely unsigned. Every quantity entering it is a surprisal, I(y) ≥ 0 and I(y∣x) ≥ 0, and their difference is the only quantity used. There is no notion of direction anywhere in the definition, and no hypothesis class in which the ratio would be well-posed.

We should be exact, because what follows is less dramatic than it first appears. The authors do not claim otherwise: their limitations section states that the framework measures *informational* contribution, that "informational contribution should not be directly equated with creativity or originality," that it is not "a normative judgment about creative value or authorship," and that human editing may carry creative input it does not capture [18]. The measure is not wrong for its stated purpose. What the separability result adds is a theorem where they supply a sentence: the caveat is an axiom-level property of the whole class, so the measure cannot be extended into credit accounting, originality adjudication or pricing by recalibration — only by changing the definition to a signed one.

Rewriting their estimator exposes a sharper problem than the negatives themselves. Their Equation (10), φ̂ = (I(y) + N log τ)/I(y), reduces to φ̂ = 1 − τ̄/s̄, where τ̄ = −log τ is the plausibility bar and s̄ = I(y)/N the mean per-token unconditional surprisal of the output. Two consequences follow. First, φ̂ is a function of the output alone — the human input does not appear — and it is unbounded below as y grows more predictable, so the [0,1] reading of the primary measure does not survive in the estimation variant. Second, its sign is φ̂ < 0 ⟺ s̄ < τ̄, and τ̄ is not measured from the collaboration but fitted: the authors set −log τ to the empirical mean plus one standard deviation of conditional surprisal over 2,500 WildChat prompts, giving 0.5496 for Llama-3 and 0.4155 for Mixtral [18, §A.5]. The only sign this framework can report is therefore set by a nuisance parameter estimated out of distribution, and the same output is evidence of contribution under one calibration and evidence against it under another. They observe these negatives and reinterpret them — "could plausibly have been generated with minimal or negligible human contribution, under the minimal contribution assumption" [18, §5.5] — which is correct inside their own estimand. But a quantity whose zero point moves when a threshold is refitted cannot carry direction. This is the separability failure in its sharpest form: not that the measure is unsigned, but that its apparent sign is not identified. We formalize this as a theorem rather than as an objection: for every output, `sign_not_identified` exhibits two calibrations that flip the reported sign, `sign_not_identified_exact` pins the witnesses to bars at half and one-and-a-half times the output's mean surprisal, and `sign_not_identified_in_context` records the assumption that makes the point bite — that the bar is fitted out of distribution. The apparent sign is a property of the calibration, not of the collaboration.

More generally, every reflection-invariant measure — KL, mutual information, total variation, Jensen–Shannon — has this blind spot, not as an implementation defect but as a property of the class: an author who moves a claim toward the truth and one who moves it toward an equally plausible falsehood produce identical mutual information with the text. The measure returns the same number; the biology has moved in opposite directions.

This also refutes a natural first attempt at a within-layer sensitivity function, H(x) = |δΦ/δx|. Taking an absolute value identifies refinement with coarsening, so the instrument cannot distinguish an author who sharpened a mechanism model from one who blurred it, and reports zero for both.

The fix is not a better divergence but a signed definition fixed in advance. Under order-preserving, additive, unit-fixing maps on a signed domain — rather than arbitrary monotone transforms — the impossibility sharpens: when the floor binds, reviewers of different reliability produce *identical* optimal verification effort, and no monotone exchange rate between human bits and machine rounds survives. When it does not bind, the two are exponentially but not linearly related, exp(d·N\*) = A·d / c. "Fully incommensurable" overstates that second regime; "not linearly convertible" is exact.

### Formalization

All results above are stated and proved in Lean 4 (v4.15.0) with Mathlib, on finite probability spaces: 117 theorems and 20 machine-checked worked examples across nine modules, compiling with zero `sorry` and zero admitted axioms. The formalization is not decoration: it falsified the confusion-matrix inequality above, forced the residual term to carry a TV floor, reversed two monotonicity directions we had asserted, and turned the separability claim into a theorem. A modelling error that survives an interactive theorem prover is unlikely to survive a collaborator.

---

## Figure legends

**Figure 1 | The identifiability ceiling.** (a) Every test of two hypotheses p and q is bounded by Le Cam's two-point lemma: the excess accuracy over chance is exactly TV(p, q)/2, and the error rate is exactly (1 − TV)/2. Both bounds are attained, so no detector can exceed the curve. (b) The two-sided form |TP − FP| ≤ TV is the identity J ≤ TV for Youden's index J = Se + Sp − 1; the geometry is fixed by p and q alone, leaving threshold choice no freedom. (c) As a generator's distribution converges to the reference distribution, TV → 0 and attainable advantage → 0, independently of detector architecture.

**Figure 2 | Verification effort has a floor.** Residual miss rate as a function of the number of verification rounds. Geometric decay (1 − q)^N (dotted) is clipped at the floor T = λ·TV (dashed), giving the maximum of the two (solid). The cost-minimizing budget N\* is the smaller of the unconstrained optimum N_c and the p-independent cap N_0 = ln(1/λ·TV)/ln(1/(1−q)) (vertical markers). Increasing reviewer reliability p lowers N\* only while the floor is slack; once T ≥ x_c, N\* is pinned at N_0 and further reviewer quality buys nothing.

**Figure 3 | Two layers, two currencies, no exchange rate.** (a) The observation protocol induces an equivalence class [s\*]_α; certified coverage Φ(α) is a property of the class, not of a point. (b) Refinement (human, cross-layer) moves Φ itself and has unbounded gain; within-layer compression (machine) reduces the residual e_t to Φ and is capped at log(e₀/Φ). (c) The sign of the value is determined by which way along the axis the class moved, and no unsigned divergence can recover it.

**Figure 4 | Influence and value are separable.** For any M > 0 there exist processes with identical |influence| between two states α and β whose signed value is +M, and processes with the same |influence| whose value is −M. The horizontal coordinate (magnitude of change) is identical across all four cases; the vertical coordinate (signed contribution) is not determined by it. Any reflection-invariant measure — KL, mutual information, total variation, Jensen–Shannon — is blind to this split.

---

## Visual summary (for a general audience)

A four-panel illustrated series accompanies this article. All four panels use the same character and the same palette so that they read as a single sequence.

**VS1 | Two birds, one signal.** A field ecologist sights two songbirds through an instrument. The instrument returns a glowing outline for each, and the two outlines are identical; a dashed line joins them. The two organisms differ. The measurement does not. This is total variation distance equal to the sum of the mass the protocol cannot resolve, and it sets the ceiling on every detector that will ever be pointed at them.

**VS2 | Survey harder, resolve no further.** Four superimposed copies of the ecologist scan the same valley in sequence. Every scan beam travels a long way and is then clipped by a luminous horizontal barrier. Two bird silhouettes sit above the barrier, at a fixed separation, no matter how many scans are added. This is the verification floor: residual miss rate decays as (1 − q)^N and is then cut off at λ·TV, so the optimal number of rounds is capped at a value that contains no term for reviewer reliability.

**VS3 | Same push, opposite direction.** The character appears twice in identical pose, moving an identical glowing sphere with identical effort. On the left the sphere climbs toward a warm dawn and sharpens into precision. On the right the sphere falls into a dark vortex and dissolves into noise. Magnitude is held constant; only direction changes. Every unsigned measure — mutual information, KL, total variation — assigns both cases the same number.

**VS4 | Two currencies, no exchange rate.** The ecologist climbs a staircase of stacked glass layers, each layer a further resolution, her hand trailing light across each one. Beside her, a small robot compresses a cluster of glowing orbs along a single flat layer toward a fixed amber target. Between the staircase and the flat layer, an exchange arrow has broken into drifting fragments. Refinement moves the target and is unbounded; compression moves the residual and is capped at log(e₀/Φ). No monotone rate converts one into the other.

---

## Methods

The mathematical development was carried out in Lean 4 (toolchain `leanprover/lean4:v4.15.0`) against Mathlib, and is organized as nine modules: total variation and its properties; Bayesian-optimal detection and error rate; contamination as repeated TV mixing; coverage monotonicity, submodularity and diminishing marginal returns; a hypothesis-testing module consolidating mass-sum identities and the TV bounds; a refinement module separating layer-crossing and within-layer gains; a value module establishing the separability lemma; a verification-budget module; an incommensurability module fixing the utility class; and a calibration module proving that the sign of the minimum-contribution estimator is not identified. Finite probability spaces are modelled as `structure PMF (n : ℕ)`; total variation is the maximum over events of the absolute mass difference, with the two-sided bounds proved by summation over a partition rather than by appeal to the general theory. The full build completes with 2,532 of 2,533 targets and reports `Build completed successfully.`

Provenance search was conducted against the published literature on AI-text detection impossibility, information-theoretic measures of human contribution, verifier-robustness theory, and observation quotients in representation learning. Every digital object identifier reported here was resolved at the time of writing; where an identifier could not be resolved, none is given. Full texts rather than abstracts were read and checked for references 10, 13, 17 and 18, including the appendices of reference 18; the quotations are verbatim, Equation (10) and the hyperparameter values are as stated in its §A.5, and the authorship of reference 17 was corrected against the retrieved PDF.

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

---

## Acknowledgements

[To be assigned]

## Author contributions

[To be assigned]

## Competing interests

The authors declare no competing interests.

## Code availability

The formal development comprises 117 machine-checked theorems in nine Lean modules with zero admitted axioms. Reproduction requires toolchain `leanprover/lean4:v4.15.0` and Mathlib v4.15.0; a full build reports `Build completed successfully.` at 2,532/2,533 targets.