# -*- coding: utf-8 -*-
"""Slide 03 - section divider 01."""

from theme import *


def build(prs):
    s = new_slide(prs)
    set_bg(s, "primary")

    tf = tbox(s, 0.85, 0.98, 3.0, 1.85)
    para(tf, "01", size=104, color="light", bold=True, font=FONT_NUM, first=True)

    tf = tbox(s, 0.90, 2.78, 5.7, 0.72)
    para(tf, "看不见的鸟", size=34, color="bg", bold=True, first=True)

    tf = tbox(s, 0.90, 3.60, 5.6, 0.80)
    para(tf, "在谈 AI 之前，生态学家已经把这件事说过一遍了。",
         size=13, color="light", first=True, line=1.4)

    shape(s, 8.80, 0.20, 0.92, 0.92, line="secondary", lw=1.25, kind="oval")
    shape(s, 9.13, 0.53, 0.24, 0.24, fill="accent", kind="oval")
    badge(s, 3, dark=True)
    return s
