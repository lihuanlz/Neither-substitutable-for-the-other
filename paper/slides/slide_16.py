# -*- coding: utf-8 -*-
"""Slide 16 - the estimator's formula contains no human."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "标定层 · 问题", "最通行的那个估计量，公式里没有人类", 16)

    card(s, 0.55, 1.34, 8.90, 1.35, style="peach")
    tf = tbox(s, 0.55, 1.62, 8.90, 0.80, anchor="middle")
    para(tf, "φ̂  =  1  −  τ̄ / s̄", size=40, color="primary", bold=True,
         align="center", font=FONT_NUM, first=True)

    card(s, 0.55, 2.86, 4.35, 0.66, style="ghost")
    tf = tbox(s, 0.80, 2.98, 3.90, 0.42, anchor="middle")
    para(tf, "τ̄ = 拟合出来的那条「合理线」", size=12, color="primary", first=True)

    card(s, 5.10, 2.86, 4.35, 0.66, style="ghost")
    tf = tbox(s, 5.35, 2.98, 3.90, 0.42, anchor="middle")
    para(tf, "s̄ = 这段输出的平均意外程度", size=12, color="primary", first=True)

    card(s, 0.55, 3.68, 8.90, 1.12, style="teal")
    tf = tbox(s, 0.85, 3.88, 8.30, 0.76)
    para(tf, "人类的输入 x 根本不在这个式子里。",
         size=17, color="bg", bold=True, first=True, line=1.3)
    para(tf, "所以它算出来的是「这段输出有多出人意料」，而不是「这里面有多少是人做的」。",
         size=12.5, color="light", line=1.3)
    return s
