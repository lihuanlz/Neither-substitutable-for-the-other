# -*- coding: utf-8 -*-
"""Slide 20 - the eleven formalisation modules."""

from theme import *

MODULES = [
    ("全变差", "Basic"),
    ("污染", "Contamination"),
    ("覆盖", "Coverage"),
    ("假设检验", "HypothesisTest"),
    ("分层与观测等价", "Refinement"),
    ("影响力与价值", "Value"),
    ("验证预算", "VerifyBudget"),
    ("不可通约", "Incommensurable"),
    ("标定不可识别", "Calibration"),
    ("碎片化", "Fragmentation"),
    ("语料即筛选", "Corpus"),
]


def build(prs):
    s = new_slide(prs)
    header(s, "形式化", "153 条定理，分布在 11 个模块里", 20)

    # Eleven modules in three columns need four rows, so the pitch is tighter
    # than the nine-module layout this slide used to carry.
    for i, (zh, mod) in enumerate(MODULES):
        x = 0.55 + (i % 3) * 3.17
        y = 1.30 + (i // 3) * 0.74
        is_new = mod in ("Calibration", "Fragmentation", "Corpus")
        card(s, x, y, 2.95, 0.62, style="peach" if is_new else "ghost")
        tf = tbox(s, x + 0.24, y + 0.09, 2.50, 0.28)
        para(tf, zh, size=12.5, color="primary", bold=True, first=True)
        tf = tbox(s, x + 0.24, y + 0.37, 2.50, 0.22)
        para(tf, mod, size=9.5, color="primary", first=True)

    card(s, 0.55, 4.34, 8.90, 0.62, style="peach")
    tf = tbox(s, 0.85, 4.48, 8.30, 0.34, anchor="middle")
    para(tf, "Lean 4 v4.15.0 + Mathlib · 153 条定理 + 20 个精确算例 · "
             "零 sorry · 零公理 · 全量构建通过",
         size=12, color="primary", bold=True, first=True)
    return s
