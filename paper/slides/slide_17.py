# -*- coding: utf-8 -*-
"""Slide 17 - the core slide: one output, two calibrations, opposite signs."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "CALIBRATION LAYER · THEOREM", "One Output, Two Signs", 17)

    s.shapes.add_picture(asset("chart_signflip.png"), IN(0.55), IN(1.36), width=IN(4.70))

    tf = tbox(s, 5.50, 1.40, 3.95, 0.34)
    para(tf, "Fix the output: s̄ = 0.50", size=14, color="primary", bold=True, first=True)

    card(s, 5.50, 1.92, 3.95, 0.78, style="peach")
    tf = tbox(s, 5.72, 2.04, 3.55, 0.56)
    para(tf, "Calibration A · Llama-3: τ̄ = 0.5496", size=11, color="primary",
         bold=True, first=True, line=1.3)
    para(tf, "Reports −0.099: almost no human", size=11.5, color="primary", line=1.3)

    card(s, 5.50, 2.84, 3.95, 0.78, style="ghost")
    tf = tbox(s, 5.72, 2.96, 3.55, 0.56)
    para(tf, "Calibration B · Mixtral: τ̄ = 0.4155", size=11, color="primary",
         bold=True, first=True, line=1.3)
    para(tf, "Reports +0.169: human present", size=11.5, color="primary", line=1.3)

    tf = tbox(s, 5.50, 3.78, 3.95, 0.50)
    para(tf, "Same text, same data, opposite verdicts.",
         size=12.5, color="primary", bold=True, first=True, line=1.35)

    card(s, 0.55, 4.42, 8.90, 0.58, style="peach")
    tf = tbox(s, 0.85, 4.52, 8.30, 0.38, anchor="middle")
    para(tf, "Only the bar moved, and it was fitted on 2500 unrelated "
             "chat prompts.",
         size=11.5, color="primary", bold=True, first=True)

    source(s, "τ̄ from Xie et al. (ACL 2026), Appendix A.5", y=5.06)
    return s
