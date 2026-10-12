# -*- coding: utf-8 -*-
"""Slide 13 - influence cannot stand in for value."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "SYSTEM LAYER · REBUTTAL", "Influence ≠ Value", 13)

    card(s, 0.55, 1.34, 2.35, 1.05, style="peach")
    tf = tbox(s, 0.55, 1.50, 2.35, 0.72, anchor="middle")
    para(tf, "+M", size=40, color="primary", bold=True, align="center",
         font=FONT_NUM, first=True)

    card(s, 3.05, 1.34, 2.35, 1.05, style="ghost")
    tf = tbox(s, 3.05, 1.50, 2.35, 0.72, anchor="middle")
    para(tf, "−M", size=40, color="primary", bold=True, align="center",
         font=FONT_NUM, first=True)

    tf = tbox(s, 0.55, 2.62, 4.85, 0.34)
    para(tf, "Two outputs, identical |influence|.", size=13, color="primary",
         bold=True, first=True)
    tf = tbox(s, 0.55, 3.00, 4.85, 0.50)
    para(tf, "One is +M, the other −M, and M is arbitrary.",
         size=11.5, color="primary", first=True, line=1.35)

    card(s, 0.55, 3.60, 4.85, 1.05, style="teal")
    tf = tbox(s, 0.85, 3.78, 4.30, 0.70)
    para(tf, "Influence cannot stand in for value.",
         size=12.5, color="bg", bold=True, first=True, line=1.35)
    para(tf, "That is a defect of definition.", size=12.5, color="light",
         line=1.35)

    s.shapes.add_picture(anime("anime_03_direction_matters.jpg"),
                         IN(5.72), IN(1.34), width=IN(3.73))
    tf = tbox(s, 5.72, 3.56, 3.73, 0.80)
    para(tf, "KL and mutual information measure magnitude only.",
         size=11.5, color="primary", first=True, line=1.45)

    card(s, 5.72, 4.45, 3.73, 0.55, style="peach")
    tf = tbox(s, 5.92, 4.55, 3.33, 0.35, anchor="middle")
    para(tf, "Value needs a sign.", size=11.5,
         color="primary", bold=True, first=True)
    return s
