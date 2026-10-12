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
    ("153 theorems consistent",    "153 theorems" in t and "136 theorems" not in t
                                   and "117 theorems" not in t),
    ("twelve modules consistent",  t.count("twelve modules") >= 2
                                   and "nine modules" not in t and "nine Lean modules" not in t),
    ("corpus module described",    "dilution invariance and selection filters" in t),
    ("calibration theorem cited",  "sign_not_identified_exact" in t),
]

print("--- integrity ---")
for name, ok in checks:
    print("  %-30s %s" % (name, "OK" if ok else "*** FAIL ***"))

print()
ok = all(v for _, v in checks)
print("ALL PASS" if ok else "PROBLEMS REMAIN")

# Exit non-zero on failure so this can gate a CI job.
sys.exit(0 if ok else 1)