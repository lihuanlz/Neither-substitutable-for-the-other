# -*- coding: utf-8 -*-
"""Slide 16 - the estimator's formula contains no human."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "CALIBRATION LAYER · PROBLEM", "The Standard Estimator Has No Human", 16)

    card(s, 0.55, 1.34, 8.90, 1.35, style="peach")
    tf = tbox(s, 0.55, 1.62, 8.90, 0.80, anchor="middle")
    para(tf, "φ̂  =  1  −  τ̄ / s̄", size=40, color="primary", bold=True,
         align="center", font=FONT_NUM, first=True)

    card(s, 0.55, 2.86, 4.35, 0.66, style="ghost")
    tf = tbox(s, 0.80, 2.98, 3.90, 0.42, anchor="middle")
    para(tf, "τ̄ = the fitted plausibility bar", size=12, color="primary", first=True)

    card(s, 5.10, 2.86, 4.35, 0.66, style="ghost")
    tf = tbox(s, 5.35, 2.98, 3.90, 0.42, anchor="middle")
    para(tf, "s̄ = mean surprisal of the output", size=12, color="primary", first=True)

    card(s, 0.55, 3.68, 8.90, 1.12, style="teal")
    tf = tbox(s, 0.85, 3.88, 8.30, 0.76)
    para(tf, "The human input x is not in the formula.",
         size=17, color="bg", bold=True, first=True, line=1.3)
    para(tf, "It measures how surprising the output is, not how human.",
         size=12.5, color="light", line=1.3)
    return s
