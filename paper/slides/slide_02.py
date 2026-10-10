# -*- coding: utf-8 -*-
"""Slide 02 - table of contents."""

from theme import *

ITEMS = [
    ("01", "看不见的鸟", "「观测不到」从来不等于「不存在」"),
    ("02", "检测能力的上限", "再怎么努力，也压不过那道物理天花板"),
    ("03", "真相不是一个点", "观测协议决定了你能看见什么"),
    ("04", "符号不由数据决定", "一个估计量连自己的正负都做不了主"),
    ("05", "把争议变成定理", "117 条 Lean 4 证明，零 sorry 零公理"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "CONTENTS", "这份报告讲什么", 2)

    for i, (num, title, desc) in enumerate(ITEMS):
        y = 1.32 + i * 0.73
        shape(s, 0.78, y + 0.05, 0.40, 0.40, fill="primary", kind="oval")
        tf = tbox(s, 0.78, y + 0.07, 0.40, 0.36, anchor="middle")
        para(tf, num, size=10.5, color="bg", bold=True, align="center",
             font=FONT_NUM, first=True)
        tf = tbox(s, 1.42, y + 0.03, 2.9, 0.34)
        para(tf, title, size=16, color="primary", bold=True, first=True)
        tf = tbox(s, 4.48, y + 0.08, 4.6, 0.32)
        para(tf, desc, size=12, color="primary", first=True)

    return s
