# -*- coding: utf-8 -*-
"""Slide 07 - the detector ceiling, stated as two formulas."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "内容层 · 结果一", "最强检测器能做到什么，已经被算死了", 7)

    card(s, 0.55, 1.32, 4.35, 1.80, style="peach")
    tf = tbox(s, 0.85, 1.56, 3.85, 0.74)
    para(tf, "TV / 2", size=38, color="primary", bold=True, font=FONT_NUM, first=True)
    tf = tbox(s, 0.85, 2.44, 3.85, 0.46)
    para(tf, "任何检测器相对「瞎猜」能达到的最大优势",
         size=12, color="primary", first=True, line=1.35)

    card(s, 5.10, 1.32, 4.35, 1.80, style="ghost")
    tf = tbox(s, 5.40, 1.62, 3.85, 0.66)
    para(tf, "(1 − TV) / 2", size=30, color="primary", bold=True,
         font=FONT_NUM, first=True)
    tf = tbox(s, 5.40, 2.44, 3.85, 0.46)
    para(tf, "最优检测器的最小错误率",
         size=12, color="primary", first=True, line=1.35)

    card(s, 0.55, 3.26, 8.90, 0.54, style="ghost")
    tf = tbox(s, 0.85, 3.40, 8.30, 0.30, anchor="middle")
    para(tf, "TV = 两个分布有多不一样，取值 0 到 1。TV = 0，意味着你完全分不出两者的区别。",
         size=12.5, color="primary", first=True)

    card(s, 0.55, 3.94, 8.90, 0.94, style="peach")
    tf = tbox(s, 0.85, 4.08, 8.30, 0.70)
    para(tf, "举个例子：参考分布 p=(0.42, 0.28, 0.18, 0.12)，模型输出 q=(0.10, 0.20, 0.40, 0.30)",
         size=12, color="primary", first=True, line=1.35)
    para(tf, "两者的 TV = 0.40 → 最好也只能比瞎猜强 0.20，错误率 0.30。",
         size=12, color="primary", bold=True, line=1.35)

    source(s, "来源：论文图 1 · 这是 Neyman–Pearson / Le Cam 两点引理，不是我们的新发现", y=4.98)
    return s
