import re
import sys
from pathlib import Path

# Resolved relative to this file so the check runs against the checkout it
# lives in, not against whatever happens to sit on the author's machine.
MD = Path(__file__).resolve().parent / "manuscript.md"

t = MD.read_text(encoding="utf-8")

body = t.split("## References")[0]
main = body.split("## Figure legends")[0]

print("main text words        :", len(main.split()))
print("figure legends         :",
      len(body.split("## Figure legends")[1].split("## Visual summary")[0].split()))
print("visual summary         :",
      len(body.split("## Visual summary")[1].split()))
print("methods                :",
      len(re.search(r"## Methods(.*?)## References", t, re.S).group(1).split()))
print("references             :",
      len(re.findall(r"(?m)^\d+\. ", t.split("## References")[1])))
print()

# Working notes quote Lean signatures verbatim, so they rot the moment a
# theorem is renamed. Nothing else in the repo would notice: the notes are not
# built into the PDF and no other check reads them. This walks every Lean-shaped
# name in paper/notes/ and requires it to exist in the Lean sources.
NOTES = Path(__file__).resolve().parent / "notes"
LEAN = Path(__file__).resolve().parent.parent / "Provenance"

lean_text = ""
for _f in sorted(LEAN.glob("*.lean")):
    lean_text += _f.read_text(encoding="utf-8")

# Names appear in two places, and reading only the first one is how the first
# version of this check passed a misspelled `fragmentation_squeeze` that lived
# solely inside a fenced block: inline backticks, and ```lean fences.
IDENT = re.compile(r"[a-z][A-Za-z0-9]*_[A-Za-z0-9_]+|[a-z]+[A-Z][A-Za-z0-9]*")
FENCE = re.compile(r"```lean\n(.*?)```", re.S)
TICK = re.compile(r"`([^`\n]+)`")

note_problems = []
if NOTES.is_dir():
    for _n in sorted(NOTES.glob("*.md")):
        _txt = _n.read_text(encoding="utf-8")
        _fenced = " ".join(FENCE.findall(_txt))
        _inline = " ".join(TICK.findall(_txt))
        for _tok in set(IDENT.findall(_fenced)) | set(IDENT.findall(_inline)):
            if _tok not in lean_text:
                note_problems.append(f"{_n.name}: {_tok}")

checks = [
    # Scoped to the reference list on purpose. The front matter now carries the
    # paper's own DOI, which is an identifier for this work, not a citation of
    # someone else's, and counting it here would silently change the meaning of
    # the check the first time either one moved.
    ("DOI count == 16",            len(re.findall(r"https://doi\.org/",
                                                  t.split("## References")[-1])) == 16),
    ("ref 11 author fixed",        "Sadasivan, V." in t),
    ("no stale Krishna",           "Krishna, T." not in t),
    ("ref 17 = Li et al.",         "Li, W., Aboutorabi" in t),
    ("Dorner paragraph rewritten", "never optimize over the budget" in t),
    ("no 'dual description' claim","dual description of the floor" not in t),
    ("Xie verbatim quote",         "informational contribution should not be directly equated" in t),
    ("Xie 5.5 quote",              "minimal or negligible human contribution" in t),
    ("Silva conditional hedging",  "decline to claim has already occurred" in t),
    ("Silva classical note",       "classical results in statistical decision theory" in t),
    ("no toolchain typo",          "v4.150" not in t),
    ("no stale overclaim",         "not a measure of contribution in any sense" not in t),
    ("164 theorems consistent",    "164 theorems" in t and "136 theorems" not in t
                                   and "153 theorems" not in t),
    ("thirteen modules consistent", t.count("thirteen modules") >= 2
                                   and "twelve modules" not in t
                                   and "nine modules" not in t and "nine Lean modules" not in t),
    ("corpus module described",    "dilution invariance and selection filters" in t),
    ("tagged module described",    "tagged-corpus module" in t
                                   and "machine_item_takes_over" in t
                                   and "source_irrelevant" in t),
    ("contamination in section 3","π · TV₀ / 2" in t and "π^k · TV₀" in t),
    ("p_bind closed form",         "p_bind = 1 − c / (L · d · λ · TV)" in t),
    ("falsification conditions",   "what would undo them" in t
                                   and "starN_le_floorRounds" in t),
    ("calibration theorem cited",  "sign_not_identified_exact" in t),
    ("notes cite real Lean names", not note_problems),
]

print("--- integrity ---")
for name, ok in checks:
    print("  %-30s %s" % (name, "OK" if ok else "*** FAIL ***"))

# Naming the offending token matters more than the bare FAIL: the failure mode
# is a renamed theorem, and "final_check failed" does not say which one.
if note_problems:
    print()
    print("--- unknown identifiers quoted in paper/notes/ ---")
    for p in note_problems:
        print("  " + p)

print()
ok = all(v for _, v in checks)
print("ALL PASS" if ok else "PROBLEMS REMAIN")

# Exit non-zero on failure so this can gate a CI job.
sys.exit(0 if ok else 1)