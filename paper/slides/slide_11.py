# -*- coding: utf-8 -*-
"""Slide 11 - observation equivalence classes, with a small diagram."""

from theme import *

ROWS = [
    ("Strict", 3),
    ("Medium", 2),
    ("Loose", 6),
]


def build(prs):
    s = new_slide(prs)
    header(s, "SYSTEM LAYER · CONCEPT", "Truth Is a Class, Not a Point", 11)

    tf = tbox(s, 0.55, 1.40, 4.35, 0.85)
    para(tf, "Old way: the answer is one point; estimate the distance.",
         size=12.5, color="primary", first=True, line=1.45)

    tf = tbox(s, 0.55, 2.34, 4.35, 0.85)
    para(tf, "Our way: which states look identical under this protocol?",
         size=12.5, color="primary", first=True, line=1.45)

    card(s, 0.55, 3.34, 4.35, 1.06, style="peach")
    tf = tbox(s, 0.80, 3.54, 3.90, 0.70)
    para(tf, "They form a class [s*]. Error becomes a function of the "
             "protocol.",
         size=12, color="primary", first=True, line=1.4)

    for i, (lab, k) in enumerate(ROWS):
        y = 1.50 + i * 1.00
        box_w = 0.42 + 0.40 * k
        shape(s, 6.36, y - 0.06, box_w, 0.40, fill=None, line="secondary",
              lw=1.25, kind="round", radius=0.18)
        for j in range(6):
            cx = 6.56 + j * 0.40
            filled = j < k
            shape(s, cx, y + 0.02, 0.20, 0.20,
                  fill=("accent" if filled else "bg"),
                  line=(None if filled else "secondary"), lw=1.0, kind="oval")
        tf = tbox(s, 5.28, y + 0.04, 0.95, 0.28)
        para(tf, lab, size=11, color="primary", first=True)
    tf = tbox(s, 5.28, 4.24, 4.17, 0.70)
    para(tf, "The same truth mixes different states under different protocols.",
         size=11, color="primary", first=True, line=1.45)
    return s
