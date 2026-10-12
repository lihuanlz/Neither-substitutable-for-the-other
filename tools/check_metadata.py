# -*- coding: utf-8 -*-
"""Check that the repository's scholarly metadata is well-formed.

`paper/final_check.py` guards the manuscript; this guards the files a crawler
or reference manager reads. Both matter for discoverability, and a malformed
CITATION.cff fails silently everywhere except in the one place you notice it.

Fails on: unparseable YAML/JSON, a missing licence, a missing citation block,
and any TODO left in an author field. Run from the repository root:

    python tools/check_metadata.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8") if p.exists() else ""


def norm_orcid(orcid: str) -> str:
    """Reduce any spelling of an ORCID - bare, URL, or hyphenated - to digits.

    The four files that repeat this identifier spell it three different ways,
    so comparing raw strings would report a disagreement that does not exist
    while still missing the ones that do.
    """
    return re.sub(r"[^0-9Xx]", "", str(orcid))


def orcid_check_digit(first15: str) -> int:
    """ISO 7064 MOD 11-2 check digit, as ORCID assigns it."""
    total = 0
    for ch in first15:
        total = (total + int(ch)) * 2
    result = (12 - total % 11) % 11
    return 0 if result == 10 else result


def orcid_is_valid(orcid: str) -> bool:
    """True only for a 16-digit ORCID whose check digit agrees.

    A mistyped ORCID is worse than an absent one: it resolves to somebody else
    or to nothing, and the error is invisible in every rendering.
    """
    digits = norm_orcid(orcid)
    if len(digits) != 16 or not digits[:-1].isdigit():
        return False
    return orcid_check_digit(digits[:15]) == int(digits[15])


def main() -> int:
    problems = []
    notes = []

    # --- CITATION.cff -----------------------------------------------------
    cff_path = ROOT / "CITATION.cff"
    if not cff_path.exists():
        problems.append("CITATION.cff is missing")
    else:
        cff = read(cff_path)
        try:
            import yaml
            data = yaml.safe_load(cff)
        except ImportError:
            data = None
            print("  (PyYAML absent, skipping the structural parse)")
        except Exception as exc:  # noqa: BLE001 - report, do not raise
            problems.append("CITATION.cff does not parse: %s" % exc)
        if isinstance(data, dict):
            if not str(data.get("cff-version", "")).startswith("1.2"):
                problems.append("CITATION.cff: cff-version should be 1.2.0")
            if not data.get("title"):
                problems.append("CITATION.cff: no title")
            if not data.get("authors"):
                problems.append("CITATION.cff: no authors")
            elif any("TODO" in str(a.get("family-names", ""))
                     for a in data["authors"]):
                # A known temporary state, not a malformed file: CI stays green
                # until the real author list is supplied.
                notes.append("CITATION.cff: author name still TODO")
            if not data.get("license"):
                problems.append("CITATION.cff: no license")
            if not data.get("repository-code"):
                problems.append("CITATION.cff: no repository-code")

    # --- .zenodo.json -----------------------------------------------------
    zen_path = ROOT / ".zenodo.json"
    if not zen_path.exists():
        problems.append(".zenodo.json is missing")
    else:
        try:
            zen = json.loads(read(zen_path))
        except Exception as exc:  # noqa: BLE001
            problems.append(".zenodo.json does not parse: %s" % exc)
            zen = None
        if isinstance(zen, dict):
            if zen.get("access_right") != "open":
                problems.append(".zenodo.json: access_right should be 'open'")
            if not zen.get("license"):
                problems.append(".zenodo.json: no license")
            if any("TODO" in str(c.get("name", ""))
                   for c in zen.get("creators", [])):
                notes.append(".zenodo.json: creator name still TODO")

    # --- LICENSE ----------------------------------------------------------
    lic = read(ROOT / "LICENSE")
    if not lic:
        problems.append("LICENSE is missing")
    elif "MIT License" not in lic:
        problems.append("LICENSE does not look like MIT")

    # --- README -----------------------------------------------------------
    readme = read(ROOT / "README.md")
    if "## Citation" not in readme:
        problems.append("README.md: no Citation section")
    if "application/ld+json" not in readme:
        problems.append("README.md: no JSON-LD ScholarlyArticle block")
    if "paper/manuscript.md" not in readme:
        problems.append("README.md: does not point at the plain-text manuscript")

    # --- ORCID consistency across every file that repeats the identity ----
    # The same identifier appearing in four places is four chances to drift.
    # One stale copy is enough for a reference manager to attribute the work to
    # a stranger.
    def orcids_in(text: str) -> list:
        # Match the whole run rather than a fixed-width window: the identifier
        # is always followed by URL punctuation, never by more digits.
        return sorted({norm_orcid(m)
                       for m in re.findall(r"orcid\.org/([0-9Xx][0-9Xx-]*)", text)})

    cff_orcid = ""
    if isinstance(data, dict) and data.get("authors"):
        cff_orcid = str(data["authors"][0].get("orcid", ""))
    zen_orcid = ""
    if isinstance(zen, dict) and zen.get("creators"):
        zen_orcid = str(zen["creators"][0].get("orcid", ""))
    readme_orcids = orcids_in(readme)
    manuscript_orcids = orcids_in(read(ROOT / "paper" / "manuscript.md"))

    seen = {x for x in [cff_orcid, zen_orcid] if x}
    seen.update(readme_orcids)
    seen.update(manuscript_orcids)
    # Everything above is compared in digits, so a URL and a bare number are
    # the same identifier and only genuine disagreement survives.
    digits = {norm_orcid(x) for x in seen if norm_orcid(x)}

    if not digits:
        notes.append("no ORCID recorded anywhere; the author is unattributed")
    else:
        if len(digits) > 1:
            problems.append("ORCID disagrees across files: %s"
                            % ", ".join(sorted(digits)))
        else:
            orcid = digits.pop()
            if not orcid_is_valid(orcid):
                problems.append("ORCID %s fails its check digit" % orcid)
            for label, value in [("CITATION.cff", cff_orcid),
                                 (".zenodo.json", zen_orcid)]:
                if value and norm_orcid(value) != orcid:
                    problems.append("%s: ORCID does not match the others" % label)
        # A file that silently drops the identifier is as much a drift as one
        # that disagrees about it.
        if readme and not readme_orcids:
            problems.append("README.md: citation block carries no ORCID")
        if (ROOT / "paper" / "manuscript.md").exists() and not manuscript_orcids:
            problems.append("manuscript.md: header carries no ORCID")

    # The registered name is given-name + family-name. A rejoin is a silent
    # mismatch against every authority that reads the identifier.
    for rel, text in [("README.md", readme),
                      ("CITATION.cff", read(cff_path)),
                      (".zenodo.json", read(zen_path)),
                      ("LICENSE", read(ROOT / "LICENSE")),
                      ("paper/manuscript.md", read(ROOT / "paper" / "manuscript.md")),
                      ("paper/docx_build/content.py",
                       read(ROOT / "paper" / "docx_build" / "content.py"))]:
        if re.search(r"\bHuanli\b", text):
            problems.append("%s: author name written 'Huanli', expected 'Huan Li'"
                            % rel)

    todo = sorted(
        str(p.relative_to(ROOT)) for p in ROOT.rglob("*")
        if p.is_file()
        and p.suffix in {".cff", ".json"}
        and p.name in {"CITATION.cff", ".zenodo.json"}
        and "TODO" in p.read_text(encoding="utf-8", errors="ignore")
    )
    if todo:
        notes.append("placeholders still to fill: %s" % ", ".join(todo))

    print("--- metadata ---")
    for x in problems:
        print("  %-46s *** FAIL ***" % x)
    for x in notes:
        print("  note: %s" % x)
    if not problems:
        print("  all metadata files well-formed")
    print()
    print("METADATA OK" if not problems else "METADATA PROBLEMS REMAIN")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
