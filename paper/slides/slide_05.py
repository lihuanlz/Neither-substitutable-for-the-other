# -*- coding: utf-8 -*-
"""Slide 05 - the same mistake, side by side."""

from theme import *

ROWS = [
    ("Unseen → recorded as undetected", "Undetected → taken as absent"),
    ("Reference: the true species distribution", "Reference: the published record"),
    ("Change protocol → conclusion changes", "Change model → conclusion flips"),
    ("Repeat surveys → detection rises", "More rounds → actually more accurate?"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "THE PROBLEM · ONE MISTAKE", "AI Repeats This Mistake", 5)

    card(s, 0.55, 1.28, 4.30, 0.50, style="peach")
    tf = tbox(s, 0.55, 1.38, 4.30, 0.30, anchor="middle")
    para(tf, "Ecologists", size=14, color="primary", bold=True, align="center",
         first=True)

    card(s, 5.15, 1.28, 4.30, 0.50, style="teal")
    tf = tbox(s, 5.15, 1.38, 4.30, 0.30, anchor="middle")
    para(tf, "AI-assisted research today", size=14, color="bg", bold=True,
         align="center", first=True)

    shape(s, 5.00, 1.95, 0.012, 2.40, fill="secondary")

    for i, (left, right) in enumerate(ROWS):
        y = 1.98 + i * 0.62
        dot(s, 0.72, y + 0.16, d=0.09, color="accent")
        tf = tbox(s, 0.92, y + 0.03, 3.95, 0.30)
        para(tf, left, size=12.5, color="primary", first=True)
        dot(s, 5.32, y + 0.16, d=0.09, color="primary")
        tf = tbox(s, 5.52, y + 0.03, 3.90, 0.30)
        para(tf, right, size=12.5, color="primary", first=True)

    card(s, 0.55, 4.42, 8.90, 0.62, style="peach")
    tf = tbox(s, 0.85, 4.55, 8.30, 0.36, anchor="middle")
    para(tf, "AI research treats model output as the observation itself.",
         size=13, color="primary", bold=True, first=True)
    return s
