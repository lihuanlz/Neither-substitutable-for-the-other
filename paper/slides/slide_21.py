# -*- coding: utf-8 -*-
"""Slide 21 - the prover caught our own mistakes first."""

from theme import *

ITEMS = [
    ("An inequality was backwards", "The proof failed. Lean killed our own modelling error."),
    ("The residual had no floor", "“More verification is better” refuted; miss rate has a floor."),
    ("Two monotonicities reversed", "We expected the budget to fall with TV. It does not."),
    ("“Fully incommensurable” too strong", "Forced to the exact claim: not linearly convertible."),
]


def build(prs):
    s = new_slide(prs)
    header(s, "WHAT THE FORMALIZATION WAS WORTH", "It Caught Us First", 21)

    for i, (title, body) in enumerate(ITEMS):
        x = 0.55 + (i % 2) * 4.55
        y = 1.34 + (i // 2) * 1.56
        card(s, x, y, 4.35, 1.42, style="peach" if i % 2 == 0 else "ghost")
        tf = tbox(s, x + 0.30, y + 0.20, 3.75, 0.34)
        para(tf, title, size=14, color="primary", bold=True, first=True)
        tf = tbox(s, x + 0.30, y + 0.62, 3.75, 0.66)
        para(tf, body, size=12, color="primary", first=True, line=1.4)

    card(s, 0.55, 4.48, 8.90, 0.52, style="teal")
    tf = tbox(s, 0.85, 4.58, 8.30, 0.32, anchor="middle")
    para(tf, "A modelling error that survives the prover will not survive a "
             "coauthor.",
         size=13, color="bg", bold=True, align="center", first=True)
    return s
