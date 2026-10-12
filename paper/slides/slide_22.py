# -*- coding: utf-8 -*-
"""Slide 22 - takeaways and closing position."""

from theme import *

TAKEAWAYS = [
    "Unseen ≠ absent. AI treats model output as the observation.",
    "Detection has a ceiling. Effort does not move it.",
    "The verification budget has a cap with no human in it.",
    "Influence does not measure value. Value needs a sign.",
    "The sign is not identified either; an out-of-distribution bar decides it.",
    "153 theorems, zero sorry, zero added axioms, reproducible build.",
]


def build(prs):
    s = new_slide(prs)
    header(s, "CLOSING", "What We Proved", 22)

    for i, t in enumerate(TAKEAWAYS):
        y = 1.32 + i * 0.52
        dot(s, 0.78, y + 0.16, d=0.11)
        tf = tbox(s, 1.02, y + 0.02, 8.35, 0.32)
        para(tf, t, size=12.5, color="primary", first=True)

    card(s, 0.55, 4.38, 8.90, 0.64, style="teal")
    tf = tbox(s, 0.85, 4.44, 8.30, 0.52)
    para(tf, "We do not attack existing measures; they work for their "
             "stated purpose.",
         size=11, color="bg", first=True, line=1.25)
    para(tf, "We turned their prose warnings into theorems a machine can "
             "check.",
         size=11, color="light", line=1.25)
    return s
