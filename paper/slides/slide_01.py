# -*- coding: utf-8 -*-
"""Slide 01 - cover."""

from theme import *


def build(prs):
    s = new_slide(prs)
    set_bg(s, "primary")

    shape(s, 7.55, 2.65, 2.30, 2.30, line="secondary", lw=1.25, kind="oval")
    shape(s, 8.25, 3.35, 0.90, 0.90, line="secondary", lw=1.00, kind="oval")
    shape(s, 8.05, 4.52, 0.30, 0.30, fill="accent", kind="oval")
    shape(s, 6.92, 3.02, 0.18, 0.18, fill="secondary", kind="oval")

    tf = tbox(s, 0.80, 1.02, 6.0, 0.30)
    para(tf, "Formalization · Lean 4 + Mathlib", size=12.5,
         color="light", bold=True, first=True)

    tf = tbox(s, 0.80, 1.44, 8.6, 1.05)
    para(tf, "The Identifiability Limit", size=44, color="bg", bold=True, first=True)

    tf = tbox(s, 0.80, 2.72, 6.0, 1.25)
    para(tf, "How much of this work is human?",
         size=15, color="light", first=True, line=1.5)
    para(tf, "Now 153 machine-checked theorems.",
         size=15, color="light", line=1.5)

    stats = [("153", "proved theorems"), ("0", "sorry, added axioms"), ("12", "formalized modules")]
    for i, (num, lab) in enumerate(stats):
        x = 0.80 + i * 2.10
        tf = tbox(s, x, 4.14, 2.0, 0.58)
        para(tf, num, size=30, color="light", bold=True, font=FONT_NUM, first=True)
        tf = tbox(s, x, 4.70, 2.0, 0.28)
        para(tf, lab, size=11, color="light", first=True)

    return s
