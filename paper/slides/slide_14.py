# -*- coding: utf-8 -*-
"""Slide 14 - incommensurability splits into two regimes."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "系统层 · 判决", "「不可通约」这句话，其实要分两半说", 14)

    card(s, 0.55, 1.34, 4.35, 2.55, style="peach")
    tf = tbox(s, 0.85, 1.56, 3.80, 0.32)
    para(tf, "当检测地板卡住了", size=14, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 1.98, 3.80, 0.52)
    para(tf, "完全不可通约", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 0.85, 2.68, 3.80, 1.00)
    para(tf, "两个可靠度完全不同的人，给出完全相同的预算。",
         size=12, color="primary", first=True, line=1.4)
    para(tf, "连高低都分不出来。", size=12, color="primary", line=1.4)

    card(s, 5.10, 1.34, 4.35, 2.55, style="ghost")
    tf = tbox(s, 5.40, 1.56, 3.80, 0.32)
    para(tf, "当地板没卡住", size=14, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 1.98, 3.80, 0.52)
    para(tf, "可通约，但非线性", size=22, color="primary", bold=True, first=True)
    tf = tbox(s, 5.40, 2.68, 3.80, 1.00)
    para(tf, "谁强谁弱看得出来（保序）。",
         size=12, color="primary", first=True, line=1.4)
    para(tf, "但不是成比例换算，做不成价格表。",
         size=12, color="primary", line=1.4)

    card(s, 0.55, 4.10, 8.90, 0.85, style="peach")
    tf = tbox(s, 0.85, 4.24, 8.30, 0.60)
    para(tf, "准确的说法是「不可线性换算」，不是「完全不可通约」。",
         size=13, color="primary", bold=True, first=True, line=1.35)
    para(tf, "后者太强，会被定理直接判死 —— 这是形式化帮我们改掉的原话。",
         size=12.5, color="primary", line=1.35)
    return s
