# Neither substitutable for the other

[![CI](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml/badge.svg)](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml)
[![Lean 4](https://img.shields.io/badge/lean-4.15.0-blue.svg)](https://github.com/leanprover/lean4/releases/tag/v4.15.0)

A Lean 4 development formalizing the claim that, under AI-assisted discovery,
the human role and the machine role are not substitutes for one another.

**164 theorems and 20 worked examples**, zero `sorry`, and no axioms beyond
`Classical.choice`, `Quot.sound` and `propext`. 117 cover the main line,
19 the fragmentation side topic, 17 the corpus-selection side topic, and the
remainder the modules those three rest on.

This repository publishes the Lean development. The article that the development
supports is archived separately on Zenodo and cited below; its manuscript
sources are not part of this repository.

## What the modules establish

The main line separates two operations and shows they act on different
quantities. A machine, holding the hypothesis space fixed, reduces a residual
`e_t` toward a floor `Φ` it cannot pass, so its total gain is bounded by
`log(e₀/Φ)` regardless of how many steps it takes. A human moves `Φ` itself, and
that gain is unbounded. Two consequences follow from the same currency:
influence magnitude does not determine signed value, and the sign of a
calibrated contribution estimator is not identified by the data.

| Module | What it settles |
|---|---|
| `Basic.lean` | Total variation, optimal testing, and the ceiling any detector hits |
| `HypothesisTest.lean` | Set-form total variation theorem, Neyman–Pearson power bound |
| `Contamination.lean` | TV mixing, its exponential law under repeated contamination, and a collapse bound |
| `VerifyBudget.lean` | The optimal verification budget is capped independently of reviewer reliability |
| `Refinement.lean` | Observation-layer equivalence classes, and the two currencies formalized |
| `Value.lean` | Separability of influence and value: any reflection-invariant proxy is blind to the split |
| `Incommensurable.lean` | The two are not linearly convertible, stated regime by regime |
| `Calibration.lean` | The sign of the estimated minimum contribution is not identified |
| `Coverage.lean` | Coverage function, submodularity, single-sample marginal gain |
| `Fragmentation.lean` | Adding members earns zero and costs; waiting is worth non-increasingly more |
| `Corpus.lean` | Dilution invariance and the selection ceiling: only the single best item counts |
| `Tagged.lean` | Provenance labels are not read by the floor, so they cannot certify a bound |
| `Examples.lean` | Exact rational worked examples |

`Fragmentation`, `Corpus` and `Tagged` are side topics. `Tagged` and
`Contamination` are formalized in separate carriers and there is no map between
them, so the contamination rate and the provenance vocabulary are kept apart on
purpose.

## Repository layout

```
Provenance.lean            Main entry point (module guide + reproduction notes)
Provenance/                13 Lean modules
tools/audit_axioms.py      Axiom-dependency audit over the 164 theorems (CI gate)
tools/check_metadata.py    CITATION.cff / .zenodo.json / README citation check (CI gate)
tools/strip_bom.py         Strips UTF-8 BOMs from Python sources (ast.parse needs it)
.github/workflows/ci.yml   GitHub Actions: Lean build, axiom audit, metadata
CITATION.cff               Machine-readable citation metadata
.zenodo.json               Zenodo archive metadata (a release mints a versioned DOI)
LICENSE                    MIT
lakefile.lean, lean-toolchain, lake-manifest.json
```

## Reproduction

### Lean proofs

Requires [Elan](https://github.com/leanprover/elan):

```powershell
lake build
```

The toolchain is pinned in `lean-toolchain` (`leanprover/lean4:v4.15.0`) and the
dependencies in `lake-manifest.json`. `.lake/` is not in this repository; the
first build pulls Mathlib and takes a while.

### Checks

```powershell
python tools\audit_axioms.py   # axiom dependencies for all 164 declarations
python tools\check_metadata.py # CITATION.cff / .zenodo.json / README agreement
python tools\strip_bom.py      # strip UTF-8 BOMs
```

`audit_axioms.py` is the one that matters. A passing `lake build` only says the
kernel accepted the proofs; the axiom audit is what stops a claim from being
quietly weakened by a `sorry`.

## CI

Every push to `main` and every pull request runs one job:

1. `lake build` via [leanprover/lean-action](https://github.com/leanprover/lean-action), which installs the pinned toolchain and fetches the Mathlib cache before compiling
2. `tools/audit_axioms.py`, confirming all 164 declarations resolve against only `Classical.choice`, `Quot.sound` and `propext`, with zero `sorryAx`
3. `tools/check_metadata.py`, confirming the citation files and the README agree

## Citation

> **Two saturating operators: non-substitutability of human and machine
> contribution in AI-assisted discovery.** *Huan Li.* Independent Researcher,
> 2026. [ORCID 0009-0004-2695-6825](https://orcid.org/0009-0004-2695-6825).
> DOI: [10.5281/zenodo.23321578](https://doi.org/10.5281/zenodo.23321578)

Cite the concept DOI rather than a version DOI: it resolves to the newest
archived version, so the citation stays correct as new versions are published.

The article is CC-BY-4.0. The code in this repository is MIT; see
[`LICENSE`](LICENSE). `tools/check_metadata.py` fails if the two are collapsed
into one.

The Lean sources behind that claim are the ones in this repository, and
`tools/audit_axioms.py` is the machine check on them.

<!--
  Scholarly metadata for crawlers. This describes the Zenodo record, not a file
  in this repository. It previously carried an `encoding.contentUrl` pointing at
  paper/manuscript.md on raw.githubusercontent.com; that path no longer resolves,
  so the block points only at the DOI.
-->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ScholarlyArticle",
  "headline": "Two saturating operators: non-substitutability of human and machine contribution in AI-assisted discovery",
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
  "sameAs": "https://doi.org/10.5281/zenodo.23321578",
  "datePublished": "2026-10-10",
  "keywords": "AI-assisted discovery, identifiability, total variation, formalization, Lean 4, human-AI collaboration",
  "isAccessibleForFree": true,
  "codeRepository": "https://github.com/lihuanlz/Neither-substitutable-for-the-other"
}
</script>

## License

MIT for the Lean sources and tooling. See [`LICENSE`](LICENSE).
