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
NAMESPACE = re.compile(r"^\s*namespace\s+([A-Za-z_][A-Za-z0-9_']*)")
END = re.compile(r"^\s*end\s+([A-Za-z_][A-Za-z0-9_']*)")
COMMENT = re.compile(r"^\s*(/|-)")


def collect():
    """Return the fully-qualified name of every theorem/lemma in the package.

    Namespaces nest (Provenance contains Fragmentation), so track the open
    `namespace` stack rather than assuming a single fixed prefix.
    """
    names = []
    for fn in sorted(os.listdir(SRC)):
        if not fn.endswith(".lean"):
            continue
        with open(os.path.join(SRC, fn), encoding="utf-8") as f:
            src = f.read()
        stack = []
        for line in src.splitlines():
            # Skip doc comments: they may contain the words namespace/end.
            if COMMENT.match(line):
                continue
            m = NAMESPACE.match(line)
            if m:
                stack.append(m.group(1))
                continue
            m = END.match(line)
            if m:
                if stack:
                    stack.pop()
                continue
            m = DECL.match(line)
            if m:
                names.append(".".join(stack + [m.group(2)]))
    return names


# Lean reports problems as "path:line:col: error: message", not from column 0.
ERROR = re.compile(r"(^|\s)(error|unknown identifier|unknown constant)\b")


def main():
    names = collect()
    if not names:
        print("no declarations found under %s" % SRC)
        return 1
    print("declarations found: %d\n" % len(names))

    # Written outside the repo so the audit never dirties the working tree.
    # Import every module explicitly: `Provenance.Fragmentation` is not
    # re-exported by the root module, so `import Provenance` alone would not
    # make its declarations visible.
    modules = sorted(fn[:-5] for fn in os.listdir(SRC) if fn.endswith(".lean"))
    fd, path = tempfile.mkstemp(suffix=".lean", prefix="axiom_audit_")
    os.close(fd)
    try:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("import Provenance\n")
            for m in modules:
                f.write("import Provenance.%s\n" % m)
            f.write("\n")
            f.write("\n".join("#print axioms %s" % n for n in names))
            f.write("\n")
        r = subprocess.run(["lake", "env", "lean", path], cwd=ROOT,
                           capture_output=True, text=True,
                           encoding="utf-8", errors="replace")
    finally:
        os.unlink(path)

    out = r.stdout + r.stderr

    errors = [l for l in out.splitlines() if ERROR.search(l)]
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

    # Name the declarations that produced no verdict, so a namespace mistake
    # is obvious instead of just showing up as a count mismatch.
    if clean + len(verdicts) != len(names):
        seen = set(re.findall(r"'([A-Za-z0-9_.']+)'", out))
        missing = [n for n in names if n not in seen]
        if missing:
            print("\nno verdict for %d name(s):" % len(missing))
            for n in missing[:15]:
                print("    %s" % n)

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
