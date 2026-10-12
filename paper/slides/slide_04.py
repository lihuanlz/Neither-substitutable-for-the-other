# -*- coding: utf-8 -*-
"""Slide 04 - the cryptic species lesson, mixed media."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "ECOLOGY · AN OLD STORY", "The Bird You Never See", 4)

    card(s, 0.55, 1.28, 4.45, 0.92, style="peach")
    tf = tbox(s, 0.80, 1.50, 4.0, 0.50, anchor="middle")
    para(tf, "Unseen ≠ Absent", size=20, color="primary", bold=True, first=True)

    reasons = [
        "The bird is not in this stand",
        "It is there, but too dark, too dense",
        "It is there, but wind and distance",
    ]
    for i, r in enumerate(reasons):
        y = 2.38 + i * 0.48
        dot(s, 0.80, y + 0.15)
        tf = tbox(s, 1.02, y + 0.02, 4.0, 0.30)
        para(tf, r, size=12.5, color="primary", first=True)

    card(s, 0.55, 3.86, 4.45, 1.14, style="ghost")
    tf = tbox(s, 0.78, 4.02, 4.14, 0.82)
    para(tf, "Repeated surveys raise detection, never to 1.",
         size=11.5, color="primary", first=True, line=1.35)
    para(tf, "The ceiling is set by the protocol.",
         size=11.5, color="primary", line=1.35)

    s.shapes.add_picture(anime("anime_01_cryptic_species.jpg"),
                         IN(5.32), IN(1.28), width=IN(4.10))
    tf = tbox(s, 5.32, 3.70, 4.10, 0.90)
    para(tf, "Under one protocol, look-alike states are lumped together. "
             "More sampling raises detection; what the protocol cannot "
             "separate, it never will.",
         size=11, color="primary", first=True, line=1.45)
    return s
