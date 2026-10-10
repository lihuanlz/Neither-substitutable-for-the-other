# -*- coding: utf-8 -*-
"""Slide 18 - it is not even a proportion."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "标定层 · 后果", "它甚至不是一个比例", 18)

    card(s, 0.55, 1.34, 4.35, 1.85, style="peach")
    tf = tbox(s, 0.85, 1.58, 3.80, 0.46)
    para(tf, "有上界", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 2.14, 3.80, 0.85)
    para(tf, "φ̂ 永远小于 1。", size=12.5, color="primary", bold=True,
         first=True, line=1.4)
    para(tf, "输出越出人意料，它越接近 1。", size=12.5, color="primary", line=1.4)

    card(s, 5.10, 1.34, 4.35, 1.85, style="ghost")
    tf = tbox(s, 5.40, 1.58, 3.80, 0.46)
    para(tf, "没有下界", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 2.14, 3.80, 0.85)
    para(tf, "输出越「意料之中」，它越小。", size=12.5, color="primary",
         bold=True, first=True, line=1.4)
    para(tf, "可以是任意负数，没有底线。", size=12.5, color="primary", line=1.4)

    card(s, 0.55, 3.38, 8.90, 0.92, style="teal")
    tf = tbox(s, 0.85, 3.56, 8.30, 0.58, anchor="middle")
    para(tf, "所以把它读成「0 到 1 之间的一个比例」，在估计版本里并不成立。",
         size=14, color="bg", bold=True, first=True)

    tf = tbox(s, 0.55, 4.38, 8.40, 0.62)
    para(tf, "作者自己观察到这些负值，并在他们的框架内部给出了正确解释：",
         size=10.5, color="primary", first=True, line=1.35)
    para(tf, "“could plausibly have been generated with minimal or negligible "
             "human contribution” — Xie et al., §5.5",
         size=10.5, color="primary", line=1.35)
    return s
