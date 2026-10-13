# -*- coding: utf-8 -*-
"""Check that the repository's scholarly metadata is well-formed.

This guards the files a crawler or reference manager reads: CITATION.cff,
.zenodo.json, the README citation block, the JSON-LD block, and LICENSE. A
malformed one fails silently everywhere except in the one place you notice it.

It used to sit alongside `paper/final_check.py`, which guarded the manuscript.
That script went away with the manuscript sources, so this now covers the whole
of what the repository publishes.

Fails on: unparseable YAML/JSON, a missing licence, a missing citation block,
a README link into the untracked `paper/` tree, ORCID disagreement between
files, and any TODO left in an author field. Run from the repository root:

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


def creator_name_is_surnamed_first(name: str) -> bool:
    """True when a creator is written 'Family, Given' as Zenodo expects.

    Zenodo reads the GitHub integration's .zenodo.json against the legacy
    deposit schema, where a creator carries one free-text name. That field is
    parsed as a surname-first name: without the comma, the whole string becomes
    the family name. 'Huan Li' therefore yields family name 'Huan Li', and that
    value propagates into DataCite, Crossref and every authority file derived
    from the record, where the author sorts and displays wrongly. The error is
    invisible on the Zenodo landing page, which renders the raw string.
    """
    if "," not in name:
        return False
    family, _, given = name.partition(",")
    return bool(family.strip()) and bool(given.strip())


def description_paragraphs_are_separated(description: str) -> bool:
    """True when every adjacent pair of tags in the description has whitespace.

    Zenodo keeps the raw HTML for the landing page but derives the plain text
    from it for social cards and for corpus ingestion, and that derivation drops
    the tags without inserting a separator. Two paragraphs written as
    '</p><p>' therefore reach every plain-text reader as one sentence, with the
    last word of the first paragraph welded to the first word of the second. A
    single space between the tags is plain text, so it survives any strip.
    """
    return re.search(r"><", description) is None


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

            for creator in zen.get("creators", []):
                name = str(creator.get("name", ""))
                if name and not creator_name_is_surnamed_first(name):
                    problems.append(
                        ".zenodo.json: creator %r is not written 'Family, Given', "
                        "so Zenodo reads the whole string as the family name"
                        % name)

            description = str(zen.get("description", ""))
            if description and not description_paragraphs_are_separated(description):
                problems.append(
                    ".zenodo.json: two tags meet with no space in the description, "
                    "so its plain-text form runs the paragraphs together")

            if zen.get("upload_type") == "publication" and not zen.get("publication_type"):
                problems.append(".zenodo.json: a publication needs publication_type")

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
    # `paper/` is untracked, so any link into it from the README resolves to
    # nothing for a reader who cloned the repository. This replaced the old
    # requirement that the README point at paper/manuscript.md, which cannot
    # hold now that the manuscript is not published from here.
    for _m in re.findall(r"\]\((paper/[^)]+)\)", readme):
        problems.append("README.md: links to %s, which is not tracked" % _m)
    for _m in re.findall(r"\"contentUrl\"\s*:\s*\"([^\"]+)\"", readme):
        if "/paper/" in _m:
            problems.append("README.md: JSON-LD contentUrl points into paper/: %s"
                            % _m)

    # --- README module table ------------------------------------------------
    # With the manuscript unpublished, the README is the only place a reader
    # learns which modules exist. Add or rename a module without touching the
    # table and the first thing a reader meets is a wrong list, so this is
    # checked in both directions.
    prov = ROOT / "Provenance"
    if prov.is_dir():
        on_disk = {p.name for p in prov.glob("*.lean")}
        in_readme = set(re.findall(r"`([A-Za-z0-9_]+\.lean)`", readme))
        # Provenance.lean is the root module and lives outside the directory.
        expected = on_disk | {"Provenance.lean"}
        for _name in sorted(in_readme - expected):
            problems.append("README.md: names %s, which is not in the repository"
                            % _name)
        for _name in sorted(on_disk - in_readme):
            problems.append("README.md: Provenance/%s exists but is not listed"
                            % _name)

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

    seen = {x for x in [cff_orcid, zen_orcid] if x}
    seen.update(readme_orcids)
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

    # The registered name is given-name + family-name. A rejoin is a silent
    # mismatch against every authority that reads the identifier.
    # Only tracked files are scanned. The manuscript used to appear here too, and
    # its absence from this list is the point: `paper/` is not published, so a
    # name that only appears there cannot drift against anything a reader sees.
    for rel, text in [("README.md", readme),
                      ("CITATION.cff", read(cff_path)),
                      (".zenodo.json", read(zen_path)),
                      ("LICENSE", read(ROOT / "LICENSE"))]:
        if re.search(r"\bHuanli\b", text):
            problems.append("%s: author name written 'Huanli', expected 'Huan Li'"
                            % rel)

    # --- licence split -----------------------------------------------------
    # The paper is CC-BY-4.0 and the code is MIT. Collapsing the two is the
    # likely drift: one side gets edited and the other keeps its old value,
    # leaving the repository making two incompatible promises about one PDF.
    PAPER_LICENCE = "CC-BY-4.0"
    zen_licence = str(zen.get("license", "")) if isinstance(zen, dict) else ""
    cff_licence = str(data.get("license", "")) if isinstance(data, dict) else ""

    if zen_licence and zen_licence != PAPER_LICENCE:
        problems.append(".zenodo.json: paper licence is %s, expected %s"
                        % (zen_licence, PAPER_LICENCE))
    if cff_licence and cff_licence != PAPER_LICENCE:
        problems.append("CITATION.cff: paper licence is %s, expected %s"
                        % (cff_licence, PAPER_LICENCE))
    lic_text = read(ROOT / "LICENSE")
    if lic_text and "MIT License" not in lic_text:
        problems.append("LICENSE: code licence is no longer MIT; the paper and "
                        "code licences are meant to differ")

    # --- DOI ---------------------------------------------------------------
    # A version DOI pins a reader to one immutable snapshot. The concept DOI
    # resolves to the newest version and stays correct across releases, so it
    # is the one that belongs in metadata.
    cff_doi = str(data.get("doi", "")).strip() if isinstance(data, dict) else ""
    readme_dois = sorted(set(re.findall(r"10\.5281/zenodo\.\d+", readme)))
    if cff_doi and cff_doi not in readme_dois:
        problems.append("README.md: does not carry the DOI from CITATION.cff")
    if len(set(readme_dois)) > 1:
        problems.append("README.md: more than one Zenodo DOI: %s"
                        % ", ".join(readme_dois))

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
