# -*- coding: utf-8 -*-
"""Typographic polish: ASCII maths shorthand -> real glyphs, for the DOCX only.

Word renders Times New Roman Greek and combining marks far better than the
ASCII stand-ins that are convenient while drafting. Combining macron U+0304
(U+0302 for phi-hat) was verified to compose correctly in the rendered PDF.

The mapping is applied to `content.py` in place, below the `FIGS = {` marker so
the LaTeX in `EQS` stays ASCII. Two rules keep it safe:

* every shorthand is matched on word boundaries, because `Phi` occurs inside
  "Philosophical Transactions" in reference 5 and `e0` inside DOIs;
* URLs are masked out before substitution and restored afterwards, so a DOI
  can never pick up a glyph.

Running it twice is a no-op, so it can sit in the build chain unconditionally.
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, "content.py")

# Word-boundary shorthand. `e0` and `N0` are digit-suffixed, so the boundary is
# one-sided there.
REPL = [
    # inequalities and arrows
    (r"<=", "\u2264"),
    (r">=", "\u2265"),
    (r" -> ", " \u2192 "),
    # Greek letters
    (r"\blambda\b", "\u03bb"),
    (r"\bLambda\b", "\u039b"),
    (r"\bPhi\b", "\u03a6"),
    (r"\bphi\b", "\u03c6"),
    (r"\btau\b", "\u03c4"),
    (r"\bsigma\b", "\u03c3"),
    (r"\balpha\b", "\u03b1"),
    (r"\bbeta\b", "\u03b2"),
    (r"\bdelta\b", "\u03b4"),
    # barred symbols
    (r"\bs-bar\b", "s\u0304"),
    (r"\btau-bar\b", "\u03c4\u0304"),
    (r"\bphi-hat\b", "\u03c6\u0302"),
    # sub- and superscripts
    (r"\bN_0\b", "N\u2080"),
    (r"\bN_c\b", "N\u1d04"),
    (r"\be_0\b", "e\u2080"),
    (r"\be_t\b", "e\u209c"),
    (r"\be0\b", "e\u2080"),
    # minus signs in signed numbers
    (r"(?<![\w])-(\d)", "\u2212\\1"),
]

URL_RE = re.compile(r"https?://\S+")


def polish(text: str) -> tuple[str, int]:
    """Apply the mapping, leaving every URL byte-identical."""
    urls: list[str] = []

    def mask(m: re.Match) -> str:
        urls.append(m.group(0))
        return "\x00%d\x00" % (len(urls) - 1)

    text = URL_RE.sub(mask, text)

    n = 0
    for pattern, repl in REPL:
        text, k = re.subn(pattern, repl, text)
        n += k

    return re.sub(r"\x00(\d+)\x00", lambda m: urls[int(m.group(1))], text), n


def main() -> int:
    src = open(path, encoding="utf-8").read()

    marker = "EQS = {"
    i = src.index(marker)
    j = src.index("FIGS = {")
    head, eqs, tail = src[:i], src[i:j], src[j:]

    new_tail, n = polish(tail)
    if new_tail == tail:
        print("polish: already up to date, nothing to do")
        return 0

    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(head + eqs + new_tail)

    print("applied %d replacements in the block/caption section "
          "(EQS left untouched)" % n)
    print("LaTeX block unchanged:", eqs == src[i:j])
    return 0


if __name__ == "__main__":
    sys.exit(main())
