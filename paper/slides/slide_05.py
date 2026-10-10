# -*- coding: utf-8 -*-
"""Slide 05 - the same mistake, side by side."""

from theme import *

ROWS = [
    ("看不见 → 记为「未检出」", "检测不到 → 当成「不存在」"),
    ("参考分布：真实的物种分布", "参考分布：文献里的既有结论"),
    ("换一个观测协议 → 结论改变", "换一个模型或检测器 → 结论翻转"),
    ("重复调查 → 检出率上升", "多跑几轮验证 → 真的会更准吗"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "问题 · 同一个错误", "AI 正在重复这个错误", 5)

    card(s, 0.55, 1.28, 4.30, 0.50, style="peach")
    tf = tbox(s, 0.55, 1.38, 4.30, 0.30, anchor="middle")
    para(tf, "生态学家", size=14, color="primary", bold=True, align="center",
         first=True)

    card(s, 5.15, 1.28, 4.30, 0.50, style="teal")
    tf = tbox(s, 5.15, 1.38, 4.30, 0.30, anchor="middle")
    para(tf, "今天的 AI 辅助研究", size=14, color="bg", bold=True,
         align="center", first=True)

    shape(s, 5.00, 1.95, 0.012, 2.40, fill="secondary")

    for i, (left, right) in enumerate(ROWS):
        y = 1.98 + i * 0.62
        dot(s, 0.72, y + 0.16, d=0.09, color="accent")
        tf = tbox(s, 0.92, y + 0.03, 3.95, 0.30)
        para(tf, left, size=12.5, color="primary", first=True)
        dot(s, 5.32, y + 0.16, d=0.09, color="primary")
        tf = tbox(s, 5.52, y + 0.03, 3.90, 0.30)
        para(tf, right, size=12.5, color="primary", first=True)

    card(s, 0.55, 4.42, 8.90, 0.62, style="peach")
    tf = tbox(s, 0.85, 4.55, 8.30, 0.36, anchor="middle")
    para(tf, "今天的 AI 辅助科研，把「模型输出」当成了「观测本身」。"
             "但模型输出是一条有分辨率的通道。",
         size=13, color="primary", bold=True, first=True)
    return s
