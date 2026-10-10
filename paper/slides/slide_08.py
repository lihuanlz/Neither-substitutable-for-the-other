# -*- coding: utf-8 -*-
"""Slide 08 - the verification floor, data visualisation."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "内容层 · 结果二", "验证不是越多越好", 8)

    s.shapes.add_picture(asset("chart_floor.png"), IN(0.55), IN(1.34), width=IN(4.85))

    tf = tbox(s, 5.62, 1.40, 3.83, 0.42)
    para(tf, "漏检率会往下掉，但掉到某个数就停住了",
         size=15, color="primary", bold=True, first=True)

    points = [
        "每多验证一轮，漏掉的概率就乘一次 —— 这是指数下降",
        "但它有一个地板，无论验证多久都降不下去",
        "地板高度 = λ × TV：检测器越弱，天花板越高",
    ]
    for i, p in enumerate(points):
        y = 2.02 + i * 0.62
        dot(s, 5.75, y + 0.15)
        tf = tbox(s, 5.95, y + 0.01, 3.50, 0.60)
        para(tf, p, size=12, color="primary", first=True, line=1.35)

    card(s, 5.62, 3.98, 3.83, 0.62, style="peach")
    tf = tbox(s, 5.78, 4.08, 3.52, 0.42, anchor="middle")
    para(tf, "地板 T = 0.09：再加多少验证者，也只能到这。",
         size=11.5, color="primary", bold=True, first=True)

    source(s, "参数：TV = 0.09、q = 0.5、λ = 1（与论文图 2 同源）",
           y=4.52, x=0.55, w=4.75)
    return s
