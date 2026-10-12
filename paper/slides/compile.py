# -*- coding: utf-8 -*-
"""Compile all slide modules into one PPTX."""

import importlib
import os
import sys

from pptx import Presentation
from pptx.util import Inches

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import theme  # noqa: E402

N_SLIDES = 22
OUTDIR = os.path.join(HERE, "output")
OUTFILE = os.path.join(OUTDIR, "人机贡献的能识别边界-科普版.pptx")


def main():
    prs = Presentation()
    prs.slide_width = Inches(theme.W)
    prs.slide_height = Inches(theme.H)

    prs.core_properties.title = "人机贡献的能识别边界"
    prs.core_properties.subject = "形式化研究：人机贡献度量的可识别性边界"
    prs.core_properties.comments = "153 条 Lean 4 定理，零 sorry 零公理"

    for i in range(1, N_SLIDES + 1):
        name = "slide_%02d" % i
        mod = importlib.import_module(name)
        mod.build(prs)

    os.makedirs(OUTDIR, exist_ok=True)
    prs.save(OUTFILE)
    print("saved:", OUTFILE)
    print("slides:", len(prs.slides._sldIdLst))


if __name__ == "__main__":
    main()
