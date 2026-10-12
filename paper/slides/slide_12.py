# -*- coding: utf-8 -*-
"""Slide 12 - splitting contribution into two accounts."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "SYSTEM LAYER · RESULT 3", "Two Accounts of Credit", 12)

    card(s, 0.55, 1.34, 4.45, 1.92, style="peach")
    tf = tbox(s, 0.85, 1.54, 3.90, 0.34)
    para(tf, "Human credit: change the layer", size=15, color="primary", bold=True, first=True)
    for i, t in enumerate(["Ask a better question",
                           "Formally: change Φ(α) itself",
                           "Gain has no ceiling"]):
        y = 2.00 + i * 0.40
        dot(s, 0.95, y + 0.13, d=0.09)
        tf = tbox(s, 1.15, y, 3.60, 0.28)
        para(tf, t, size=12, color="primary", first=True)

    card(s, 0.55, 3.40, 4.45, 1.32, style="ghost")
    tf = tbox(s, 0.85, 3.58, 3.90, 0.34)
    para(tf, "AI credit: compress within the layer", size=15, color="primary", bold=True, first=True)
    for i, t in enumerate(["Push error toward Φ(α)",
                           "Marginal gain shrinks, hard cap"]):
        y = 4.04 + i * 0.34
        dot(s, 0.95, y + 0.12, d=0.09, color="primary")
        tf = tbox(s, 1.15, y, 3.60, 0.26)
        para(tf, t, size=12, color="primary", first=True)

    s.shapes.add_picture(anime("anime_04_two_currencies.jpg"),
                         IN(5.55), IN(1.34), width=IN(3.90))
    tf = tbox(s, 5.55, 3.62, 3.90, 0.66)
    para(tf, "AI hits a wall inside the layer; a human changes layer.",
         size=11, color="primary", first=True, line=1.45)

    card(s, 5.55, 4.36, 3.90, 0.62, style="peach")
    tf = tbox(s, 5.78, 4.42, 3.45, 0.52, anchor="middle")
    para(tf, "“AI helps” holds only when the layer is fixed, "
             "the state with no human credit.",
         size=10.5, color="primary", bold=True, first=True, line=1.3)
    return s
