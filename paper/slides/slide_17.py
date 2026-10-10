# -*- coding: utf-8 -*-
"""Slide 17 - the core slide: one output, two calibrations, opposite signs."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "标定层 · 定理", "同一个输出，两次标定，正负相反", 17)

    s.shapes.add_picture(asset("chart_signflip.png"), IN(0.55), IN(1.36), width=IN(4.70))

    tf = tbox(s, 5.50, 1.40, 3.95, 0.34)
    para(tf, "固定一个输出：s̄ = 0.50", size=14, color="primary", bold=True, first=True)

    card(s, 5.50, 1.92, 3.95, 0.78, style="peach")
    tf = tbox(s, 5.72, 2.04, 3.55, 0.56)
    para(tf, "标定 A · Llama-3：τ̄ = 0.5496", size=11, color="primary",
         bold=True, first=True, line=1.3)
    para(tf, "报告 −0.099 → 判为「几乎没人」", size=11.5, color="primary", line=1.3)

    card(s, 5.50, 2.84, 3.95, 0.78, style="ghost")
    tf = tbox(s, 5.72, 2.96, 3.55, 0.56)
    para(tf, "标定 B · Mixtral：τ̄ = 0.4155", size=11, color="primary",
         bold=True, first=True, line=1.3)
    para(tf, "报告 +0.169 → 判为「有人参与」", size=11.5, color="primary", line=1.3)

    tf = tbox(s, 5.50, 3.78, 3.95, 0.50)
    para(tf, "同一段文字、同一份数据，结论完全相反。",
         size=12.5, color="primary", bold=True, first=True, line=1.35)

    card(s, 0.55, 4.42, 8.90, 0.58, style="peach")
    tf = tbox(s, 0.85, 4.52, 8.30, 0.38, anchor="middle")
    para(tf, "差别只在于：你把那条「合理线」画在了哪里 —— 而这条线是在 2500 条与本任务无关的公开对话上拟合出来的。",
         size=11.5, color="primary", bold=True, first=True)

    source(s, "τ̄ 取自 Xie et al. (ACL 2026) 附录 A.5", y=5.06)
    return s
