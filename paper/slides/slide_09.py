# -*- coding: utf-8 -*-
"""Slide 09 - the three budget numbers."""

from theme import *

CARDS = [
    ("N_c", "3.793", "Set by reviewer reliability", "peach", "primary"),
    ("N_0", "3.474", "Hard cap, no human in it", "ghost", "primary"),
    ("N*", "3.474", "The smaller: here N_0", "teal", "bg"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "CONTENT LAYER · RESULT 2 (CONT.)", "Where the Budget Sticks: Three Numbers", 9)

    for i, (name, val, desc, style, txt) in enumerate(CARDS):
        x = 0.55 + i * 3.17
        card(s, x, 1.34, 2.95, 1.85, style=style)
        tf = tbox(s, x + 0.28, 1.56, 2.40, 0.32)
        para(tf, name, size=14, color=txt, bold=True, font=FONT, first=True)
        tf = tbox(s, x + 0.28, 1.92, 2.45, 0.62)
        para(tf, val, size=34, color=txt,
             bold=True, font=FONT_NUM, first=True)
        tf = tbox(s, x + 0.28, 2.62, 2.45, 0.46)
        para(tf, desc, size=11, color=txt, first=True, line=1.35)

    card(s, 0.55, 3.42, 8.90, 0.98, style="peach")
    tf = tbox(s, 0.85, 3.60, 8.30, 0.64)
    para(tf, "Perfect reviewers still cap the budget at 3.474.",
         size=14, color="primary", bold=True, first=True, line=1.35)
    para(tf, "The remaining misses no headcount can recover.",
         size=13, color="primary", line=1.35)

    dot(s, 0.72, 4.72)
    tf = tbox(s, 0.92, 4.58, 8.5, 0.32)
    para(tf, "In 83.97% of parameter sets the detector binds, not the person.",
         size=12.5, color="primary", bold=True, first=True)
    source(s, "Parameters: TV = 0.09, q = 0.5, λ = 1, as in Fig. 2 "
              "(N_c: another reviewer p)",
           y=5.06, x=0.55, w=6.6)
    return s
