# -*- coding: utf-8 -*-
"""Slide 20 - the twelve formalisation modules."""

from theme import *

MODULES = [
    ("Total variation", "Basic"),
    ("Contamination", "Contamination"),
    ("Coverage", "Coverage"),
    ("Hypothesis testing", "HypothesisTest"),
    ("Refinement and observation", "Refinement"),
    ("Influence and value", "Value"),
    ("Verification budget", "VerifyBudget"),
    ("Incommensurability", "Incommensurable"),
    ("Unidentified calibration", "Calibration"),
    ("Fragmentation", "Fragmentation"),
    ("Corpus as selection", "Corpus"),
    ("Package root", "Provenance"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "FORMALIZATION", "164 Theorems, 13 Modules", 20)

    # Twelve modules in three columns need four rows, so the pitch is tighter
    # than the nine-module layout this slide used to carry.
    for i, (zh, mod) in enumerate(MODULES):
        x = 0.55 + (i % 3) * 3.17
        y = 1.30 + (i // 3) * 0.74
        is_new = mod in ("Calibration", "Fragmentation", "Corpus")
        card(s, x, y, 2.95, 0.62, style="peach" if is_new else "ghost")
        tf = tbox(s, x + 0.24, y + 0.09, 2.50, 0.28)
        para(tf, zh, size=12.5, color="primary", bold=True, first=True)
        tf = tbox(s, x + 0.24, y + 0.37, 2.50, 0.22)
        para(tf, mod, size=9.5, color="primary", first=True)

    card(s, 0.55, 4.34, 8.90, 0.62, style="peach")
    tf = tbox(s, 0.85, 4.48, 8.30, 0.34, anchor="middle")
    para(tf, "Lean 4 v4.15.0 + Mathlib · 164 theorems + 20 worked examples · "
             "zero sorry, zero added axioms",
         size=12, color="primary", bold=True, first=True)
    return s
