# -*- coding: utf-8 -*-
"""How long a self-generated corpus keeps its signal, and at what weight.

Transcription of three theorems in `Provenance/Contamination.lean`:

    totalVariation_mix          TV((1-pi)pH + pi u, (1-pi)pH + pi v) = pi * TV0
    contamination_budget        (delta <= TV(mixed)/2)  ->  pi * TV0 >= 2 * delta
    totalVariation_contamIter   after k rounds:  TV = pi^k * TV0

`--verify` re-reads the Lean file and fails if the statements below have changed,
so this script and the specification cannot drift apart.

Read the bound carefully, because it is easy to invert. `pi` is the weight placed
on the discriminating material in `mix`, not the fraction of bad material. At
`pi = 1` the mixture *is* the hypothesis and the separation is the full `TV0`.
So retaining an advantage `delta` requires

    pi  >=  2 * delta / TV0          (contamination_budget, `contamination_budget`)

a LOWER bound on the weight. A weaker original signal demands a heavier weight,
not more tolerance.

Across k self-consuming rounds the separation is `pi^k * TV0`, so the corpus
survives only while

    pi^k  >=  2 * delta / TV0
    k     <=  log(2 * delta / TV0) / log(pi)

which is the number this script exists to compute. It is the operational form of
the question: how many times can a dialogue corpus be fed back to itself before
an advantage of interest is gone.

An earlier version of this tool and of the paper reported the single-round bound
as `pi <= 2 * delta / TV0`, which is the negation of the theorem.

Usage:
    python tools/contamination_budget.py --verify
    python tools/contamination_budget.py --demo
    python tools/contamination_budget.py --measurements path.json
"""

import io
import json
import math
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEAN = os.path.join(ROOT, "Provenance", "Contamination.lean")

# Literal fragments that must still be in the Lean file for this script to count
# as a faithful transcription. Not formulas: a reformulation of the statement
# trips the check instead of silently passing.
REQUIRED = [
    ("contamination_budget",
     "totalVariation (mix p u π h) (mix p v π h) / 2",
     "the hypothesis is delta bounded by half the mixed total variation"),
    ("contamination_budget",
     "π * totalVariation u v ≥ 2 * δ",
     "the conclusion is pi * TV0 >= 2 * delta"),
    ("totalVariation_mix",
     "= π * totalVariation u v",
     "mixing scales the separation exactly linearly in pi"),
    ("totalVariation_contamIter",
     "= (π ^ k) * totalVariation u v",
     "k rounds attenuate the separation to pi^k"),
]


def read(path):
    return io.open(path, encoding="utf-8").read()


def verify_against_lean() -> int:
    if not os.path.isfile(LEAN):
        print(f"FAIL: no Lean file at {LEAN}")
        return 1
    text = read(LEAN)
    bad = []
    for theorem, fragment, why in REQUIRED:
        if theorem not in text:
            bad.append(f"  theorem `{theorem}` is gone")
        elif fragment not in text:
            bad.append(f"  `{theorem}` no longer contains: {fragment}\n"
                       f"      ({why})")
    if bad:
        print("FAIL: this script no longer matches the Lean specification")
        for b in bad:
            print(b)
        return 1
    print(f"OK: {len(REQUIRED)} fragments of Contamination.lean still match")
    return 0


# ---------------------------------------------------------------------------
# arithmetic transcribed from the statements above
# ---------------------------------------------------------------------------

def pi_required(delta: float, tv0: float) -> float:
    """Weight on the discriminating material needed to retain `delta`.

    From contamination_budget: pi * tv0 >= 2 * delta, so pi >= 2*delta/tv0.
    This is a LOWER bound on the weight, not an upper bound on contamination.
    """
    if tv0 <= 0:
        return float("inf")
    return 2.0 * delta / tv0


def delta_surviving(pi: float, tv0: float) -> float:
    """Largest advantage that survives one mixing round."""
    return pi * tv0 / 2.0


def k_max(pi: float, tv0: float, delta: float) -> int:
    """Self-consuming rounds the corpus survives before the signal drops under
    `delta`.

    From pi^k * tv0 / 2 >= delta, so k <= log(2*delta/tv0) / log(pi).
    """
    if tv0 <= 0:
        return 0
    if pi <= 0:
        return 10 ** 9                     # no mixing weight, no decay
    if pi >= 1:
        return 10 ** 9                     # accumulate_no_decay: factor is 1
    ratio = 2.0 * delta / tv0
    if ratio <= 0:
        return 10 ** 9
    if ratio > 1:
        return 0
    return int(math.floor(math.log(ratio) / math.log(pi)))


# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------

DEMO = {
    "_comment": "SYNTHETIC numbers, not measurements. Shape only.",
    "target_delta": 0.05,
    "strata": [
        {"name": "head-common",    "pi": 0.55, "tv0": 0.30},
        {"name": "mid",            "pi": 0.25, "tv0": 0.30},
        {"name": "tail-rare",      "pi": 0.08, "tv0": 0.30},
        {"name": "tail-very-rare", "pi": 0.03, "tv0": 0.10},
    ],
}


def report(data: dict) -> int:
    delta = float(data["target_delta"])
    print()
    print(f"target advantage to retain: delta = {delta}")
    print("pi is the weight on the discriminating material; pi_required is the")
    print("least weight that retains delta, so the gap is headroom, not slack.")
    print()

    head = (f"{'stratum':<18}{'pi':>7}{'TV0':>8}{'pi_required':>13}"
            f"{'headroom':>10}{'delta kept':>12}{'rounds':>8}")
    print(head)
    print("-" * len(head))

    usable = []
    for s in data["strata"]:
        pi, tv0 = float(s["pi"]), float(s["tv0"])
        preq = pi_required(delta, tv0)
        room = pi - preq
        dk = delta_surviving(pi, tv0)
        k = k_max(pi, tv0, delta)
        if k >= 1:
            usable.append((s["name"], k))
        print(f"{s['name']:<18}{pi:>7.2f}{tv0:>8.2f}{preq:>13.3f}"
              f"{room:>+10.3f}{dk:>12.3f}{k:>8}")

    print()
    if not usable:
        print("No stratum survives a single re-feeding round. A corpus from this")
        print("bank cannot support any claim about training on self-generated")
        print("material. Change the question bank, not the sample size.")
        return 2
    print("Survives at least one self-feeding round: "
          + ", ".join(f"{n} (k<={k})" for n, k in usable))
    thin = [n for n, k in usable if k <= 1]
    if thin:
        print("A stratum at k<=1 cannot be re-fed even once, so a second round of")
        print("training on its own output would be operating below the floor.")
    return 0


def main(argv):
    if "--verify" in argv:
        return verify_against_lean()
    if "--demo" in argv:
        return (verify_against_lean() or report(DEMO))
    for i, a in enumerate(argv):
        if a == "--measurements":
            if verify_against_lean() != 0:
                return 1
            return report(json.loads(read(argv[i + 1])))
    print(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
