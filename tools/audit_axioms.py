"""Check that every theorem in the package depends on nothing but Lean's three
standard axioms.

`grep`ping the sources for `axiom` or `sorry` is not enough: a declaration can
acquire an unexpected dependency without either word appearing. This asks Lean
itself, by emitting one `#print axioms` directive per theorem and parsing the
verdict.

    python tools/audit_axioms.py

Exits non-zero if any theorem depends on `sorryAx`, if a name fails to
resolve, or if the number of verdicts does not match the number of theorems.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Provenance")

# The standard axioms a Mathlib proof may use. Nothing else is acceptable
# without an explicit, deliberate decision.
STANDARD = {"Classical.choice", "Quot.sound", "propext"}

DECL = re.compile(r"^\s*(theorem|lemma)\s+([A-Za-z_][A-Za-z0-9_'.]*)")
NAMESPACE = re.compile(r"^\s*namespace\s+Provenance\b", re.M)


def collect():
    """Return the fully-qualified name of every theorem/lemma in the package."""
    names = []
    for fn in sorted(os.listdir(SRC)):
        if not fn.endswith(".lean"):
            continue
        with open(os.path.join(SRC, fn), encoding="utf-8") as f:
            src = f.read()
        # Most modules open `namespace Provenance`; Calibration.lean does not.
        prefix = "Provenance." if NAMESPACE.search(src) else ""
        for line in src.splitlines():
            m = DECL.match(line)
            if m:
                names.append(prefix + m.group(2))
    return names


def main():
    names = collect()
    if not names:
        print("no declarations found under %s" % SRC)
        return 1
    print("declarations found: %d\n" % len(names))

    # Written outside the repo so the audit never dirties the working tree.
    fd, path = tempfile.mkstemp(suffix=".lean", prefix="axiom_audit_")
    os.close(fd)
    try:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("import Provenance\n\n")
            f.write("\n".join("#print axioms %s" % n for n in names))
            f.write("\n")
        r = subprocess.run(["lake", "env", "lean", path], cwd=ROOT,
                           capture_output=True, text=True,
                           encoding="utf-8", errors="replace")
    finally:
        os.unlink(path)

    out = r.stdout + r.stderr

    errors = [l for l in out.splitlines() if l.startswith("error")]
    sorry = re.findall(r"\bsorryAx\b", out)
    verdicts = re.findall(r"depends on axioms: \[([^\]]*)\]", out)
    clean = len(re.findall(r"does not depend on any axioms", out))

    used = set()
    for group in verdicts:
        for a in group.split(","):
            a = a.strip().strip("'").strip()
            if a:
                used.add(a)

    print("resolved without error : %d / %d" % (clean + len(verdicts), len(names)))
    print("no axioms at all       : %d" % clean)
    print("axioms used            : %s" % (", ".join(sorted(used)) or "none"))
    print("sorryAx occurrences    : %d" % len(sorry))
    print("errors                 : %d" % len(errors))

    for e in errors[:10]:
        print("    %s" % e)

    unexpected = sorted(used - STANDARD)
    failed = False

    if sorry:
        print("\nFAIL: a declaration depends on sorryAx")
        failed = True
    if errors:
        print("\nFAIL: %d name(s) did not resolve" % len(errors))
        failed = True
    if clean + len(verdicts) != len(names):
        print("\nFAIL: got %d verdicts for %d declarations"
              % (clean + len(verdicts), len(names)))
        failed = True
    if unexpected:
        print("\nFAIL: non-standard axioms: %s" % ", ".join(unexpected))
        failed = True

    if failed:
        return 1
    print("\nPASS: all %d declarations rest on the standard axioms only" % len(names))
    return 0


if __name__ == "__main__":
    sys.exit(main())
