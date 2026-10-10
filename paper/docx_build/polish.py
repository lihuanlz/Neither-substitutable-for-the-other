# -*- coding: utf-8 -*-
"""Typographic polish: ASCII maths shorthand -> real glyphs, for the DOCX only.

Word renders Times New Roman Greek and combining marks far better than the
ASCII stand-ins that were convenient while drafting. Combining macron U+0304
(U+0302 for phi-hat) was verified to compose correctly in the rendered PDF.
"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, "content.py")

REPL = [
    # inequalities
    ("<=", "\u2264"),
    (">=", "\u2265"),
    # minus / arrows
    ("TV -> 0", "TV \u2192 0"),
    ("|TP - FP|", "|TP \u2212 FP|"),
    # Greek
    ("lambda*TV", "\u03bb\u00b7TV"),
    ("lambda = 1", "\u03bb = 1"),
    ("lambda >= 0", "\u03bb \u2265 0"),
    ("N* <= N_0", "N* \u2264 N\u2080"),
    # barred symbols
    ("s-bar", "s\u0304"),
    ("tau-bar", "\u03c4\u0304"),
    ("phi-hat", "\u03c6\u0302"),
    # subscripts
    ("N_0", "N\u2080"),
    ("e_0", "e\u2080"),
]

src = open(path, encoding="utf-8").read()
before = src

# Protect the LaTeX source blocks: they must stay ASCII/LaTeX.
marker = "EQS = {"
i = src.index(marker)
j = src.index("FIGS = {")
head, eqs, tail = src[:i], src[i:j], src[j:]

n = 0
for a, b in REPL:
    if a in tail:
        n += tail.count(a)
        tail = tail.replace(a, b)

open(path, "w", encoding="utf-8").write(head + eqs + tail)
print(f"applied {n} replacements in the block/caption section (EQS left untouched)")
print("LaTeX block unchanged:", eqs == src[i:j])
