# -*- coding: utf-8 -*-
"""Render the compiled deck to per-slide PNGs for visual QA."""

import glob
import os
import sys

import fitz

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.join(HERE, "output")
PREVIEW = os.path.join(OUTDIR, "preview")

os.makedirs(PREVIEW, exist_ok=True)

pdfs = glob.glob(os.path.join(OUTDIR, "*.pdf"))
if not pdfs:
    print("no pdf found")
    sys.exit(2)

doc = fitz.open(pdfs[0])
zoom = 150 / 72.0
mat = fitz.Matrix(zoom, zoom)
for i, page in enumerate(doc, start=1):
    pix = page.get_pixmap(matrix=mat)
    p = os.path.join(PREVIEW, "slide-%02d.png" % i)
    pix.save(p)
print("rendered", len(doc), "pages ->", PREVIEW)
