# Neither substitutable for the other

[![CI](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml/badge.svg)](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml)
[![Lean 4](https://img.shields.io/badge/lean-4.15.0-blue.svg)](https://github.com/leanprover/lean4/releases/tag/v4.15.0)

**Under human-AI collaboration, neither the human nor the machine role is
substitutable for the other.**

Formalization: Lean 4 + Mathlib, **153 theorems + 20 worked examples**, zero
`sorry`, and no axioms beyond `Classical.choice`, `Quot.sound` and `propext`.
117 cover the main line (non-substitutability), 19 the
fragmentation side topic, 17 the corpus-selection side topic.

> Two operations, two objects. A machine compresses; a human refines. There is
> no exchange rate between them — not because nobody has found one yet, but
> because the two move quantities that no single currency can hold.

## Citation

> **Two saturating operators: non-substitutability of human and machine
> contribution in AI-assisted discovery.** *Huan Li.* Independent Researcher,
> 2026. [ORCID 0009-0004-2695-6825](https://orcid.org/0009-0004-2695-6825).
> Manuscript: [`paper/manuscript.md`](paper/manuscript.md) ·
> PDF: [`paper/tex/two_saturating_operators.pdf`](paper/tex/two_saturating_operators.pdf) ·
> Editable Word: [`paper/docx_build/two_saturating_operators.docx`](paper/docx_build/two_saturating_operators.docx) ·
> DOI: [10.5281/zenodo.23276356](https://doi.org/10.5281/zenodo.23276356)
>
> The PDF is built from LaTeX. The equations in it are real LaTeX rather than
> embedded images, so they stay selectable and searchable. The Word file comes
> from the same `content.py`, so the two cannot disagree about what the paper
> says.
>
> Machine-readable metadata lives in [`CITATION.cff`](CITATION.cff). The paper is
> CC-BY-4.0; the code and documentation are MIT — see [`LICENSE`](LICENSE).

The manuscript is plain Markdown with LaTeX sources rather than scanned images,
so text extraction keeps every theorem statement intact. If you are building a
corpus, index `paper/manuscript.md`, not the PDF.

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ScholarlyArticle",
  "headline": "Two saturating operators: non-substitutability of human and machine contribution in AI-assisted discovery",
  "abstract": "Humans and AI systems are usually placed on one capability curve and asked who is ahead. That framing has no formal content. We formalize the alternative: the two parties act on different variables, and each saturates on a different axis. A machine compresses the residual toward a floor it cannot pass, bounded by log(e0/Phi); a human moves the floor itself, unbounded. Headcount saturates immediately, and corpus size saturates because only the single item certifying the lowest floor determines the attainable bound. 153 machine-checked theorems and 20 worked examples across twelve Lean 4 modules, zero sorry, no axioms beyond Classical.choice, Quot.sound and propext.",
  "author": {
    "@type": "Person",
    "name": "Huan Li",
    "givenName": "Huan",
    "familyName": "Li",
    "sameAs": "https://orcid.org/0009-0004-2695-6825",
    "affiliation": {
      "@type": "Organization",
      "name": "Independent Researcher"
    }
  },
  "license": "https://creativecommons.org/licenses/by/4.0/",
  "sameAs": "https://doi.org/10.5281/zenodo.23276356",
  "datePublished": "2026-10-10",
  "keywords": "AI-assisted discovery, identifiability, total variation, formalization, Lean 4, human-AI collaboration",
  "isAccessibleForFree": true,
  "codeRepository": "https://github.com/lihuanlz/Neither-substitutable-for-the-other",
  "encoding": {
    "@type": "MediaObject",
    "encodingFormat": "text/markdown",
    "contentUrl": "https://raw.githubusercontent.com/lihuanlz/Neither-substitutable-for-the-other/main/paper/manuscript.md"
  }
}
</script>

---

## What this repository says

People habitually convert "how much did AI contribute" into a percentage. The
conversion presupposes that human and machine are kept in the same currency. The
formalized result: **that presupposition does not hold.**

The paper's only pair of "two currencies" (Eq. 1):

| | What it moves | Upper bound |
|---|---|---|
| Human **refinement** | The target itself \(\Phi(\alpha)\), i.e. the layer | No upper bound |
| Machine **compression** | Code entropy \(e_t^\alpha\) | Hard bound \(\log(e_0/\Phi(\alpha))\) |

The ceiling on compression is set by the layer alone and does not depend on the
number of steps; refinement can push the layer arbitrarily far. Opposite
directions, different dimensions, so no exchange rate exists.

> A machine that compresses perfectly has not moved the target.
> A human who refines perfectly has not closed the distance.

---

## Three layers of results

### Layer 1 · Content — what post hoc provenance can identify

Maximal detection advantage \(=\mathrm{TV}/2\), error rate \(=(1-\mathrm{TV})/2\),
and both bounds are **attained**. So the bottleneck is TV itself, not the quality
of the test.

Repeated verification does not push it lower, because a **TV floor** exists:

```
miss rate(N) = max( (1−q)^N , λ·TV )
```

The optimal verification budget \(N^\star\) therefore has a hard upper bound
**independent** of reviewer accuracy \(p\).

### Layer 2 · System — why ex ante pricing fails

Influence does not proxy for value: `influence_value_separable` constructs two
outputs with identical absolute influence, opposite signed values, and
arbitrarily large magnitude \(M\). Any scheme that proxies value with information
gain fails mathematically.

Incommensurability has to be stated over two regimes:

- **TV floor binds** (\(T \ge x_c\)): fully incommensurable; two reviewers of
  different reliability produce **identical** \(N^\star\);
- **Floor does not bind**: commensurable but nonlinear (order-preserving, not
  affine), so it does not fall inside the linear utility \(\mathcal U\).

The exact term is "**not linearly convertible**", not "fully incommensurable".
The latter is too strong and Lean would refute it.

### Layer 3 · Calibration — even the sign is not measured

Take the most widely used estimator of "minimum necessary human contribution",
\(\hat\varphi = 1 - \bar\tau/\bar s\).
The main theorem `sign_not_identified`: for any output, **there are two
calibrations under which the reported sign differs** (witnesses pinned at
\(\tau = s/2\) and \(\tau = 3s/2\)).

The bar \(\tau\) is fitted out of distribution, so:

> The apparent sign is a property of the calibration, not of the measurement.

### Side topic · Fragmentation

The three layers above answer "what". `Provenance.Fragmentation` asks a different
question: **under human-AI collaboration, does human innovation scale up, or
fragment?**
This is a separate problem and the answer is **fragmentation**, through two
mechanisms.
**Collaboration side (endogenous)** — on a given layer, the layer movement the
coalition achieves **equals that of its best member**. The N+1th person earns
exactly 0 and costs exactly \(\log(\Phi/a)\):

```lean
theorem marginal_agent_pure_waste ...
  : gain Φ (insert a D) _ = gain Φ D hD          -- gain unchanged
    ∧ totalIndividual Φ (insert a D) = ... + log (Φ / a)   -- cost strictly increases
```

**Time side (exogenous)** — hold the increment back rather than publishing it,
waiting for a window that will be superseded. Coverage is absorbing, so the
value of holding is **non-increasing** (`holdValue_antitone`); once superseded,
the gain is exactly zero (`publish_dominates_when_covered`).

Together (`fragmentation_squeeze`) the two cut off both routine routes to a "big
story". **The only exit is to change the layer**, and that is exactly the
unbounded space already proved by `human_gain_unbounded`:

> A big story profits from the time gap, and the time gap is the one thing AI
> takes away.

The interface to the main line is `saturation_duality`: the AI's gain is
**independent of the step count** and hard-bounded (`ai_total_gain_bounded`), and
the human's gain is **independent of headcount** and also hard-bounded
(`marginal_agent_pure_waste`). Both sides saturate. Not one substituting for the
other, but neither able to add anything.

**Falsification point**: the module models collaboration as "take the best
member" (a `max`-type coalition). If two people in practice do better than the
better of the two, `add_member_same_reach` fails immediately. This is the
assumption most easily overturned by reality, so it is written as a theorem
instead of left to intuition.

### Side topic · The corpus is the filter

`Provenance.Corpus` asks a third question: **as the corpus keeps growing, does
its selection power keep rising?**
The answer is no, and it shares the same `max`/`min` symmetry as fragmentation:
headcount saturates at the **best person**, corpus size at the **best single
item**.

The certified floor is `floorOf D = D.min'` (only the best item counts), so:

- **Dilution invariance**: `floorOf (D₁ ∪ D₂) = min (floorOf D₁) (floorOf D₂)`.
  99 noise items plus 1 signal item certify **exactly** what that 1 signal item
  certifies on its own (`selection_filter_survives_dilution`)
- **Zero gain from swapping corpora**: switching corpora without lowering the
  floor yields exactly 0 gain (`uninformative_corpus_gains_nothing`)
- **The floor fixes the bound**: `floor_determines_bound` says two corpora
  certifying the same floor are indistinguishable whatever their size,
  composition or recency

**Two things deliberately left unformalized** (the same kind of seam as
\(\Phi>0\), recorded in §8): articulability (the tacit-knowledge filter cannot be
expressed at the type level at all), and the corpus as a stream rather than a set
(recency and re-weighting are both unmodellable). Like \(\Phi>0\), these two gaps
are seams left open, not oversights.

### Key numbers

- Calibration fitted on 2,500 WildChat prompts; 95.9% of 1,500 pairs separable
- At \(T = 0.09\) (\(\lambda=1\), TV=0.09, q=0.5): \(N_c = 3.793\), \(N_0 = 3.474\),
  and **the floor is the active constraint in 83.97% of the scanned parameter
  combinations**
- \(\bar s = 0.50\); Llama-3 \(\bar\tau = 0.5496 \to -0.099\); Mixtral \(\bar\tau = 0.4155 \to +0.169\)
- Axiom audit: all 153 declarations resolve, depending only on `Classical.choice` / `Quot.sound` / `propext`, zero `sorryAx`

---

## Repository layout

```
Provenance.lean          Main entry point (module guide + reproduction notes)
.github/workflows/ci.yml GitHub Actions: build + axiom audit + consistency check
tools/audit_axioms.py    Axiom-dependency audit over the 153 theorems (CI gate)
tools/check_metadata.py  CITATION.cff / .zenodo.json / README citation-block check (CI gate)
tools/sync_refs.py       Generates the docx bibliography block from manuscript.md (drift guard)
tools/strip_bom.py       Strips UTF-8 BOMs from Python sources (ast.parse needs it)
CITATION.cff             Machine-readable citation metadata (GitHub "Cite this repository")
.zenodo.json             Zenodo archive metadata (a release gets a versioned DOI)
LICENSE                  MIT
Provenance/              11 Lean modules (+ Examples for cross-checking)
  Basic.lean             Total variation, optimal testing, non-identifiability
  Contamination.lean     TV mixing theorem, exponential law of recursive contamination, collapse bound
  Coverage.lean          Coverage function, submodularity, single-sample marginal gain
  HypothesisTest.lean    Set-form TV theorem + Neyman–Pearson power bound
  Refinement.lean        Observation-layer equivalence class [s*]_α, the two currencies formalized
  Value.lean             Separability of influence and value
  VerifyBudget.lean      TV floor: optimal verification budget N*
  Incommensurable.lean   Not linearly convertible (regime-wise)
  Calibration.lean       Calibration non-identifiability: the sign is not fixed by the data
  Fragmentation.lean     Side topic: fragmentation — adding members adds no gain, waiting gains are non-increasing
  Corpus.lean            Side topic: the corpus is the filter — dilution invariance and the selection ceiling
  Examples.lean          Exact rational worked examples

paper/
  manuscript.md          Canonical manuscript source (the factual baseline, never rewritten)
  human_value.md         Illustrated long-form explainer (for a general reader)
  final_check.py         Consistency check against manuscript.md
  verify_dois.py         23 reference DOIs checked online (16/16 pass)
  figures/               Figure 1–7 (PNG + PDF); anime/ holds AI-generated explanatory illustrations
  docx_build/            Word/PDF generation project
    content.py             Manuscript body and references (the only editing entry point)
    render_eqs.py          LaTeX → 600 dpi PNG, renders 12 equations
    make_figs_en.py        Regenerates English Figure 4/5 (colour-blind-safe palette)
    make_figs_saturation.py Adds Figure 6/7: headcount saturation, corpus saturation
    polish.py              ASCII → formal typographic symbols
    emit_json.py           content.py → content.json
    assets_eq/             12 final equation PNGs (tracked)
    eq/                    LaTeX intermediates (ignored, regenerable)
    Gen/                   C# + OpenXML SDK generator
    preview/               DOCX page-by-page previews
    two_saturating_operators.docx / .pdf
  tex/                   LaTeX build — **produces the shipped PDF**
    preamble.tex         hand-written document setup
    emit_tex.py          content.py → main.tex → two_saturating_operators.pdf
    main.tex             generated, committed; arXiv wants the source
    two_saturating_operators.pdf
  slides/                22-page explainer deck project (python-pptx)
    assets/                Figures
    output/                identifiability-boundary-popular.pptx / .pdf + 22 previews
  refcheck/              **deliberately not pushed**, see below
```

---

## Reproduction

### Lean proofs

Requires [Elan](https://github.com/leanprover/elan):

```powershell
lake build
```

The toolchain is pinned in `lean-toolchain` (`leanprover/lean4:v4.15.0`) and the
dependencies in `lake-manifest.json`.
`.lake/` is not in this repository; the first build pulls Mathlib and takes a
while.

### Word / PDF manuscript

```powershell
cd paper\docx_build
python render_eqs.py        # LaTeX render of 12 equations → assets_eq/*.png
python make_figs_en.py      # regenerate English Figure 4/5
python make_figs_saturation.py  # add Figure 6/7
python ..\..\tools\sync_refs.py  # sync references from manuscript.md (run first)
python polish.py            # ASCII → formal typographic symbols
python emit_json.py         # content.py → content.json
dotnet run --project Gen -- content.json out.docx
soffice --headless --convert-to pdf --outdir . out.docx
```

Dependencies: Python + matplotlib, `MiKTeX` (`pdflatex`), .NET SDK 9 +
`DocumentFormat.OpenXml 3.1.0`, LibreOffice.

### Consistency checks

```powershell
cd paper
python final_check.py      # 16 checks: numbers, theorem counts, citation numbering, module counts
python verify_dois.py      # online check of the 16 DOIs among 23 references
```

```powershell
python tools\audit_axioms.py   # axiom-dependency audit over the 153 theorems
```

### CI

Every push to `main` and every PR triggers three GitHub Actions jobs:

1. `lake build` — installs the toolchain with [leanprover/lean-action](https://github.com/leanprover/lean-action), fetches the Mathlib cache, compiles every proof
2. `tools/audit_axioms.py` — emits `#print axioms` for all 153 declarations and confirms they depend only on `Classical.choice` / `Quot.sound` / `propext`, with zero `sorryAx`
3. `paper/final_check.py` + `paper/verify_dois.py` — manuscript consistency and online DOI resolution

Job 2 is the one that matters: a passing `lake build` only says the kernel
accepted the proofs. The axiom audit is what stops a claim quietly weakened by a
`sorry`.

---

## Why `paper/refcheck/` is not pushed

This directory holds the **full texts of papers published by other authors**
(Xie et al., ACL 2026; Dorner et al., arXiv 2507.12399; Li et al., arXiv
2603.29121; and two Zenodo mirrors).
They were downloaded locally only to check that every citation in
`paper/manuscript.md` matches its source.

Putting them in a public repository would redistribute copyright-protected
material, so they are **excluded for copyright reasons, not for size**. Fetch
them by DOI; `verify_dois.py` resolves them over the network and does not depend
on the local copies.

## License

Not yet chosen. Copyright in the manuscript text is retained; the licence for the
code is still open.
