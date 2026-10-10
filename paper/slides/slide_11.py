# -*- coding: utf-8 -*-
"""Slide 11 - observation equivalence classes, with a small diagram."""

from theme import *

ROWS = [
    ("协议严格", 3),
    ("协议中等", 2),
    ("协议宽松", 6),
]


def build(prs):
    s = new_slide(prs)
    header(s, "系统层 · 概念", "「真相」不是一个点，是一个等价类", 11)

    tf = tbox(s, 0.55, 1.40, 4.35, 0.85)
    para(tf, "老做法：把真实答案当成一个确定的点，然后去估计它离这个点有多远。",
         size=12.5, color="primary", first=True, line=1.45)

    tf = tbox(s, 0.55, 2.34, 4.35, 0.85)
    para(tf, "我们的做法：先问一句 —— 在这个观测协议下，哪些状态看起来完全一样？",
         size=12.5, color="primary", first=True, line=1.45)

    card(s, 0.55, 3.34, 4.35, 1.06, style="peach")
    tf = tbox(s, 0.80, 3.54, 3.90, 0.70)
    para(tf, "它们组成一个等价类 [s*]。于是误差从一个数字，"
             "变成一个随协议变化的层级函数。",
         size=12, color="primary", first=True, line=1.4)

    for i, (lab, k) in enumerate(ROWS):
        y = 1.50 + i * 1.00
        box_w = 0.42 + 0.40 * k
        shape(s, 6.36, y - 0.06, box_w, 0.40, fill=None, line="secondary",
              lw=1.25, kind="round", radius=0.18)
        for j in range(6):
            cx = 6.56 + j * 0.40
            filled = j < k
            shape(s, cx, y + 0.02, 0.20, 0.20,
                  fill=("accent" if filled else "bg"),
                  line=(None if filled else "secondary"), lw=1.0, kind="oval")
        tf = tbox(s, 5.28, y + 0.04, 0.95, 0.28)
        para(tf, lab, size=11, color="primary", first=True)
    tf = tbox(s, 5.28, 4.24, 4.17, 0.70)
    para(tf, "同一个「真相」，在不同协议下被混在一起的状态并不相同。",
         size=11, color="primary", first=True, line=1.45)
    return s
