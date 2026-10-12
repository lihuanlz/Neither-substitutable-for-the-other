# -*- coding: utf-8 -*-
"""Slide 22 - takeaways and closing position."""

from theme import *

TAKEAWAYS = [
    "看不见 ≠ 不存在。AI 把模型输出当成了观测本身。",
    "检测能力有物理天花板，努力压不过去。",
    "验证预算有一个与人的能力无关的硬上界。",
    "影响力测不了价值 —— 价值必须带符号。",
    "符号本身也不可识别：正负由一条分布外拟合的门槛决定。",
    "153 条定理，零 sorry 零公理，全量构建可复跑。",
]


def build(prs):
    s = new_slide(prs)
    header(s, "结语", "我们证明了什么", 22)

    for i, t in enumerate(TAKEAWAYS):
        y = 1.32 + i * 0.52
        dot(s, 0.78, y + 0.16, d=0.11)
        tf = tbox(s, 1.02, y + 0.02, 8.35, 0.32)
        para(tf, t, size=12.5, color="primary", first=True)

    card(s, 0.55, 4.38, 8.90, 0.64, style="teal")
    tf = tbox(s, 0.85, 4.44, 8.30, 0.52)
    para(tf, "我们不打击任何已有度量 —— 它们对各自声明的用途是有效的。",
         size=11, color="bg", first=True, line=1.25)
    para(tf, "我们做的，是把他们散文式的警告，变成机器可以逐条检查的定理。",
         size=11, color="light", line=1.25)
    return s
