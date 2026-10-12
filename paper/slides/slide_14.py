# -*- coding: utf-8 -*-
"""Slide 14 - incommensurability splits into two regimes."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "SYSTEM LAYER · VERDICT", "Incommensurable Has Two Regimes", 14)

    card(s, 0.55, 1.34, 4.35, 2.55, style="peach")
    tf = tbox(s, 0.85, 1.56, 3.80, 0.32)
    para(tf, "When the floor binds", size=14, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 1.98, 3.80, 0.52)
    para(tf, "Incommensurable", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 2.68, 3.80, 1.00)
    para(tf, "Reviewers of any reliability: same budget.",
         size=12, color="primary", first=True, line=1.4)
    para(tf, "Not even a ranking survives.", size=12, color="primary", line=1.4)

    card(s, 5.10, 1.34, 4.35, 2.55, style="ghost")
    tf = tbox(s, 5.40, 1.56, 3.80, 0.32)
    para(tf, "When the floor is slack", size=14, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 1.98, 3.80, 0.52)
    para(tf, "Commensurable", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 2.68, 3.80, 1.00)
    para(tf, "Who is stronger is visible.",
         size=12, color="primary", first=True, line=1.4)
    para(tf, "But the rate is not proportional.",
         size=12, color="primary", line=1.4)

    card(s, 0.55, 4.10, 8.90, 0.85, style="peach")
    tf = tbox(s, 0.85, 4.24, 8.30, 0.60)
    para(tf, "The exact claim: not linearly convertible.",
         size=13, color="primary", bold=True, first=True, line=1.35)
    para(tf, "The stronger version is refuted; formalization rewrote our claim.",
         size=12.5, color="primary", line=1.35)
    return s
