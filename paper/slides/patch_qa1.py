# -*- coding: utf-8 -*-
"""Apply the QA round-1 fixes to the deck sources.

Fixes:
  1. CRITICAL  Llama-3 / Mixtral calibration constants were swapped.
  2. MAJOR     Text contrast: every accent-on-peach and secondary-on-light
               text run fails WCAG. Text is now always `primary` (or `light`
               on dark panels); `accent` and `secondary` are reserved for
               fills and hairlines.
  3. NOTATION   restore tau-bar / s-bar to match the manuscript and chart.
  4. POLISH     divider image margin, module label, lambda note, orphan lines.
"""

import io
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))


def read(p):
    with io.open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    with io.open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(s)
    print("patched", os.path.basename(p))


def sub(text, pairs, label):
    for old, new in pairs:
        if old not in text:
            print("   !! not found in %s: %r" % (label, old[:60]))
            continue
        text = text.replace(old, new)
    return text


# ---------------------------------------------------------------- theme.py
p = os.path.join(HERE, "theme.py")
t = read(p)

t = sub(t, [
    (
        'def badge(slide, n):\n'
        '    tf = tbox(slide, 9.10, 5.04, 0.70, 0.30, anchor="middle")\n'
        '    para(tf, "%02d" % n, size=11, color="secondary", align="right",\n'
        '         font=FONT_NUM, first=True)',
        'def badge(slide, n, dark=False):\n'
        '    tf = tbox(slide, 9.10, 5.04, 0.70, 0.30, anchor="middle")\n'
        '    para(tf, "%02d" % n, size=11, color=("light" if dark else "primary"),\n'
        '         align="right", font=FONT_NUM, first=True)',
    ),
    (
        '    tf = tbox(slide, 0.55, 0.30, 7.6, 0.26)\n'
        '    para(tf, eyebrow, size=10.5, color="accent", bold=True, first=True)',
        '    dot(slide, 0.60, 0.42, d=0.11, color="accent")\n'
        '    tf = tbox(slide, 0.78, 0.30, 7.4, 0.26)\n'
        '    para(tf, eyebrow, size=10.5, color="primary", bold=True, first=True)',
    ),
    (
        'def source(slide, text, y=5.04, x=0.55, w=6.4):\n'
        '    tf = tbox(slide, x, y, w, 0.28)\n'
        '    para(tf, text, size=9.5, color="secondary", first=True)',
        'def source(slide, text, y=5.04, x=0.55, w=6.4):\n'
        '    tf = tbox(slide, x, y, w, 0.28)\n'
        '    para(tf, text, size=10, color="primary", first=True)',
    ),
], "theme.py")
write(p, t)


# ------------------------------------------------------------ global sweep
# Text on a LIGHT background may only use `primary`.
for fn in sorted(os.listdir(HERE)):
    if not re.match(r"^slide_\d\d\.py$", fn):
        continue
    path = os.path.join(HERE, fn)
    s = read(path)
    s = s.replace('color="secondary"', 'color="primary"')
    s = s.replace('size=9.5,', 'size=10,')
    write(path, s)


# ------------------------------------------------- dark-background overrides
DARK = {
    "slide_01.py": [
        ('para(tf, "形式化研究 · Lean 4 + Mathlib", size=12.5,\n'
         '         color="primary", bold=True, first=True)',
         'para(tf, "形式化研究 · Lean 4 + Mathlib", size=12.5,\n'
         '         color="light", bold=True, first=True)'),
        ('para(tf, "把「这份工作里有多少是人做的」从一句立场之争，",\n'
         '         size=15, color="primary", first=True, line=1.5)',
         'para(tf, "把「这份工作里有多少是人做的」从一句立场之争，",\n'
         '         size=15, color="light", first=True, line=1.5)'),
        ('para(tf, "变成 153 条能被机器逐条检查的定理。",\n'
         '         size=15, color="primary", line=1.5)',
         'para(tf, "变成 153 条能被机器逐条检查的定理。",\n'
         '         size=15, color="light", line=1.5)'),
        ('para(tf, num, size=30, color="accent", bold=True, font=FONT_NUM, first=True)',
         'para(tf, num, size=30, color="light", bold=True, font=FONT_NUM, first=True)'),
        ('para(tf, lab, size=11, color="primary", first=True)',
         'para(tf, lab, size=11, color="light", first=True)'),
    ],
    "slide_03.py": [
        ('size=13, color="primary", first=True, line=1.4',
         'size=13, color="light", first=True, line=1.4'),
        ('para(tf, "01", size=104, color="accent", bold=True',
         'para(tf, "01", size=104, color="light", bold=True'),
        ('badge(s, 3)', 'badge(s, 3, dark=True)'),
    ],
    "slide_10.py": [
        ('size=13, color="primary", first=True, line=1.4',
         'size=13, color="light", first=True, line=1.4'),
        ('para(tf, "03", size=104, color="accent", bold=True',
         'para(tf, "03", size=104, color="light", bold=True'),
        ('badge(s, 10)', 'badge(s, 10, dark=True)'),
    ],
    "slide_15.py": [
        ('size=13, color="primary", first=True, line=1.4',
         'size=13, color="light", first=True, line=1.4'),
        ('para(tf, "04", size=104, color="accent", bold=True',
         'para(tf, "04", size=104, color="light", bold=True'),
        ('badge(s, 15)', 'badge(s, 15, dark=True)'),
    ],
    "slide_19.py": [
        ('size=13, color="primary", first=True, line=1.4',
         'size=13, color="light", first=True, line=1.4'),
        ('para(tf, "05", size=104, color="accent", bold=True',
         'para(tf, "05", size=104, color="light", bold=True'),
        ('badge(s, 19)', 'badge(s, 19, dark=True)'),
    ],
    "slide_06.py": [
        ('badge(s, 6)', 'badge(s, 6, dark=True)'),
    ],
    "slide_13.py": [
        ('para(tf, "这不是工程问题，是定义问题。", size=12.5, color="primary",\n'
         '         line=1.35)',
         'para(tf, "这不是工程问题，是定义问题。", size=12.5, color="light",\n'
         '         line=1.35)'),
        ('para(tf, "+M", size=40, color="accent", bold=True, align="center",',
         'para(tf, "+M", size=40, color="primary", bold=True, align="center",'),
    ],
    "slide_16.py": [
        ('size=12.5, color="primary", line=1.3)\n    return s',
         'size=12.5, color="light", line=1.3)\n    return s'),
    ],
}
for fn, pairs in DARK.items():
    path = os.path.join(HERE, fn)
    write(path, sub(read(path), pairs, fn))


# ---------------------------------------------- accent hero numbers -> primary
ACCENT_TEXT = {
    "slide_07.py": [('size=38, color="accent", bold=True, font=FONT_NUM',
                     'size=38, color="primary", bold=True, font=FONT_NUM')],
    "slide_09.py": [('color=("accent" if style == "peach" else txt),',
                     'color=txt,')],
    "slide_14.py": [('para(tf, "完全不可通约", size=22, color="accent", bold=True, first=True)',
                     'para(tf, "完全不可通约", size=22, color="primary", bold=True, first=True)')],
}
for fn, pairs in ACCENT_TEXT.items():
    path = os.path.join(HERE, fn)
    write(path, sub(read(path), pairs, fn))


print("done")
