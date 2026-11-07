# -*- coding: utf-8 -*-
"""Do the prose claims and the Lean statements say the same thing?

The kernel checks that a proof has the type its statement declares. It cannot
check that the statement is the claim you meant, and it cannot check that the
sentence written above the theorem says what the theorem proves. Those are the
failures this repository has actually made: the contamination bound's theorem
proved `π * TV₀ ≥ 2δ` while its docstring said the negation, `π ≤ 2δ/TV₀`; and
`accumulate_no_decay` is documented as the case where the human source is
reinserted at full weight, which is the case where its weight is zero.

So this compares the two layers mechanically.

The comparison of a relation is exact rather than inferred. Deciding that a
prose sentence and a Lean conclusion contradict each other from the symbols
they mention is not decidable: `the marginal gain is ≥ w_z` and
`w z ≤ coverage ... - coverage ...` are the same inequality written in the two
directions, and any automatic reading of the two mistakes one for the other.
So `tools/statement_coverage.json` pairs each prose formula with the fragment
of the Lean conclusion it stands for, and this script checks that

  * the prose formula is still in the file, verbatim;
  * the Lean fragment is still in the file, verbatim;
  * the two carry the same relation, so a reversal in either one is caught;
  * every symbol in the prose formula occurs in the Lean fragment.

The register also holds two things a script cannot invent. `gaps` records the
places where a claim is deliberately broader than its proof, and each one is
checked in both directions: a gap that closes fails the guard until the prose
that reports it is updated. `glossary` records the wording a symbol must carry
everywhere, so that two docstrings cannot give one symbol two meanings.

On top of that, three checks run without any register:

  * a theorem named in the tracked prose must exist in the tree;
  * a theorem whose *name* attributes the result to an agent the statement does
    not model is reported, and accepted only under a recorded naming
    convention;
  * every declaration without a docstring is reported, because there is no
    prose to compare and that is worth knowing.

    python tools/statement_adequacy.py            # report and exit status
    python tools/statement_adequacy.py --scan     # advisory, finds candidates
    python tools/statement_adequacy.py --json     # machine-readable report

Exit status is 0 when nothing fails, 1 otherwise. An acknowledged gap is not a
failure; it is a line in the report, and it has to stay there.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEAN_DIR = ROOT / "Provenance"
REGISTER_PATH = ROOT / "tools" / "statement_coverage.json"
PROSE_FILES = ["ORIENTATION.md", "README.md"]

# ---------------------------------------------------------------------------
# Lean source parsing
# ---------------------------------------------------------------------------

DECL_RE = re.compile(r"(?m)^[ \t]*(theorem|lemma)\s+([A-Za-z_][A-Za-z0-9_'.]*)")
OPEN_DELIM = {"(": ")", "{": "}", "[": "]"}


class Declaration:
    """One theorem or lemma, with the prose that sits above it.

    `conclusion` is whitespace-normalised for reading. `conclusion_raw` is the
    same span taken verbatim from the file, which is what the register pairs a
    prose formula against: a fragment that is not a literal substring of the
    source cannot be checked by looking for it.
    """

    def __init__(self, name, path, doc, hypotheses, conclusion,
                 hypotheses_raw="", conclusion_raw=""):
        self.name = name
        self.path = path
        self.doc = doc
        self.hypotheses = hypotheses
        self.conclusion = conclusion
        self.hypotheses_raw = hypotheses_raw
        self.conclusion_raw = conclusion_raw

    @property
    def statement(self):
        return (self.hypotheses + " " + self.conclusion).strip()

    def __repr__(self):
        return "<%s %s>" % (self.name, self.path)


def strip_comments(text):
    """Blank out every comment, keeping the offsets intact.

    Returns `(code, docs)`, where `code` is `text` with each comment replaced
    by spaces of the same length, and `docs` is the list of `(start, end,
    body)` for every `/-- ... -/` block. The offsets are what let a docstring
    be matched to the declaration it documents without guessing.
    """
    out = list(text)
    docs = []
    i = 0
    n = len(text)
    while i < n:
        if text.startswith("--", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
            continue
        if text.startswith("/-", i):
            is_doc = text.startswith("/--", i)
            depth = 1
            j = i + 1
            while j < n and depth > 0:
                if text.startswith("/-", j):
                    depth += 1
                    j += 2
                    continue
                if text.startswith("-/", j):
                    depth -= 1
                    j += 2
                    continue
                j += 1
            if is_doc:
                docs.append((i, j, text[i + 3:j - 2]))
            for k in range(i, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j
            continue
        i += 1
    return "".join(out), docs


def split_signature(code, start):
    """Cut a declaration's signature out of the code.

    The signature ends at the `:=` that introduces the proof, or at a `by` that
    starts one. Returns the signature text.
    """
    depth = 0
    stop = len(code)
    i = start
    n = len(code)
    while i < n:
        ch = code[i]
        if ch in OPEN_DELIM:
            depth += 1
        elif ch in ")}]":
            depth -= 1
        elif depth == 0:
            if code.startswith(":=", i):
                stop = i
                break
            if code.startswith("by", i):
                before = code[i - 1] if i > 0 else " "
                after = code[i + 2] if i + 2 < n else " "
                if before.isspace() and (after.isspace() or after == ""):
                    stop = i
                    break
        i += 1
    return code[start:stop]


def split_conclusion(signature):
    """Separate the hypotheses from the goal.

    The separator is the first colon at bracket depth zero: every hypothesis
    sits inside `{}` or `()`, so its own colon is deeper. Taking the *last*
    depth-zero colon instead would eat the `ℝ` in a goal like
    `∃ Φα Φβ : ℝ, ...` and report the type as part of the conclusion.
    """
    depth = 0
    for i, ch in enumerate(signature):
        if ch in OPEN_DELIM:
            depth += 1
        elif ch in ")}]":
            depth -= 1
        elif ch == ":" and depth == 0:
            return signature[:i], signature[i + 1:]
    return signature, ""


def parse_file(path):
    """Every declaration in one Lean file, with its docstring."""
    text = path.read_text(encoding="utf-8")
    code, docs = strip_comments(text)
    found = []
    for m in DECL_RE.finditer(code):
        name = m.group(2)
        sig = split_signature(code, m.end())
        hypotheses, conclusion = split_conclusion(sig)
        # The same span, verbatim. `strip_comments` keeps the offsets, so the
        # slice indexes into the original file too.
        raw = text[m.end():m.end() + len(sig)]
        hyp_raw, concl_raw = split_conclusion(raw)

        doc = None
        for start, end, body in docs:
            if end <= m.start() and code[end:m.start()].strip() == "":
                doc = body
        found.append(Declaration(name, path, doc, hypotheses.strip(),
                                  " ".join(conclusion.split()),
                                  hyp_raw.strip(), concl_raw.strip()))
    return found


def all_declarations():
    decls = []
    for path in sorted(LEAN_DIR.glob("*.lean")):
        decls.extend(parse_file(path))
    return decls


# ---------------------------------------------------------------------------
# Symbols and relations
# ---------------------------------------------------------------------------

GREEK = {
    "π": "pi", "δ": "delta", "φ": "phi", "Φ": "phi", "α": "alpha", "β": "beta",
    "γ": "gamma", "Γ": "gamma", "ε": "epsilon", "ϵ": "epsilon", "η": "eta",
    "λ": "lambda", "μ": "mu", "ν": "nu", "ρ": "rho", "σ": "sigma", "τ": "tau",
    "θ": "theta", "ϑ": "theta", "κ": "kappa", "ω": "omega", "ψ": "psi",
    "χ": "chi", "ξ": "xi", "ζ": "zeta", "Ψ": "psi",
}

SUBSCRIPTS = str.maketrans("₀₁₂₃₄₅₆₇₈₉", "0123456789")

LATEX_GREEK = {
    "pi": "pi", "delta": "delta", "phi": "phi", "varphi": "phi",
    "alpha": "alpha", "beta": "beta", "gamma": "gamma", "epsilon": "epsilon",
    "varepsilon": "epsilon", "eta": "eta", "lambda": "lambda", "mu": "mu",
    "nu": "nu", "rho": "rho", "sigma": "sigma", "tau": "tau", "theta": "theta",
    "vartheta": "theta", "kappa": "kappa", "omega": "omega", "psi": "psi",
    "chi": "chi", "xi": "xi", "zeta": "zeta", "ell": "ell",
}

# Two spellings of the same quantity. The prose says `TV` and `TV₀`; the
# tree says `totalVariation`. Without this, a prose claim about the separation
# would look like it was about nothing in the statement.
SYNONYMS = {
    "tv": "totalvariation", "tv0": "totalvariation", "tv1": "totalvariation",
    "totalvariation": "totalvariation",
}

# Words that carry no information about what is being compared.
STOPWORDS = set("""
a an the of in to is are was were be been being and or not no for with that
this these those it its as by on at from into onto up down over under then than
so if but such can could may might must shall should will would do does did
has have had all any each every one two three both either neither more most
less least very much many few only also still just even because since while
when where which what who whom whose there here their they them their our ours
your yours my mine he she him her his hers i we you me us
log exp real nat fin set finset pmf prop proof ok
""".split())


def normalise_symbol(token):
    """Reduce one symbol to a comparable key."""
    t = token.translate(SUBSCRIPTS)
    t = t.replace("\\", "").replace("{", "").replace("}", "")
    t = t.replace("_", "")
    t = t.lower()
    if t in GREEK:
        t = GREEK[t]
    elif t in LATEX_GREEK:
        t = LATEX_GREEK[t]
    if t in SYNONYMS:
        t = SYNONYMS[t]
    return t


def symbols_of(text):
    """The set of normalised content symbols in a piece of text."""
    found = set()
    for raw in re.findall(r"[A-Za-z][A-Za-z0-9]*|[\u0370-\u03ff]",
                          text.replace("_", " ")):
        key = normalise_symbol(raw)
        if key and key not in STOPWORDS:
            found.add(key)
    return found


def symbol_keys(symbol):
    """The token keys a registered symbol stands for.

    `TV₀` is one symbol written in two pieces, and `π₁` is a Greek letter with
    a subscript. Both have to reduce to something that `symbols_of` can find
    in the other side of the comparison.
    """
    keys = set()
    for raw in re.findall(r"[A-Za-z][A-Za-z0-9]*|[\u0370-\u03ff]",
                           symbol.replace("_", " ")):
        key = normalise_symbol(raw)
        if key and key not in STOPWORDS:
            keys.add(key)
    return keys


def relation_of(text):
    """The first relation operator in a fragment, or None."""
    for op in ("≥", "≤", "≠", "=", "<", ">"):
        if op in text:
            return op
    return None


def relations_in(text):
    """Every relation operator occurring in a piece of text."""
    found = []
    for op in ("≥", "≤", "≠", "=", "<", ">"):
        found.extend(op for _ in range(text.count(op)))
    return found


OPPOSITE = {"≥": "≤", "≤": "≥", ">": "<", "<": ">", "=": "≠", "≠": "="}

# Phrases that assert a relation in words. Matched longest-first so that
# "does not exceed" is not also read as "exceed".
REL_PHRASES = [
    (r"does not exceed", "≤"),
    (r"never exceeds", "≤"),
    (r"cannot exceed", "≤"),
    (r"is at most", "≤"),
    (r"at most", "≤"),
    (r"no more than", "≤"),
    (r"no larger than", "≤"),
    (r"not exceed", "≤"),
    (r"is bounded above by", "≤"),
    (r"bounded above by", "≤"),
    (r"at least", "≥"),
    (r"no smaller than", "≥"),
    (r"is bounded below by", "≥"),
    (r"bounded below by", "≥"),
    (r"exceeds", ">"),
    (r"is greater than", ">"),
    (r"greater than", ">"),
    (r"is smaller than", "<"),
    (r"smaller than", "<"),
    (r"is strictly less than", "<"),
]

CODE_SPAN_RE = re.compile(r"`([^`]+)`")
INLINE_MATH_RE = re.compile(r"\\\((.+?)\\\)|\$\$?(.+?)\$\$?", re.S)
INDENTED_RE = re.compile(r"(?m)^[ \t]{4,}(\S.*)$")


def math_spans(doc):
    """The formula-shaped pieces of a docstring.

    Backticked code, inline LaTeX and indented blocks. A docstring states its
    claim in one of those; the sentences around it carry the argument.
    """
    spans = []
    for m in CODE_SPAN_RE.finditer(doc):
        spans.append(m.group(1))
    for m in INLINE_MATH_RE.finditer(doc):
        spans.append(m.group(1) or m.group(2) or "")
    for m in INDENTED_RE.finditer(doc):
        spans.append(m.group(1))
    return [s for s in spans if s.strip()]


def prose_relations(doc):
    """Relations the docstring asserts in words, with the sentence around."""
    out = []
    for sentence in re.split(r"(?<=[.!?])\s+|\n+", doc):
        flat = " ".join(sentence.split())
        if not flat:
            continue
        taken = []
        for pattern, op in REL_PHRASES:
            for m in re.finditer(pattern, flat, re.I):
                if any(not (m.end() <= a or m.start() >= b)
                       for a, b in taken):
                    continue
                taken.append((m.start(), m.end()))
                out.append((op, flat))
    return out


def formula_relations(doc):
    """Relations the docstring asserts in a formula."""
    out = []
    for span in math_spans(doc):
        op = relation_of(span)
        if op is None:
            continue
        out.append((op, symbols_of(span), span))
    return out


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

# Terms that name an agent. A statement that mentions none of them cannot
# support a claim about who does something.
ACTOR_TERMS = ["human", "ai", "agent", "model", "researcher", "operator",
               "practitioner", "author", "scientist", "team", "participant"]


def actors_in(text):
    """The agent terms a piece of text names."""
    low = text.lower()
    found = set()
    for term in ACTOR_TERMS:
        if re.search(r"\b%s\b" % re.escape(term), low):
            found.add(term)
    return found


def check_claims(decls, register):
    """The registered prose/statement pairs, in both directions."""
    problems = []
    notes = []
    by_name = {d.name: d for d in decls}

    for entry in register.get("claims", []):
        name = entry.get("theorem", "")
        decl = by_name.get(name)
        if decl is None:
            problems.append("register: %s is not a declaration in the tree"
                            % name)
            continue

        prose_anchor = entry.get("prose_anchor", "")
        lean_fragment = entry.get("lean_fragment", "")
        if not prose_anchor or not lean_fragment:
            problems.append("register: the claim for %s needs both a "
                            "prose_anchor and a lean_fragment" % name)
            continue

        prose_file = entry.get("prose_file")
        prose_path = (ROOT / prose_file if prose_file else decl.path)
        if not prose_path.exists():
            problems.append("register: the claim for %s points at %s, which "
                            "does not exist" % (name, prose_file))
            continue
        prose_text = prose_path.read_text(encoding="utf-8")
        lean_text = decl.path.read_text(encoding="utf-8")

        if prose_anchor not in prose_text:
            problems.append(
                "register: the prose formula recorded for %s is gone, so its "
                "relation has not been checked against the statement. "
                "Anchor: %r" % (name, prose_anchor))
        if lean_fragment not in lean_text:
            problems.append(
                "register: the statement of %s no longer contains %r. The "
                "claim has to be re-read and re-recorded." % (name, lean_fragment))
            continue

        prose_rel = entry.get("prose_relation") or relation_of(prose_anchor)
        lean_rel = relation_of(lean_fragment)
        lean_rels = set(relations_in(lean_fragment))
        mode = entry.get("relation_mode", "same")

        if prose_rel and lean_rel:
            if mode == "mirror":
                # The prose states the inequality with the two sides the
                # other way round: `the marginal gain is ≥ w_z` against
                # `w z ≤ gain`. The relation must then be the opposite one,
                # which is a stronger check than equality, because it pins
                # the direction rather than just the shape.
                if prose_rel != OPPOSITE.get(lean_rel):
                    problems.append(
                        "register: %s is recorded as a mirror of the "
                        "statement, so the prose saying %r has to go with the "
                        "statement saying %r. It says %r." % (
                            name, prose_rel, OPPOSITE.get(lean_rel), lean_rel))
            elif mode == "any_of":
                if prose_rel not in lean_rels:
                    problems.append(
                        "register: %s is recorded as asserting %r, and the "
                        "statement carries %s" % (
                            name, prose_rel,
                            ", ".join(sorted(lean_rels)) or "no relation"))
            else:
                if prose_rel != lean_rel:
                    problems.append(
                        "register: %s is recorded with the prose saying %r and "
                        "the statement saying %r. One of them has been edited "
                        "and the other has not." % (name, prose_rel, lean_rel))
        elif prose_rel and not lean_rels:
            problems.append(
                "register: %s pairs a prose formula carrying %r with a "
                "statement fragment that carries no relation" % (name, prose_rel))

        for sym in entry.get("symbols", []):
            keys = symbol_keys(sym)
            if keys & symbols_of(lean_fragment):
                continue
            problems.append(
                "register: %s is recorded as being about %r, which does not "
                "occur in the fragment it is paired with" % (name, sym))

    return problems, notes


def check_gaps(decls, register):
    """The acknowledged gaps, in both directions."""
    problems = []
    notes = []
    by_name = {d.name: d for d in decls}

    for entry in register.get("gaps", []):
        name = entry.get("theorem", "")
        decl = by_name.get(name)
        if decl is None and not entry.get("file") and not entry.get("prose_file"):
            problems.append("register: the gap for %s names no declaration "
                            "and no file" % name)
            continue

        # The prose a gap is about may live in the theorem's own file, in
        # another tracked file, or nowhere a theorem is involved at all.
        prose_path = ROOT / entry["prose_file"] if entry.get("prose_file") else None
        if prose_path is None and decl is not None:
            prose_path = decl.path
        if prose_path is None:
            prose_path = ROOT / entry["file"]
        if not prose_path.exists():
            problems.append("register: the gap for %s points at %s, which "
                            "does not exist" % (name, prose_path))
            continue
        prose_source = prose_path.read_text(encoding="utf-8")

        lean_path = decl.path if decl is not None else None
        if lean_path is None and entry.get("file"):
            lean_path = ROOT / entry["file"]
        lean_source = (lean_path.read_text(encoding="utf-8")
                       if lean_path is not None else "")

        kind = entry.get("kind", "")

        if kind == "actor_not_in_statement":
            if decl is None:
                problems.append("register: the gap for %s is about an actor "
                                "in a statement, and %s is not a declaration"
                                % (name, name))
                continue
            actors = entry.get("actors", [])
            prose_has = sorted(actors_in(decl.doc or "") & set(actors))
            stmt_has = sorted(actors_in(decl.statement) & set(actors))
            if prose_has and not stmt_has:
                notes.append(
                    "gap still open: %s names %s in prose; the statement "
                    "names none. %s" % (name, ", ".join(prose_has),
                                       entry.get("note", "")))
            elif not prose_has:
                problems.append(
                    "register: the gap for %s is recorded as an actor named "
                    "in prose, but the docstring no longer names one. Either "
                    "the prose was corrected or the gap record is stale."
                    % name)
            else:
                problems.append(
                    "register: the gap for %s has closed: the statement now "
                    "names %s. Update the prose that reports the gap."
                    % (name, ", ".join(stmt_has)))
        elif kind in ("weight_inverted", "prose_wider_than_statement",
                      "not_formalised"):
            # The prose describes the situation one way and the statement
            # another. The record holds the text of both, so the record
            # cannot quietly go stale: if the prose is rewritten, the check
            # fails until the gap is either closed or re-recorded.
            prose_text = entry.get("prose_text", "")
            lean_text = entry.get("lean_text", "")
            if prose_text and prose_text not in prose_source:
                problems.append(
                    "register: the gap for %s is recorded against text that "
                    "%s no longer contains: %r"
                    % (name, prose_path.name, prose_text))
            elif lean_text and lean_text not in lean_source:
                problems.append(
                    "register: the gap for %s is recorded against a statement "
                    "fragment that is no longer there: %r" % (name, lean_text))
            else:
                notes.append("gap still open: %s. %s"
                             % (name, entry.get("note", "")))
        else:
            problems.append("register: unknown gap kind %r" % kind)

    return problems, notes


def check_glossary(decls, register):
    """The wording a symbol must carry, in both directions."""
    problems = []
    notes = []
    by_name = {d.name: d for d in decls}

    for entry in register.get("glossary", []):
        symbol = entry.get("symbol", "")
        for pattern in entry.get("forbidden", []):
            rx = re.compile(pattern, re.I)
            for path in sorted(LEAN_DIR.glob("*.lean")):
                text = path.read_text(encoding="utf-8")
                for m in rx.finditer(text):
                    line = text.count("\n", 0, m.start()) + 1
                    problems.append(
                        "glossary: %s is glossed as %r at %s:%d, which is the "
                        "wrong meaning. %s" % (
                            symbol, " ".join(m.group(0).split()),
                            path.name, line, entry.get("why", "")))
        for req in entry.get("required_in", []):
            decl = by_name.get(req.get("theorem", ""))
            if decl is None:
                problems.append("register: the glossary requires text in %s, "
                                "which is not a declaration"
                                % req.get("theorem"))
                continue
            text = req.get("text", "")
            if text not in (decl.doc or ""):
                problems.append(
                    "glossary: %s no longer carries the required wording %r. "
                    "The canonical meaning of %s has to be visible where the "
                    "symbol is used." % (decl.name, text, symbol))
            else:
                notes.append("glossary: %s keeps the required wording for %s"
                             % (decl.name, symbol))

    return problems, notes


def check_naming(decls, register):
    """The theorems whose names attribute the result to an agent.

    A name is a permanent claim about the content of a declaration. When the
    name says `human` and the statement mentions no agent, the attribution
    lives in the name rather than in the theorem. That is a naming convention
    of this framework, so it is accepted, but it is recorded and reported.
    """
    problems = []
    notes = []
    convention = register.get("naming_convention")
    for decl in decls:
        actors = actors_in(decl.name)
        if not actors:
            continue
        grounded = actors & actors_in(decl.statement)
        if grounded:
            continue
        if convention is None:
            problems.append(
                "%s: the name attributes the result to %s, and the statement "
                "names no agent. Record this under a naming convention or "
                "rename the declaration." % (decl.name, ", ".join(sorted(actors))))
        else:
            notes.append(
                "%s: the name attributes the result to %s; the statement "
                "names no agent. Accepted under the naming convention."
                % (decl.name, ", ".join(sorted(actors))))

    return problems, notes


def check_prose_names(decls):
    """Every theorem named in the tracked prose must exist in the tree."""
    names = {d.name for d in decls}
    # The root module lives outside the directory the declarations are read
    # from, so it is added by hand.
    modules = {d.path.stem for d in decls} | {"Provenance"}
    problems = []
    for rel in PROSE_FILES:
        path = ROOT / rel
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        # A citation may be qualified: `Corpus.floorOf_insert_ge`. The whole
        # backticked run is taken, so the module prefix is seen rather than
        # silently truncated at the dot.
        for m in re.finditer(r"`([A-Za-z_][A-Za-z0-9_.]*)`", text):
            token = m.group(1)
            if token.endswith((".lean", ".md", ".py", ".json", ".yml")):
                # A file reference, not a theorem reference.
                continue
            if "." in token:
                module, _, bare = token.rpartition(".")
                if module in modules and bare not in names:
                    problems.append("%s: names `%s`, and %s is not in the tree"
                                    % (rel, token, bare))
                continue
            if "_" not in token and token not in modules:
                continue
            if token in names or token in modules:
                continue
            problems.append("%s: names `%s`, which is not in the tree"
                            % (rel, token))
    return problems


def check_docstrings(decls):
    """A declaration without a docstring has no prose to compare."""
    return ["%s: no docstring" % d.name for d in decls if not d.doc]


# ---------------------------------------------------------------------------
# Advisory scan
# ---------------------------------------------------------------------------


def scan_directions(decls, register):
    """Find prose relations that do not appear in the conclusion.

    Advisory only. The same inequality written the other way round reads as a
    contradiction here, so every line has to be read before it is trusted.
    """
    retractions = register.get("retractions", [])
    out = []
    for decl in decls:
        if not decl.doc:
            continue
        lean_rels = set(relations_in(decl.conclusion))
        lean_syms = symbols_of(decl.conclusion)
        if not lean_rels:
            continue
        claims = [(op, syms, span)
                  for op, syms, span in formula_relations(decl.doc)]
        claims += [(op, symbols_of(sentence), sentence)
                   for op, sentence in prose_relations(decl.doc)]
        for op, syms, span in claims:
            if op in lean_rels:
                continue
            other = OPPOSITE.get(op)
            if other is None or other not in lean_rels:
                continue
            if not (syms & lean_syms):
                continue
            if any(r.get("text") and r["text"] in span for r in retractions):
                continue
            out.append("%s: prose asserts %r over %s; the conclusion carries "
                       "%r over %s" % (decl.name, op, ", ".join(sorted(syms)),
                                       other, ", ".join(sorted(lean_syms))))
    return out


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------


def main(argv):
    # The console code page on this machine is GBK, and the report quotes
    # mathematics. Without this the run dies on the first minus sign.
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass

    mode = "report"
    for arg in argv:
        if arg == "--scan":
            mode = "scan"
        elif arg == "--json":
            mode = "json"

    decls = all_declarations()
    register = {}
    if REGISTER_PATH.exists():
        register = json.loads(REGISTER_PATH.read_text(encoding="utf-8"))

    problems = []
    notes = []

    for result in (check_claims(decls, register),
                   check_gaps(decls, register),
                   check_glossary(decls, register),
                   check_naming(decls, register)):
        problems.extend(result[0])
        notes.extend(result[1])

    problems.extend(check_prose_names(decls))
    notes.extend(check_docstrings(decls))

    if mode == "scan":
        for line in scan_directions(decls, register):
            print(line)
        print()
        print("%d candidate(s). Advisory: read each one before believing it."
              % len(scan_directions(decls, register)))
        return 0

    if mode == "json":
        print(json.dumps({
            "declarations": len(decls),
            "problems": problems,
            "notes": notes,
        }, ensure_ascii=False, indent=2))
        return 1 if problems else 0

    print("--- statement adequacy ---")
    print("declarations parsed : %d" % len(decls))
    print("recorded claims     : %d" % len(register.get("claims", [])))
    print("acknowledged gaps   : %d" % len(register.get("gaps", [])))
    print("glossary entries    : %d" % len(register.get("glossary", [])))
    print()

    for x in notes:
        print("  note: %s" % x)
    if notes:
        print()
    for x in problems:
        print("  %-46s *** FAIL ***" % x)

    print()
    if problems:
        print("STATEMENT ADEQUACY PROBLEMS REMAIN")
        return 1
    print("STATEMENT ADEQUACY OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
