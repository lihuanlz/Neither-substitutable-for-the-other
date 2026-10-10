# -*- coding: utf-8 -*-
"""
Render every display equation in content.EQS through real LaTeX (MiKTeX pdflatex)
to a tightly-cropped high-DPI PNG for embedding in the DOCX.

The `standalone` class is broken in this MiKTeX install, so we compile with
`article` + amsmath and crop the tight bounding box afterwards with PyMuPDF.
"""
import io
import os
import subprocess
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import fitz  # PyMuPDF

import content as C

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "eq")
OUT = os.path.join(HERE, "assets_eq")
DPI = 600  # print quality; equations are small so this keeps them crisp in Word

TEX = r"""\documentclass[12pt]{article}
\usepackage{amsmath,amssymb}
\usepackage[margin=0pt]{geometry}
\pagestyle{empty}
\setlength{\parindent}{0pt}
\begin{document}
{\fontsize{12}{14}\selectfont
\[
%s
\]
}
\end{document}
"""


def render(key, latex, num):
    stem = f"eq{num:02d}_{key}"
    tex_path = os.path.join(BUILD, stem + ".tex")
    with open(tex_path, "w", encoding="utf-8") as fh:
        fh.write(TEX % latex)

    for attempt in range(2):  # MiKTeX may need a second pass to settle
        r = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", stem + ".tex"],
            cwd=BUILD, capture_output=True, text=True, timeout=300,
        )
        pdf = os.path.join(BUILD, stem + ".pdf")
        if os.path.isfile(pdf):
            break
    else:
        print(f"FAIL {key}: pdflatex produced no PDF")
        print(r.stdout[-1500:])
        return None

    doc = fitz.open(pdf)
    page = doc[0]

    # Tight bbox from the vector content, then pad a little.
    blocks = page.get_text("blocks")
    if not blocks:
        print(f"FAIL {key}: empty page")
        return None
    x0 = min(b[0] for b in blocks)
    y0 = min(b[1] for b in blocks)
    x1 = max(b[2] for b in blocks)
    y1 = max(b[3] for b in blocks)
    pad = 2.0
    rect = fitz.Rect(max(0, x0 - pad), max(0, y0 - pad),
                     min(page.rect.width, x1 + pad),
                     min(page.rect.height, y1 + pad))

    pix = page.get_pixmap(clip=rect, dpi=DPI, alpha=False)
    out = os.path.join(OUT, f"eq{num:02d}.png")
    pix.save(out)
    doc.close()
    print(f"OK   {key:9s} num={num:<3} {pix.width}x{pix.height}px -> {os.path.basename(out)}")
    return out


def main():
    os.makedirs(BUILD, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)

    # Equation numbers come from the document plan, so numbering stays in sync.
    plan = [(b["key"], b["num"]) for b in C.BLOCKS if b["t"] == "eq"]

    ok = 0
    for key, num in plan:
        if key not in C.EQS:
            print(f"FAIL {key}: not defined in content.EQS")
            continue
        if render(key, C.EQS[key], num):
            ok += 1

    print(f"\nrendered {ok}/{len(plan)} equations at {DPI} dpi")
    return 0 if ok == len(plan) else 1


if __name__ == "__main__":
    sys.exit(main())
