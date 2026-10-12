# -*- coding: utf-8 -*-
"""Slide 07 - the detector ceiling, stated as two formulas."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "CONTENT LAYER · RESULT 1", "The Best Detector Is Already Computed", 7)

    card(s, 0.55, 1.32, 4.35, 1.80, style="peach")
    tf = tbox(s, 0.85, 1.56, 3.85, 0.74)
    para(tf, "TV / 2", size=38, color="primary", bold=True, font=FONT_NUM, first=True)
    tf = tbox(s, 0.85, 2.44, 3.85, 0.46)
    para(tf, "Best any detector beats a coin flip",
         size=12, color="primary", first=True, line=1.35)

    card(s, 5.10, 1.32, 4.35, 1.80, style="ghost")
    tf = tbox(s, 5.40, 1.62, 3.85, 0.66)
    para(tf, "(1 − TV) / 2", size=30, color="primary", bold=True,
         font=FONT_NUM, first=True)
    tf = tbox(s, 5.40, 2.44, 3.85, 0.46)
    para(tf, "Smallest error rate of the best detector",
         size=12, color="primary", first=True, line=1.35)

    card(s, 0.55, 3.26, 8.90, 0.54, style="ghost")
    tf = tbox(s, 0.85, 3.40, 8.30, 0.30, anchor="middle")
    para(tf, "TV = how far apart two distributions are, 0 to 1. "
             "TV = 0 means you cannot tell them apart.",
         size=12.5, color="primary", first=True)

    card(s, 0.55, 3.94, 8.90, 0.94, style="peach")
    tf = tbox(s, 0.85, 4.08, 8.30, 0.70)
    para(tf, "Example: reference p=(0.42, 0.28, 0.18, 0.12), "
             "model q=(0.10, 0.20, 0.40, 0.30)",
         size=12, color="primary", first=True, line=1.35)
    para(tf, "TV = 0.40 → at best 0.20 above chance, error rate 0.30.",
         size=12, color="primary", bold=True, line=1.35)

    source(s, "Source: Fig. 1 — the Neyman-Pearson / Le Cam two-point "
              "lemma, not our result", y=4.98)
    return s
