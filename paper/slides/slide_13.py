# -*- coding: utf-8 -*-
"""Slide 13 - influence cannot stand in for value."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "系统层 · 反驳", "影响力 ≠ 价值", 13)

    card(s, 0.55, 1.34, 2.35, 1.05, style="peach")
    tf = tbox(s, 0.55, 1.50, 2.35, 0.72, anchor="middle")
    para(tf, "+M", size=40, color="primary", bold=True, align="center",
         font=FONT_NUM, first=True)

    card(s, 3.05, 1.34, 2.35, 1.05, style="ghost")
    tf = tbox(s, 3.05, 1.50, 2.35, 0.72, anchor="middle")
    para(tf, "−M", size=40, color="primary", bold=True, align="center",
         font=FONT_NUM, first=True)

    tf = tbox(s, 0.55, 2.62, 4.85, 0.34)
    para(tf, "两条输出，影响力的绝对值完全一样。", size=13, color="primary",
         bold=True, first=True)
    tf = tbox(s, 0.55, 3.00, 4.85, 0.50)
    para(tf, "但一条的价值可以是 +M，另一条是 −M，M 还可以任意大。",
         size=11.5, color="primary", first=True, line=1.35)

    card(s, 0.55, 3.60, 4.85, 1.05, style="teal")
    tf = tbox(s, 0.85, 3.78, 4.30, 0.70)
    para(tf, "结论：用「影响力」代理「价值」在数学上失效。",
         size=12.5, color="bg", bold=True, first=True, line=1.35)
    para(tf, "这不是工程问题，是定义问题。", size=12.5, color="light",
         line=1.35)

    s.shapes.add_picture(anime("anime_03_direction_matters.jpg"),
                         IN(5.72), IN(1.34), width=IN(3.73))
    tf = tbox(s, 5.72, 3.56, 3.73, 0.80)
    para(tf, "KL 散度、互信息都只能测幅度：它们分不清「帮上忙」和「帮倒忙」。",
         size=11.5, color="primary", first=True, line=1.45)

    card(s, 5.72, 4.45, 3.73, 0.55, style="peach")
    tf = tbox(s, 5.92, 4.55, 3.33, 0.35, anchor="middle")
    para(tf, "价值必须带符号，幅度代替不了方向。", size=11.5,
         color="primary", bold=True, first=True)
    return s
