# -*- coding: utf-8 -*-
"""Slide 04 - the cryptic species lesson, mixed media."""

from theme import *


def build(prs):
    s = new_slide(prs)
    header(s, "生态学 · 一个老故事", "看不见的那只鸟", 4)

    card(s, 0.55, 1.28, 4.45, 0.92, style="peach")
    tf = tbox(s, 0.80, 1.50, 4.0, 0.50, anchor="middle")
    para(tf, "看不见 ≠ 不存在", size=20, color="primary", bold=True, first=True)

    reasons = [
        "鸟根本不在这一片林子里",
        "鸟在，但天太黑、灌木太密",
        "鸟在，但风太大、距离太远",
    ]
    for i, r in enumerate(reasons):
        y = 2.38 + i * 0.48
        dot(s, 0.80, y + 0.15)
        tf = tbox(s, 1.02, y + 0.02, 4.0, 0.30)
        para(tf, r, size=12.5, color="primary", first=True)

    card(s, 0.55, 3.86, 4.45, 1.14, style="ghost")
    tf = tbox(s, 0.78, 4.02, 4.14, 0.82)
    para(tf, "重复调查能把看见的概率越推越高，但永远到不了 1。",
         size=11.5, color="primary", first=True, line=1.35)
    para(tf, "那道天花板由观测协议决定，不由你有多认真决定。",
         size=11.5, color="primary", line=1.35)

    s.shapes.add_picture(anime("anime_01_cryptic_species.jpg"),
                         IN(5.32), IN(1.28), width=IN(4.10))
    tf = tbox(s, 5.32, 3.70, 4.10, 0.90)
    para(tf, "在同一个观测协议下，所有「看起来一模一样」的状态被混在了一起。"
             "重复观测能提高检出率，但协议本身分辨不了的东西，永远检不出来。",
         size=11, color="primary", first=True, line=1.45)
    return s
