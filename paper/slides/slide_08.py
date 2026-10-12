# -*- coding: utf-8 -*-
"""Slide 08 - the verification floor, data visualisation."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "CONTENT LAYER · RESULT 2", "More Verification Is Not Better", 8)

    s.shapes.add_picture(asset("chart_floor.png"), IN(0.55), IN(1.34), width=IN(4.85))

    tf = tbox(s, 5.62, 1.40, 3.83, 0.42)
    para(tf, "Miss rate falls, then stops",
         size=15, color="primary", bold=True, first=True)

    points = [
        "Each round multiplies the miss probability: geometric decay",
        "But there is a floor it never falls below",
        "Floor = λ × TV: how separable the two are",
    ]
    for i, p in enumerate(points):
        y = 2.02 + i * 0.62
        dot(s, 5.75, y + 0.15)
        tf = tbox(s, 5.95, y + 0.01, 3.50, 0.60)
        para(tf, p, size=12, color="primary", first=True, line=1.35)

    card(s, 5.62, 3.98, 3.83, 0.62, style="peach")
    tf = tbox(s, 5.78, 4.08, 3.52, 0.42, anchor="middle")
    para(tf, "Floor T = 0.09: more reviewers stop here",
         size=11.5, color="primary", bold=True, first=True)

    source(s, "Parameters: TV = 0.09, q = 0.5, λ = 1 (as in Fig. 2)",
           y=4.52, x=0.55, w=4.75)
    return s
