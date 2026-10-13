# -*- coding: utf-8 -*-
"""Slide 02 - table of contents."""

from theme import *

ITEMS = [
    ("01", "The Bird You Miss", "Not detected is not the same as absent"),
    ("02", "The Detection Ceiling", "Effort never passes that ceiling"),
    ("03", "Truth Is Not a Point", "The protocol decides what you can see"),
    ("04", "The Sign Is Unidentified", "One estimator cannot fix its own sign"),
    ("05", "Claims Become Theorems", "164 Lean 4 proofs, zero sorry, zero added axioms"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "CONTENTS", "What This Deck Covers", 2)

    for i, (num, title, desc) in enumerate(ITEMS):
        y = 1.32 + i * 0.73
        shape(s, 0.78, y + 0.05, 0.40, 0.40, fill="primary", kind="oval")
        tf = tbox(s, 0.78, y + 0.07, 0.40, 0.36, anchor="middle")
        para(tf, num, size=10.5, color="bg", bold=True, align="center",
             font=FONT_NUM, first=True)
        tf = tbox(s, 1.42, y + 0.03, 2.9, 0.34)
        para(tf, title, size=16, color="primary", bold=True, first=True)
        tf = tbox(s, 4.48, y + 0.08, 4.6, 0.32)
        para(tf, desc, size=12, color="primary", first=True)

    return s
