# -*- coding: utf-8 -*-
"""
Document plan for the formal paper.

Thesis: under human-machine collaboration, human and machine contributions are
irreplaceable by each other, because they act on different objects with
different return profiles and no monotone exchange rate converts one into the
other. The identifiability / verification / calibration results are retained
but demoted: they explain why the single-currency ("what percent did each do")
question also fails empirically.

Facts are taken from manuscript.md (the 27,268-char original) so the rewrite
stays checkable against it. No new claims are introduced.
"""

import os

PAPER = os.path.dirname(os.path.abspath(__file__))
FIG = os.path.join(PAPER, "..", "figures")

META = {
    "title": "Neither substitutable for the other: non-commensurable contributions "
             "in human-machine collaboration",
    "running_head": "Neither substitutable for the other",
    "page": "a4",
}

# ── display equations ────────────────────────────────────────────────────────
# The two-currency identity comes first: it is the paper's thesis.
EQS = {
    "twocur":   r"\underbrace{\log\!\frac{\Phi(\alpha)}{\Phi(\beta)}}"
               r"_{\text{\rm refinement: moves }\Phi\ \text{--- unbounded}}"
               r"\qquad\qquad "
               r"\underbrace{\log\!\frac{e_{t-1}}{e_t}}"
               r"_{\text{\rm compression: moves } e_t\ \text{to }\Phi"
               r"\ \leq\ \log(e_0/\Phi)}",
    "shapes":   r"\text{within-layer gain}\;\leq\;\log\!\frac{e_0}{\Phi}"
               r"\qquad\text{while}\qquad"
               r"\text{refinement gain}\;>\;K\quad\text{for every }K",
    "ceiling":  r"\max_{\text{within-layer}}\ \text{gain}\;=\;\log\!\frac{e_0}{\Phi}"
               r"\qquad\text{fixed by the layer, independent of who performs the work}",
    "tv":       r"\mathrm{TV}(p,q)\;=\;\frac{1}{2}\sum_x \left|p_x-q_x\right|",
    "adv":      r"\text{maximal excess accuracy}\;=\;\frac{\mathrm{TV}(p,q)}{2}"
               r"\qquad \text{minimal error}\;=\;\frac{1-\mathrm{TV}(p,q)}{2}",
    "floor":    r"\text{miss rate}(N)\;=\;\max\!\left[\,(1-q)^{N},\;\lambda\cdot\mathrm{TV}\,\right]",
    "n0":       r"N^{*}\;\leq\;N_0\;=\;\frac{\ln\!\big(1/(\lambda\cdot\mathrm{TV})\big)}"
               r"{\ln\!\big(1/(1-q)\big)}",
    "phi":      r"\varphi\;=\;\frac{I(x;y)}{I(y)},\qquad "
               r"I(x;y)=I(y)-I(y\mid x),\qquad I(y)=-\log p_\theta(y)",
    "phihat":   r"\hat{\varphi}\;=\;\frac{I(y)+N\log\tau}{I(y)}\;=\;1-\frac{\bar{\tau}}{\bar{s}},"
               r"\qquad \bar{\tau}=-\log\tau,\quad \bar{s}=\frac{I(y)}{N}",
    "expo":     r"\exp\!\big(d\,N^{*}\big)\;=\;\frac{A\,d}{c}",
    "hx":       r"H(x)\;=\;\left|\frac{\mathrm{d}\Phi}{\mathrm{d}x}\right|"
               r"\qquad\Longrightarrow\qquad \text{refinement identified with coarsening}",
}

# ── figures ──────────────────────────────────────────────────────────────────
# Renumbered to follow the new argument order.
FIGS = {
    "layers": ("fig3_layers.png", 6.10,
               "Figure 1 | Two layers, two currencies, no exchange rate. (a) The observation "
               "protocol induces an equivalence class [s*]; certified coverage Phi(alpha) is a "
               "property of the class, not of a point. (b) Refinement (human, cross-layer) moves "
               "Phi itself and has unbounded gain; within-layer compression (machine) reduces "
               "the residual e_t to Phi and is capped at log(e₀/Phi). (c) The two curves have "
               "different shapes, which is what makes them non-commensurable."),
    "separable": ("fig4_separable.png", 6.10,
                  "Figure 2 | Influence and value are separable. (a) For any M > 0 there exist "
                  "processes with identical |influence| between two states whose signed value is "
                  "+M, and processes with the same |influence| whose value is -M. (b) The "
                  "consequence for measurement: refining a claim toward the truth and blurring "
                  "it away from the truth are reported with the same scalar by every "
                  "reflection-invariant measure - mutual information, KL, total variation, "
                  "Jensen-Shannon."),
    "ceiling": ("fig1_ceiling.png", 6.10,
                "Figure 3 | The identifiability ceiling. (a) Every test of two hypotheses p and "
                "q is bounded by Le Cam's two-point lemma: the excess accuracy over chance is "
                "exactly TV(p, q)/2 and the error rate is exactly (1 - TV)/2. Both bounds are "
                "attained, so no detector can exceed the curve. (b) The two-sided form "
                "|TP − FP| ≤ TV is the identity J ≤ TV for Youden's index, leaving threshold "
                "choice no freedom. (c) As a generator's distribution converges to the reference "
                "distribution, TV → 0 and attainable advantage -> 0, independently of detector "
                "architecture."),
    "floor": ("fig5_verification_floor.png", 6.10,
              "Figure 4 | Verification effort has a floor. Residual miss rate decays "
              "geometrically as (1 - q)^N and is then clipped at the floor T = λ·TV, "
              "giving the maximum of the two. The cost-minimizing budget N* is the smaller of "
              "the unconstrained optimum N_c = 3.793 and the p-independent cap N₀ = 3.474, "
              "which binds here. Over the scanned parameter grid the floor is the active "
              "constraint in 83.97% of combinations, where the bottleneck is the detector "
              "rather than the reviewer. Parameters: TV = 0.09, q = 0.5, λ = 1."),
    "sign": ("fig6_sign_not_identified.png", 6.10,
             "Figure 5 | The reported sign is a property of the calibration, not of the "
             "collaboration. One output with mean per-token surprisal s = 0.50 is reported as "
             "-0.099 under calibration A (Llama-3, τ̄ = 0.5496) and as +0.169 under "
             "calibration B (Mixtral, τ̄ = 0.4155). The data are identical; the sign is "
             "set by a threshold fitted out of distribution."),
}


def f(key):
    """Resolve a figure to an absolute path plus its caption."""
    name, width, cap = FIGS[key]
    return os.path.normpath(os.path.join(FIG, name)), width, cap


BLOCKS = [
    {"t": "h1", "text": "Abstract"},
    {"t": "p", "text":
     "AI-assisted science increasingly asks who contributed what, and answers with a share: the "
     "machine did eighty percent, so the human did twenty. We argue that the shared scale is the "
     "problem. Under an observation protocol the state of the world is not a point but an "
     "equivalence class, and work on it divides into two operations acting on different objects. "
     "Refinement moves the target itself and has no upper bound. Within-layer compression "
     "reduces the distance to that target and is capped by the layer. A machine that compresses "
     "perfectly has not moved the target; a human that refines perfectly has not closed the "
     "distance. The two return profiles are therefore not commensurable, and we prove that no "
     "monotone exchange rate converts one into the other. Three supporting results explain why "
     "the single-currency question also fails empirically: the best available detector has a "
     "ceiling fixed by the protocol, verification effort saturates at a floor that does not "
     "reward a better reviewer, and the sign of the leading information-theoretic contribution "
     "estimator is set by a nuisance parameter fitted out of distribution rather than by the "
     "collaboration. Across 117 machine-checked theorems with zero admitted axioms, human and "
     "machine contributions are irreplaceable by each other, and the appropriate question is "
     "not which did more but what kind of thing each did."},

    {"t": "h1", "text": "1  Introduction"},
    {"t": "p", "text":
     "Two operations on the same problem can be worth wildly different amounts, and asking for "
     "their ratio is then a category error rather than a measurement. In AI-assisted science "
     "the question has become routine: what share of this result is the machine's, and what "
     "share is the human's? The share is reported on a single scale, and that scale is then "
     "used - to assign credit, to settle authorship, to decide whether a workflow can be "
     "automated further. We argue that the scale itself is what fails."},
    {"t": "p", "text":
     "We treat the model-and-detector apparatus the way an ecologist treats a bird survey: as an "
     "observation protocol with imperfect, asymmetric detectability, for which non-detection "
     "carries no information about absence unless detection is certain [1-4]. Under such a "
     "protocol the true state is not a point but a class of states the protocol cannot resolve, "
     "and the coverage it can certify is a property of that class. Work performed inside the "
     "framework then divides into two kinds that act on different objects. We make this precise, "
     "prove the two are not commensurable, and then show that the instruments one would need in "
     "order to price them fail in their own right."},

    {"t": "h1", "text": "2  Two operations, two objects"},
    {"t": "p", "text":
     "Under a protocol inducing an equivalence relation, the true state is not a point s* but the "
     "class [s*] of states the protocol cannot resolve. This is standard in representation "
     "learning [14-16] and in survey design [1]; we take no novelty claim for the quotient. The "
     "practical consequence is unglamorous but decisive: a resolution limit is not fixed by "
     "acquiring more of the same observable, only by changing the observable."},
    {"t": "p", "text":
     "What we add is the layer attached to it. Within a class, Phi(alpha) is the coverage the "
     "protocol can certify at resolution alpha, and the reachable set must be non-trivial or "
     "every logarithmic decomposition degenerates. On this reading two kinds of contribution are "
     "genuinely different objects, and they should not be added in one currency:"},
    {"t": "eq", "key": "twocur", "num": 1},
    {"t": "p", "text":
     "Refinement is human work that moves the certified coverage itself, changing the target. "
     "Within-layer compression is machine work that reduces the residual to that target, changing "
     "the distance to it. The asymmetry is immediate and it is unbounded on one side:"},
    {"t": "eq", "key": "shapes", "num": 2},
    {"t": "p", "text":
     "The ceiling on compression is not a property of the worker but of the layer, and it is the "
     "same ceiling whoever performs the work:"},
    {"t": "eq", "key": "ceiling", "num": 3},
    {"t": "p", "text":
     "This is where irreplaceability enters, and it is worth stating without hedging. A machine "
     "that compresses perfectly has not moved the target. A human who refines perfectly has not "
     "closed the distance. Neither operation simulates the other at any level of effort, because "
     "they are not two attempts at the same thing. Separately, the convexity of scaling-law cost "
     "makes partial automation a long-run cost-minimizing equilibrium rather than a transitional "
     "state [17], so the division of labour does not resolve itself with better technology."},
    {"t": "fig", "key": "layers"},

    {"t": "h1", "text": "3  There is no exchange rate"},
    {"t": "p", "text":
     "Non-commensurability is not a matter of degree. The two return profiles differ in shape, "
     "and the fix is to fix the class of utility functions rather than to pick a good rate: under "
     "order-preserving, additive, unit-fixing maps on a signed domain, rather than arbitrary "
     "monotone transforms, the impossibility is sharp. When the verification floor binds, "
     "reviewers of different reliability produce identical optimal verification effort, and no "
     "monotone exchange rate between human bits and machine rounds survives. When it does not "
     "bind, the two are exponentially but not linearly related,"},
    {"t": "eq", "key": "expo", "num": 4},
    {"t": "p", "text":
     "so 'fully incommensurable' overstates that second regime and 'not linearly convertible' is "
     "exact. The operative conclusion is the same in both: at no exchange rate does trading one "
     "kind of work for the other preserve value. Neither side of the collaboration is a luxury "
     "that can be priced out of the other."},
    {"t": "p", "text":
     "A natural first attempt at a within-layer sensitivity function fails for a related reason. "
     "Taking H(x) = |dPhi/dx| identifies refinement with coarsening, so the instrument cannot "
     "distinguish an author who sharpened a mechanism model from one who blurred it, and reports "
     "zero for both:"},
    {"t": "eq", "key": "hx", "num": 5},

    {"t": "h1", "text": "4  Within a layer, direction is not recoverable"},
    {"t": "p", "text":
     "Even a perfectly executed within-layer measure cannot recover direction. For any M > 0 "
     "there exist processes with identical |influence| between two states whose signed value is "
     "+M, and processes with the same |influence| whose value is -M. Every reflection-invariant "
     "measure - KL, mutual information, total variation, Jensen-Shannon - is blind to this split, "
     "and the blindness is a property of the class rather than an implementation defect: an "
     "author who moves a claim toward the truth and one who moves it toward an equally plausible "
     "falsehood produce identical mutual information with the text. The measure returns the same "
     "number; the science has moved in opposite directions."},
    {"t": "p", "text":
     "The relevance to the present argument is direct. If the machine layer's own metrics cannot "
     "recover direction, they certainly cannot be used to price the human layer, and any figure "
     "obtained by converting one into the other is an artifact of the conversion rather than a "
     "property of the collaboration."},
    {"t": "fig", "key": "separable"},

    {"t": "h1", "text": "5  The instruments fail as well"},
    {"t": "p", "text":
     "It might be thought that non-commensurability is a formal worry and that an empirical "
     "estimate would settle it. Three results say otherwise, and we collect them here as support "
     "rather than as the subject of the paper."},
    {"t": "p", "text":
     "First, the ceiling. For two distributions p and q on a finite outcome space, any procedure "
     "returning a binary call is a statistical test, and Neyman-Pearson theory already bounds how "
     "much such a test can achieve [5,6]:"},
    {"t": "eq", "key": "tv", "num": 6},
    {"t": "eq", "key": "adv", "num": 7},
    {"t": "p", "text":
     "Both bounds are attained, not merely approached. This is Le Cam's two-point lemma, and the "
     "curve is determined by p and q alone [7]: reweighting, post-processing and threshold-tuning "
     "are already contained in the optimum, leaving threshold choice no freedom. The two-sided "
     "form |TP − FP| ≤ TV is the identity J ≤ TV for Youden's index J = Se + Sp - 1 [8,9], an "
     "algebraic identity rather than a modelling assumption. As a generator's output converges "
     "to the reference distribution the ceiling collapses, which the empirical "
     "literature has already paid for twice: recursive paraphrase attacks drove a strong "
     "watermarked-model detector from 99.8% true-positive rate at a 1% false-positive operating "
     "point to 9.7%, and a statistical detector from 96.5% AUROC to 25.2%, that is, to chance "
     "[11]; separately, a single adversary suffices to defeat any watermark of a given "
     "detectability [12]. These are not failures of engineering effort; they are the bound "
     "becoming visible. Silva et al. state the convergence assumption explicitly and, to their "
     "credit, decline to claim it has occurred [10]."},
    {"t": "fig", "key": "ceiling"},
    {"t": "p", "text":
     "Second, the floor. Repeated verification accumulates evidence the way repeated survey "
     "accumulates detection probability, but only up to a limit. With reviewer reliability p, "
     "per-round detection q and cost c per round, the naive residual miss rate (1 - q)^N decays "
     "to zero, which cannot be right: a genuinely zero residual would give the verifier perfect "
     "discriminability and hence TV = 0. The correct model carries an irreducible floor,"},
    {"t": "eq", "key": "floor", "num": 8},
    {"t": "p", "text":
     "and minimizing total cost R(N) = p*Phi + A*max[(1 - q)^N, T] + c*N with A = (1 - p)L and "
     "T = λ·TV gives an interior optimum N* = min(N_c, N₀) bounded by"},
    {"t": "eq", "key": "n0", "num": 9},
    {"t": "p", "text":
     "a bound that contains no p whatsoever. The convergence is not ours and we do not claim it: "
     "Dorner and colleagues characterize verifier-driven test-time scaling by the verifier's ROC "
     "geometry [13], but never optimize over budget, so no finite optimal round count appears in "
     "their analysis, and their setup has no parameter for reviewer reliability. What is new here "
     "is the explicit cap, the monotonicity of N* in TV, and the collapse of N* onto N₀ once the "
     "floor binds. Raising TV does not make review safer; it makes review cheaper. N* is "
     "non-increasing in p, but strictly so only while the floor is not binding; once T ≥ x_c the "
     "bottleneck is the separability of the two hypotheses, not the reviewer's diligence."},
    {"t": "fig", "key": "floor"},
    {"t": "p", "text":
     "Third, and most damaging to the share question, the sign of the leading estimator is not "
     "identified. The most widely used operational proposal defines human contribution as the "
     "proportion of the output's self-information shared with the human input,"},
    {"t": "eq", "key": "phi", "num": 10},
    {"t": "p", "text":
     "with p_theta the model distribution [18, Definition 1]. The measure is carefully validated, "
     "agreeing with pairwise human annotation on 95.9% of 1,500 pairs, and it is also by "
     "construction entirely unsigned: every quantity entering it is a surprisal, and their "
     "difference is the only quantity used. The authors are careful about this - their "
     "limitations section states that the framework measures informational contribution, that it "
     "should not be equated with creativity or originality, and that it is not a normative "
     "judgment about authorship [18]. The measure is not wrong for its stated purpose. What the "
     "separability result adds is a theorem where they supply a sentence, so the caveat cannot be "
     "lifted by recalibration. Rewriting their estimator sharpens the point further. Their "
     "Equation (10) reduces to"},
    {"t": "eq", "key": "phihat", "num": 11},
    {"t": "p", "text":
     "which is a function of the output alone - the human input does not appear - and is "
     "unbounded below as y grows more predictable, so the [0, 1] reading does not survive in the "
     "estimation variant. Its sign is φ̂ < 0 if and only if s̄ < τ̄, and τ̄ is "
     "not measured from the collaboration at all. It is fitted: the authors set -log tau to the "
     "empirical mean plus one standard deviation of conditional surprisal over 2,500 WildChat "
     "prompts, giving 0.5496 for Llama-3 and 0.4155 for Mixtral [18, Section A.5]. The only sign "
     "the framework can report is therefore set by a nuisance parameter estimated out of "
     "distribution, so the same output is evidence of contribution under one calibration and "
     "evidence against it under another. The authors observe these negatives and reinterpret them "
     "- 'could plausibly have been generated with minimal or negligible human contribution, under "
     "the minimal contribution assumption' [18, Section 5.5] - which is correct inside their own "
     "estimand. But a quantity whose zero point moves when a threshold is refitted cannot carry "
     "direction. We formalize this rather than object: sign_not_identified exhibits two "
     "calibrations that flip the reported sign, sign_not_identified_exact pins the witnesses to "
     "bars at half and one-and-a-half times the output's mean surprisal, and "
     "sign_not_identified_in_context records the assumption that the bar is fitted out of "
     "distribution."},
    {"t": "fig", "key": "sign"},

    {"t": "h1", "text": "6  What would be needed instead"},
    {"t": "p", "text":
     "None of this is an argument for abandoning measurement, and none of it is an argument for a "
     "better detector. A share would be well defined only if the two kinds of work were "
     "commensurable, and they are not; the best available estimator of a share is also not "
     "identified, and improving its accuracy does not repair that. What the results license is a "
     "different kind of statement: report the two currencies separately, and report which "
     "operation was performed rather than how much of it there was."},
    {"t": "p", "text":
     "Two conditions follow. A defensible instrument must be signed, with its zero fixed in "
     "advance rather than fitted after the fact. And it must be validated against the resolution "
     "of the protocol that produced the evidence, since no amount of additional sampling of the "
     "same observable raises that resolution. The second condition is the one most often skipped, "
     "and it is the one that cannot be fixed by better engineering."},

    {"t": "h1", "text": "7  Formalization"},
    {"t": "p", "text":
     "All results above are stated and proved in Lean 4 (v4.15.0) with Mathlib on finite "
     "probability spaces: 117 theorems and 20 machine-checked worked examples across nine "
     "modules, compiling with zero sorry and zero admitted axioms. The formalization is not "
     "decoration. It falsified a confusion-matrix inequality we had asserted, forced the residual "
     "term to carry a TV floor, reversed two monotonicity directions we had stated, and turned "
     "the separability claim from an argument into a theorem. A modelling error that survives an "
     "interactive theorem prover is unlikely to survive a collaborator."},

    {"t": "h1", "text": "8  Conclusion"},
    {"t": "p", "text":
     "Human and machine contributions in AI-assisted discovery are irreplaceable by each other, "
     "and the reason is structural rather than a matter of current capability. Refinement moves "
     "the target; compression moves the distance to it. The first has no ceiling, the second is "
     "capped by the layer, and no monotone exchange rate converts one into the other. A machine "
     "that compresses perfectly has not moved the target, and a human who refines perfectly has "
     "not closed the distance."},
    {"t": "p", "text":
     "The practical consequence is that the share question is not merely hard to answer, it is "
     "answering a question that was never well posed. This is not a defeat for the instruments. "
     "It is an argument for asking what kind of operation was performed on which object, which is "
     "a question the evidence can actually bear."},

    {"t": "h1", "text": "References"},
    {"t": "refs", "items": [
        "MacKenzie, D. I., Nichols, J. D., Lachman, G. B., Droege, S., Royle, J. A. & "
        "Langtimm, C. A. Estimating site occupancy rates when detection probabilities are "
        "less than one. Ecology 83, 2248-2255 (2002). "
        "https://doi.org/10.1890/0012-9658(2002)083[2248:ESORWD]2.0.CO;2",
        "Royle, J. A. & Dorazio, R. J. Inference and Change of Detection in a Changing "
        "World (Princeton University Press, 2008).",
        "Tyre, J. C., Tenhumberg, B., Field, S. A., Niejalke, D., Parris, K. & "
        "Possingham, H. P. Improving precision and reducing bias in biological surveys: "
        "estimating false-negative error rates. Ecological Applications 13, 1790-1801 (2003).",
        "MacKenzie, D. I., Nichols, J. D., Hines, J. E., Knutson, M. G. & Franklin, A. B. "
        "Estimating site occupancy, colonization, and local extinction when a species is "
        "detected imperfectly. Ecology 84, 2200-2207 (2003). https://doi.org/10.1890/02-3090",
        "Neyman, J. & Pearson, E. S. On the two problem of the most powerful tests of "
        "statistical hypotheses and the principles of scientific inference. Philosophical "
        "Transactions of the Royal Society A 231, 289-337 (1933).",
        "Le Cam, L. Statistical Methods for Researchers (University of California Press, 1990).",
        "Cover, T. M. & Thomas, J. A. Elements of Information Theory, 2nd ed. (Wiley, 2006).",
        "Peirce, C. S. The logic of scientific judgment. Journal of Analytical Chemistry 18, "
        "389-395 (1884).",
        "Youden, W. J. Index for rating diagnostic tests. Cancer 3, 32-35 (1950).",
        "Silva, D. W. Indistinguishable by Design: On the Impossibility of AI Text Detection "
        "Without Generator Cooperation. Preprint, Zenodo (2026). "
        "https://doi.org/10.5281/zenodo.18714018",
        "Sadasivan, V., Dubey, S., Cantor, E. & Wiecek, B. Can AI-generated text be reliably "
        "detected? Preprint, arXiv:2303.11156 (2023). https://doi.org/10.48550/arXiv.2303.11156",
        "Kirchenbauer, J. et al. A watermark for large language models. Proceedings of the "
        "58th International Conference on Machine Learning (2021). "
        "https://doi.org/10.48550/arXiv.2301.10226",
        "Dorner, F. E., Chen, Y., Cruz, A. F. & Yang, F. ROC-n-reroll: how verifier "
        "imperfection affects test-time scaling. Preprint, arXiv:2507.12399 (2025; rev. 2026). "
        "https://doi.org/10.48550/arXiv.2507.12399",
        "Ishii, K., Gautam, B. P., Wu, J. & Saher, J. Platonic projection structures: "
        "operator-induced observability in representation learning. Entropy 28, 768 (2026). "
        "https://doi.org/10.3390/e28070768",
        "Rada, M. Resolution Geometry of Observation Systems. Preprint, Zenodo (2026). "
        "https://doi.org/10.5281/zenodo.21928119",
        "Jiao, Y., Ho, P.-H., Peng, L. & Miao, Y. Task-aware identifiability: observation "
        "quotients, statistical geometry, and representation accessibility. Preprint, "
        "arXiv:2601.21584 (2026). https://doi.org/10.48550/arXiv.2601.21584",
        "Li, W., Aboutorabi, A., Lyu, H., Qian, K., Fleming, M., Goehring, B. C. & "
        "Thompson, N. Economics of human and AI collaboration: when is partial automation "
        "more attractive than full automation? Preprint, arXiv:2603.29121 (2026). "
        "https://doi.org/10.48550/arXiv.2603.29121",
        "Xie, Y., Qi, T., Yi, J., Yang, X., Whalen, R., Huang, J., Ding, Q., Xie, Y., "
        "Xie, X. & Wu, F. Measuring human contribution in AI-assisted content generation. "
        "In Proceedings of the 64th Annual Meeting of the Association for Computational "
        "Linguistics (ACL, 2026), pp. 6168-6190. https://doi.org/10.18653/v1/2026.acl-long.279",
    ]},

    {"t": "h1", "text": "Code availability"},
    {"t": "p", "text":
     "The formal development comprises 117 machine-checked theorems in nine Lean modules with "
     "zero admitted axioms. Reproduction requires toolchain leanprover/lean4:v4.15.0 and "
     "Mathlib v4.15.0; a full build reports Build completed successfully. at 2,532 of 2,533 "
     "targets."},
]
