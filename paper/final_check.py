import io
import re

t = io.open(r"D:\lean_proj\source_identifiability\paper\manuscript.md",
            encoding="utf-8").read()

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
    ("DOI count == 12",            len(re.findall(r"https://doi\.org/", t)) == 12),
    ("ref 11 author fixed",        "Sadasivan, V." in t),
    ("no stale Krishna",           "Krishna, T." not in t),
    ("ref 17 = Li et al.",         "Li, W., Aboutorabi" in t),
    ("Dorner paragraph rewritten", "they never optimize over the budget" in t),
    ("no 'dual description' claim","dual description of the floor" not in t),
    ("Xie verbatim quote",         "informational contribution should not be directly equated" in t),
    ("Xie 5.5 quote",              "minimal or negligible human contribution" in t),
    ("Silva conditional hedging",  "decline to claim has already occurred" in t),
    ("Silva classical note",       "classical results in statistical decision theory" in t),
    ("no toolchain typo",          "v4.150" not in t),
    ("no stale overclaim",         "not a measure of contribution in any sense" not in t),
    ("117 theorems consistent",    "117 theorems" in t and "105 theorems" not in t),
    ("nine modules consistent",    t.count("nine modules") + t.count("nine Lean modules") >= 3
                                   and "eight modules" not in t and "eight Lean modules" not in t),
    ("build targets consistent",   "2,532 of 2,533" in t and "2,532/2,533" in t),
    ("calibration theorem cited",  "sign_not_identified_exact" in t),
]

print("--- integrity ---")
for name, ok in checks:
    print("  %-30s %s" % (name, "OK" if ok else "*** FAIL ***"))

print()
print("ALL PASS" if all(v for _, v in checks) else "PROBLEMS REMAIN")