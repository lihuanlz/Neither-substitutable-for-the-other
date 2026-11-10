# -*- coding: utf-8 -*-
"""Prove that the statement-adequacy guard can fail.

A guard that cannot be made to fail is not a guard. This script copies the
repository into a scratch directory, breaks one thing at a time, and checks
that `tools/statement_adequacy.py` notices each break and that the unbroken
copy still passes.

The breaks are the failure modes this repository has actually made:

  * a prose inequality reversed relative to the statement
  * a symbol given a second, wrong meaning in the same file
  * a prose formula deleted while the statement stayed
  * an acknowledged gap quietly closed
  * a register entry that disagrees with the statement it points at
  * a register entry naming a theorem that does not exist
  * the orientation page citing a theorem that does not exist

    python tools/fault_inject.py

Exits 0 when every break was caught, 1 otherwise. The scratch copy is removed
on the way out, so nothing outside the repository is touched.
"""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROSE = "Provenance/Contamination.lean"
REGISTER = "tools/statement_coverage.json"
ORIENTATION = "ORIENTATION.md"


def make_fixture(base):
    """A scratch copy of everything the guard reads."""
    for rel in ("Provenance", "tools"):
        shutil.copytree(ROOT / rel, base / rel,
                        ignore=shutil.ignore_patterns("__pycache__"))
    for name in (ORIENTATION, "README.md"):
        shutil.copy2(ROOT / name, base / name)
    return base


def run(fixture):
    r = subprocess.run(
        [sys.executable, str(fixture / "tools" / "statement_adequacy.py")],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, r.stdout + r.stderr


def reset(fixture):
    """Put the fixture back the way the repository is."""
    for rel in (PROSE, REGISTER, ORIENTATION, "README.md"):
        shutil.copy2(ROOT / rel, fixture / rel)


def edit(path, old, new):
    text = path.read_text(encoding="utf-8")
    if old not in text:
        return False
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    return True


# --- the breaks ------------------------------------------------------------

def flip_relation_in_prose(f):
    """The prose says the opposite of the statement."""
    return edit(f / PROSE, "`π ≥ 2δ / TV₀`", "`π ≤ 2δ / TV₀`")


def gloss_pi_wrong(f):
    """The same symbol given a second meaning in the same file."""
    return edit(f / PROSE,
                "It is\nnot a rate of contamination and not a fraction of bad "
                "material. -/",
                "`π` is the **contamination rate**. -/")


def drop_anchor(f):
    """The prose formula is gone but the statement is untouched."""
    return edit(f / PROSE,
                "the discriminating weight has to reach `π ≥ 2δ / TV₀`",
                "the discriminating weight has to reach the bound")


def close_a_gap(f):
    """An acknowledged gap is closed without saying so."""
    return edit(f / PROSE,
                "**This file does not formalise that claim,",
                "**This file formalises that claim,")


def break_register(f):
    """The register disagrees with the statement it points at."""
    path = f / REGISTER
    data = json.loads(path.read_text(encoding="utf-8"))
    for claim in data.get("claims", []):
        if claim.get("theorem") == "contamination_budget":
            claim["prose_relation"] = "≤"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8")
    return True


def point_at_missing_theorem(f):
    """The register names a theorem that does not exist."""
    path = f / REGISTER
    data = json.loads(path.read_text(encoding="utf-8"))
    data.setdefault("claims", []).append({
        "theorem": "no_such_theorem",
        "prose_anchor": "x",
        "lean_fragment": "y",
    })
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8")
    return True


def cite_missing_theorem(f):
    """The orientation page cites a theorem that does not exist."""
    path = f / ORIENTATION
    text = path.read_text(encoding="utf-8")
    path.write_text(text + "\nSee `Provenance.no_such_theorem` for the "
                          "details.\n", encoding="utf-8")
    return True


CASES = [
    ("prose inequality reversed", True, flip_relation_in_prose),
    ("symbol given a second, wrong meaning", True, gloss_pi_wrong),
    ("prose formula deleted", True, drop_anchor),
    ("an acknowledged gap quietly closed", True, close_a_gap),
    ("register disagrees with the statement", True, break_register),
    ("register names a theorem that does not exist", True,
     point_at_missing_theorem),
    ("ORIENTATION.md cites a theorem that does not exist", True,
     cite_missing_theorem),
    ("the tree as it stands", False, lambda f: True),
]


def main():
    base = Path(tempfile.mkdtemp(prefix="statement_adequacy_fixture_"))
    try:
        fixture = make_fixture(base)
        results = []
        for name, expect_fail, mutate in CASES:
            reset(fixture)
            applied = mutate(fixture)
            if not applied:
                print("%-58s *** THE BREAK DID NOT APPLY ***" % name)
                results.append(False)
                continue
            code, out = run(fixture)
            fired = code != 0
            ok = fired == expect_fail
            results.append(ok)
            print("%-58s expect_fail=%-5s exit=%d  %s"
                  % (name, expect_fail, code,
                     "OK" if ok else "*** NOT DETECTED ***"))
            for line in out.splitlines():
                if "FAIL" in line:
                    print("      %s" % line.strip()[:140])
        reset(fixture)
        print()
        print("%d/%d behaved as expected" % (sum(results), len(results)))
        return 0 if all(results) else 1
    finally:
        shutil.rmtree(base, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
