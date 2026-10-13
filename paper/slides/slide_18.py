# -*- coding: utf-8 -*-
"""Slide 18 - it is not even a proportion."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "CALIBRATION LAYER · CONSEQUENCE", "It Is Not Even a Proportion", 18)

    card(s, 0.55, 1.34, 4.35, 1.85, style="peach")
    tf = tbox(s, 0.85, 1.58, 3.80, 0.46)
    para(tf, "Bounded above", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 2.14, 3.80, 0.85)
    para(tf, "φ̂ < 1 always.", size=12.5, color="primary", bold=True,
         first=True, line=1.4)
    para(tf, "More surprising → closer to 1.", size=12.5, color="primary", line=1.4)

    card(s, 5.10, 1.34, 4.35, 1.85, style="ghost")
    tf = tbox(s, 5.40, 1.58, 3.80, 0.46)
    para(tf, "No lower bound", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 2.14, 3.80, 0.85)
    para(tf, "φ̂ goes below 0.", size=12.5, color="primary",
         bold=True, first=True, line=1.4)
    para(tf, "More predictable → further down.", size=12.5, color="primary", line=1.4)

    card(s, 0.55, 3.38, 8.90, 0.92, style="teal")
    tf = tbox(s, 0.85, 3.56, 8.30, 0.58, anchor="middle")
    para(tf, "Reading it as a proportion in [0,1] fails in the estimator.",
         size=14, color="bg", bold=True, first=True)

    tf = tbox(s, 0.55, 4.38, 8.40, 0.62)
    para(tf, "The authors saw these negatives and explained them inside "
             "their own framework:",
         size=10.5, color="primary", first=True, line=1.35)
    para(tf, "“could plausibly have been generated with minimal or negligible "
             "human contribution” Xie et al., §5.5",
         size=10.5, color="primary", line=1.35)
    return s
