# -*- coding: utf-8 -*-
"""Emit the manuscript as a LaTeX source file.

Why this exists
---------------
The Word path goes through a hand-written OpenXML generator, where every
typographic decision is a twip count passed to a helper. First-line indents,
leading, and the spacing between a claim and the equation it follows all end
up as literal numbers in C#, which is a poor place to be tuning typography,
and the output reads as uneven for that reason.

LaTeX takes all of it from the document class and the preamble, where it is
declarative and one change moves every occurrence. Equations also stop being
PNG: they were already LaTeX in `content.py`, and the old pipeline
rasterised them to `assets_eq/*.png` and embedded the raster. Here they stay
selectable and searchable.

The content model is unchanged. `content.py` remains the single source of
truth, exactly as it does for the Word path, so the title, the author and the
two identifiers are still written once and reach both outputs.

`preamble.tex` is hand-maintained and read from disk rather than embedded
here. Typography is the thing most worth editing by eye.

Usage, from the repository root:

    python paper/tex/emit_tex.py            # write paper/tex/main.tex
    python paper/tex/emit_tex.py --check    # fail if main.tex is stale
    python paper/tex/emit_tex.py --build    # also run xelatex twice

`--check` exists because main.tex is committed: arXiv wants the source, but a
committed generated file is a drift hazard unless something verifies it. The
check is wired into CI for the same reason final_check.py exists.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PAPER = os.path.dirname(HERE)
DOCX_BUILD = os.path.join(PAPER, "docx_build")
sys.path.insert(0, DOCX_BUILD)

import content  # noqa: E402  (needs the path above)

TITLE_BEGIN = "%% BEGIN TITLE BLOCK -- replaced by emit_tex.py"
TITLE_END = "%% END TITLE BLOCK"


# ── inline text → LaTeX ──────────────────────────────────────────────────────

# Characters that only ever occur inside mathematics in this manuscript:
# Greek letters, the three relations used, Unicode digit subscripts, the
# combining macron over a bar symbol, and small-cap subscript letters.
GREEK = "\u03A6\u03B1\u03B2\u03B3\u03B4\u03BB\u03C6\u03C4"
RELATIONS = "\u2264\u2265\u2192\u2212"
SUBSCRIPT_DIGITS = "\u2080\u2081\u2082\u2083\u2084\u2085\u2086\u2087\u2088\u2089"
EXTRA_MATH = "\u209C\u0304\u1D04\u00B2"
MATH_TRIGGERS = set(GREEK + RELATIONS + SUBSCRIPT_DIGITS + EXTRA_MATH)

# A math run. Sentence punctuation is absent on purpose so a run stops at a
# comma; a trailing comma or period is trimmed back out afterwards and
# re-emitted as text, because the same character inside math mode is a
# different glyph with different spacing.
MATH_RUN = re.compile(
    "[A-Za-z0-9"
    + GREEK + RELATIONS + SUBSCRIPT_DIGITS + EXTRA_MATH
    + r"_^()\[\]{}+\-*/=<>|."
    + "]+"
)

SUBSCRIPT_RE = re.compile(r"[A-Za-z]+_[A-Za-z0-9]")

# A caret followed by a value is an exponent, as in (1 - q)^N. Escaping it
# would print a literal "^" and lose the exponent.
SUPERSCRIPT_RE = re.compile(r"\^[A-Za-z0-9]")

# A short "X_c" is the one shape that is plausibly a subscript. Everything
# else with an underscore is a Lean declaration name and must not be touched.
# The rule is safe here because this manuscript writes subscripts in Unicode
# (N₀, e₀, Nₜ) rather than with an underscore: of the seventeen underscore
# tokens in the prose, all seventeen are declarations in Provenance/ and none
# is a subscript. Letting the general "has an underscore" case fall through to
# math mode rendered `human_gain_unbounded` as human_(gain)un_(bounded).
SHORT_SUBSCRIPT_RE = re.compile(
    "^[A-Za-z" + GREEK + "]{1,2}_[A-Za-z0-9]$")

# LaTeX needs \texttt rather than \emph for these: they are names in a proof
# assistant, and a reader has to be able to type them back into Lean exactly.

# Unicode digit subscripts, small-cap subscripts and superscript two have no
# direct LaTeX spelling, so they are rewritten. Greek letters and relations
# are left alone: unicode-math sets them natively and better than a command
# spelling would.
SUBSCRIPT_MAP = {c: "_" + str(i) for i, c in enumerate(SUBSCRIPT_DIGITS)}
SUBSCRIPT_MAP["\u209C"] = "_t"
SMALLCAP_MAP = {"\u1D04": "_c", "\u1D07": "_a"}
SUPERSCRIPT_MAP = {"\u00B2": "^{2}"}

# A combining macron over a letter, as in tau-bar and s-bar. Left as Unicode
# it is silently dropped: cmmi10 has no U+0304, and the log says "Missing
# character" while the PDF still gets produced. A letter with no bar and a
# letter with a bar are different quantities, so this has to be a real accent
# rather than a dropped glyph. The class covers Latin as well as Greek
# because s-bar is spelled with a plain s.
MACRON_RE = re.compile("([A-Za-z" + GREEK + "])\u0304")

# Escaped outside math mode only. Inside math mode these are already handled
# by to_math, and escaping them there would produce a literal backslash.
# `*` and `^` are absent on purpose: both are used as operators in the prose
# (p*c, lambda*TV, (1 - q)^N), not as markup.
ESCAPE = {
    "&": r"\&", "%": r"\%", "#": r"\#", "$": r"\$",
    "{": r"\{", "}": r"\}", "_": r"\_",
}


def to_math(token: str) -> str:
    for src, dst in SUBSCRIPT_MAP.items():
        token = token.replace(src, dst)
    for src, dst in SMALLCAP_MAP.items():
        token = token.replace(src, dst)
    for src, dst in SUPERSCRIPT_MAP.items():
        token = token.replace(src, dst)
    # After the digit rewrites, so a macron over a converted subscript is
    # still caught.
    token = MACRON_RE.sub(r"\\bar{\1}", token)
    return token


def escape_text(text: str) -> str:
    return "".join(ESCAPE.get(ch, ch) for ch in text)


def is_math(token: str) -> bool:
    return (any(ch in MATH_TRIGGERS for ch in token)
            or bool(SUBSCRIPT_RE.search(token))
            or bool(SUPERSCRIPT_RE.search(token)))


def is_identifier(token: str) -> bool:
    """True for a Lean declaration name.

    Checked before is_math(), because a declaration name is lexically
    indistinguishable from a subscripted expression and the two want opposite
    treatment.
    """
    return "_" in token and not SHORT_SUBSCRIPT_RE.match(token)


def inline(text: str) -> str:
    """Convert one run of prose into LaTeX.

    There is deliberately no emphasis pass. An earlier version turned
    *text* into \\textit, which was wrong for this manuscript: every
    asterisk in the prose is multiplication -- p*c, lambda*TV, the optimum
    N* -- and the pass rewrote "p*c + A*max" as italic text spanning the
    arithmetic. content.py has no emphasis markup in it at all, and neither
    does the Word output, so removing the pass makes the two agree.
    """
    out: list[str] = []
    pos = 0
    for m in MATH_RUN.finditer(text):
        out.append(escape_text(text[pos:m.start()]))
        token = m.group(0)

        # Hand trailing sentence punctuation back to text mode: a comma
        # inside math mode is a different glyph with different spacing.
        trail = ""
        while token and token[-1] in ".,":
            trail = token[-1] + trail
            token = token[:-1]

        if token and is_identifier(token):
            # ' would typeset as a curly quote inside \texttt; a Lean name has
            # to survive a copy-paste back into the editor.
            #
            # The \allowbreak after every underscore is the point of this
            # branch. hyphenat[htt] lets \texttt hyphenate, but it hyphenates
            # using patterns from a natural-language dictionary, and
            # scale_by_new_layers_not_by_headcount has no natural syllable
            # structure -- so LaTeX still pushed it 160pt past the margin.
            # An underscore is where a reader would break a name anyway.
            # Escape first, then insert the break points. The other order
            # escapes the braces in \allowbreak{} into literal ones, the
            # command never runs, and the overflow got worse rather than
            # better.
            body = escape_text(token.replace("'", r"\textquotesingle{}"))
            body = body.replace("\\_", r"\_\allowbreak{}")
            out.append("\\texttt{%s}" % body)
        elif token and is_math(token):
            out.append("$" + to_math(token) + "$")
        else:
            out.append(escape_text(token))
        out.append(trail)
        pos = m.end()
    out.append(escape_text(text[pos:]))
    return "".join(out)


# ── block rendering ──────────────────────────────────────────────────────────

def caption_body(caption: str) -> str:
    """Drop the hand-written "Figure N | " prefix.

    LaTeX assigns the number, so a caption must not also carry one. The
    prefix is stripped rather than trusted: check_figure_order() refuses to
    emit unless LaTeX's own numbering reproduces what the captions claim,
    because the prose refers to figures by number.
    """
    return re.sub(r"^\s*Figure\s+\d+\s*\|\s*", "", caption).strip()


def emit_blocks(blocks) -> str:
    out: list[str] = []
    in_abstract = False
    abstract_open = False

    for b in blocks:
        kind = b["t"]

        if kind == "h1":
            if b["text"].strip().lower() == "abstract":
                out.append("\\begin{abstract}\n")
                abstract_open = True
                in_abstract = True
            else:
                if abstract_open:
                    out.append("\\end{abstract}\n")
                    abstract_open = False
                in_abstract = False
                # Starred, so the hand-written section numbers in the heading
                # text survive verbatim. Auto-numbering would renumber the
                # headings while the prose kept saying "section 8", and the
                # two would drift the first time a section was added.
                out.append("\\section*{%s}\n" % b["text"])

        elif kind == "h2":
            out.append("\\subsection*{%s}\n" % b["text"])

        elif kind == "p":
            out.append(inline(b["text"]) + "\n")

        elif kind == "eq":
            out.append("\\begin{equation}\n%s\n\\tag{%s}\n\\end{equation}\n"
                       % (content.EQS[b["key"]], b["num"]))

        elif kind == "fig":
            name, width, cap = content.FIGS[b["key"]]
            out.append(
                "\\begin{figure}[tb]\n\\centering\n"
                "\\includegraphics[width=%.2fin]{../figures/%s}\n"
                "\\caption{%s}\n\\label{fig:%s}\n\\end{figure}\n"
                % (width, name, inline(caption_body(cap)), b["key"]))

        elif kind == "refs":
            out.append("\\begin{thebibliography}{99}\n")
            for i, item in enumerate(b["items"], start=1):
                out.append("\\bibitem{ref%d} %s\n" % (i, reference_body(item)))
            out.append("\\end{thebibliography}\n")

    if abstract_open:
        out.append("\\end{abstract}\n")

    return "".join(out)


def reference_body(item: str) -> str:
    """Render one reference, turning its DOI into a working link.

    The entries are pre-formatted strings from content.py, and a DOI like
    10.1890/0012-9658(2002)083[2248:ESORWD]2.0.CO;2 contains parentheses and
    brackets that \\url handles but inline text would not.
    """
    url = re.search(r"(https?://\S+)", item)
    if not url:
        return inline(item)
    link = r"\url{%s}" % url.group(1)
    return inline(item).replace(inline(url.group(1)), link)


# ── checks ───────────────────────────────────────────────────────────────────

def check_figure_order(blocks) -> list[str]:
    """Confirm LaTeX's numbering will match the numbers the prose assumes.

    The captions were hand-numbered in argument order before this pipeline
    existed. LaTeX now assigns the number, so the two must agree; if they do
    not, "Figure 5(b)" in the prose would point at a different panel.
    """
    problems = []
    expected = 0
    for b in blocks:
        if b["t"] != "fig":
            continue
        expected += 1
        cap = content.FIGS[b["key"]][2]
        m = re.match(r"\s*Figure\s+(\d+)\s*\|", cap)
        if not m:
            problems.append("caption for %s carries no Figure number" % b["key"])
        elif int(m.group(1)) != expected:
            problems.append(
                "figure %s would be numbered %d by LaTeX but its caption says %s"
                % (b["key"], expected, m.group(1)))
    return problems


def build_tex() -> str:
    with open(os.path.join(HERE, "preamble.tex"), encoding="utf-8") as fh:
        preamble = fh.read()

    meta = content.META
    title_block = "\n".join([
        TITLE_BEGIN,
        "\\fancyhead[L]{\\small %s}" % meta["running_head"],
        "\\fancyhead[R]{\\small\\thepage}",
        "",
        "\\title{\\textbf{%s}}" % inline(meta["title"]),
        # Every line here carries content after its break. A \\[n] immediately
        # before the closing brace is a paragraph break with nothing following
        # it, and LaTeX stops with "Paragraph ended before \author was
        # complete". The identifiers belong to the byline, not the date, so
        # they go on their own lines here.
        "\\author{%s\\\\ \\small %s\\\\[6pt]"
        "        \\small %s\\\\ \\small %s}"
        % (meta["author"], meta["affiliation"], meta["orcid"], meta["doi"]),
        "\\date{}",
        "",
        "\\maketitle",
        "\\thispagestyle{fancy}",
        TITLE_END,
    ])

    if TITLE_BEGIN not in preamble or TITLE_END not in preamble:
        raise SystemExit(
            "preamble.tex no longer carries the title-block markers; "
            "emit_tex.py has nothing to inject into.")

    head, _, tail = preamble.partition(TITLE_BEGIN)
    _, _, rest = tail.partition(TITLE_END)

    return (head + title_block + rest
            + emit_blocks(content.BLOCKS)
            + "\n\\end{document}\n")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit nonzero if main.tex differs from the model")
    ap.add_argument("--build", action="store_true",
                    help="run xelatex twice afterwards")
    args = ap.parse_args()

    problems = check_figure_order(content.BLOCKS)
    if problems:
        for p in problems:
            print("  figure order: %s" % p)
        print("\nREFUSING TO EMIT: the prose refers to figures by number.")
        return 1

    out_path = os.path.join(HERE, "main.tex")
    tex = build_tex()

    if args.check:
        current = ""
        if os.path.exists(out_path):
            with open(out_path, encoding="utf-8") as fh:
                current = fh.read()
        if current != tex:
            print("main.tex is stale; run: python paper/tex/emit_tex.py")
            return 1
        print("main.tex is up to date")
        return 0

    with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(tex)
    print("wrote %s (%d bytes)" % (out_path, len(tex)))

    if args.build:
        for _ in range(2):  # second pass settles figure references
            subprocess.run(["xelatex", "--enable-installer",
                            "-interaction=nonstopmode", "main.tex"],
                           cwd=HERE, check=False)
        # xelatex always names its output after the job, so the build would
        # otherwise ship a file called main.pdf. A release asset downloaded
        # from that arrives with the title on the filesystem, and a corpus
        # builder sees a contentless filename.
        built = os.path.join(HERE, "main.pdf")
        shipped = os.path.join(HERE, "two_saturating_operators.pdf")
        shutil.copyfile(built, shipped)
        print("built %s" % shipped)
    return 0


if __name__ == "__main__":
    sys.exit(main())
