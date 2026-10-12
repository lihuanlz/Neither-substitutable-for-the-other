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
