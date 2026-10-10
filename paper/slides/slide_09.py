# -*- coding: utf-8 -*-
"""Slide 09 - the three budget numbers."""

from theme import *

CARDS = [
    ("N_c", "3.793", "由验证者的可靠度决定", "peach", "primary"),
    ("N_0", "3.474", "与人的能力无关的硬上界", "ghost", "primary"),
    ("N*", "3.474", "取较小者 —— 这里卡在 N_0", "teal", "bg"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "内容层 · 结果二（续）", "预算卡在哪里：三个数", 9)

    for i, (name, val, desc, style, txt) in enumerate(CARDS):
        x = 0.55 + i * 3.17
        card(s, x, 1.34, 2.95, 1.85, style=style)
        tf = tbox(s, x + 0.28, 1.56, 2.40, 0.32)
        para(tf, name, size=14, color=txt, bold=True, font=FONT, first=True)
        tf = tbox(s, x + 0.28, 1.92, 2.45, 0.62)
        para(tf, val, size=34, color=txt,
             bold=True, font=FONT_NUM, first=True)
        tf = tbox(s, x + 0.28, 2.62, 2.45, 0.46)
        para(tf, desc, size=11, color=txt, first=True, line=1.35)

    card(s, 0.55, 3.42, 8.90, 0.98, style="peach")
    tf = tbox(s, 0.85, 3.60, 8.30, 0.64)
    para(tf, "就算你的验证者再靠谱，预算也卡在 3.474。",
         size=14, color="primary", bold=True, first=True, line=1.35)
    para(tf, "剩下那部分漏检，你加多少人都补不回来。",
         size=13, color="primary", line=1.35)

    dot(s, 0.72, 4.72)
    tf = tbox(s, 0.92, 4.58, 8.5, 0.32)
    para(tf, "在 83.97% 的参数组合里，真正卡住我们的是检测器本身，而不是人。",
         size=12.5, color="primary", bold=True, first=True)
    source(s, "参数组：TV = 0.09、q = 0.5、λ = 1，与论文图 2 同源（N_c 另取一组验证者可靠度）",
           y=5.06, x=0.55, w=6.6)
    return s
