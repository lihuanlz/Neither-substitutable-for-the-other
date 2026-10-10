# -*- coding: utf-8 -*-
"""Slide 21 - the prover caught our own mistakes first."""

from theme import *

ITEMS = [
    ("一个不等式写反了", "定理直接证不出来。Lean 把我们自己的建模错误判了死刑。"),
    ("残余项漏了一个地板", "「验证越多越好」被推翻 —— 漏检率有一个降不下去的下限。"),
    ("两条单调性方向写反", "我们以为预算随检测能力单调递减，结论其实要更精细。"),
    ("「完全不可通约」太满", "被逼着改成准确说法：「不可线性换算」。"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "形式化的价值", "第一个被它抓出来的，是我们自己", 21)

    for i, (title, body) in enumerate(ITEMS):
        x = 0.55 + (i % 2) * 4.55
        y = 1.34 + (i // 2) * 1.56
        card(s, x, y, 4.35, 1.42, style="peach" if i % 2 == 0 else "ghost")
        tf = tbox(s, x + 0.30, y + 0.20, 3.75, 0.34)
        para(tf, title, size=14, color="primary", bold=True, first=True)
        tf = tbox(s, x + 0.30, y + 0.62, 3.75, 0.66)
        para(tf, body, size=12, color="primary", first=True, line=1.4)

    card(s, 0.55, 4.48, 8.90, 0.52, style="teal")
    tf = tbox(s, 0.85, 4.58, 8.30, 0.32, anchor="middle")
    para(tf, "一个能扛过定理证明器的建模错误，大概也扛不过一个合作者。",
         size=13, color="bg", bold=True, align="center", first=True)
    return s
