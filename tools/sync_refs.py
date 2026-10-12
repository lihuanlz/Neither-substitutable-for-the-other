# -*- coding: utf-8 -*-
"""Regenerate the reference list embedded in `paper/docx_build/content.py`.

The manuscript is the source of truth for citations: it carries the numbering,
the check script counts DOIs there, and the reference list must not drift from
the numbers used in the prose. This copies that list into the DOCX build input
so the Word file is self-contained at build time while still being generated
rather than hand-maintained.

Run after editing the `## References` section of the manuscript:

    python tools/sync_refs.py
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANUSCRIPT = ROOT / "paper" / "manuscript.md"
CONTENT = ROOT / "paper" / "docx_build" / "content.py"

BEGIN = "# BEGIN GENERATED REFERENCES"
END = "# END GENERATED REFERENCES"

# Program.cs emits each entry as a single plain run, so emphasis markers would
# print literally. Strip them and keep the words.
_EMPH = re.compile(r"\*{1,2}")


def read_refs(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    if "## References" not in text:
        raise SystemExit("no '## References' section in %s" % path)
    tail = text.split("## References", 1)[1]
    refs = []
    for line in tail.splitlines():
        m = re.match(r"^\s*(\d+)\.\s+(.*\S)\s*$", line)
        if not m:
            continue
        refs.append(_EMPH.sub("", m.group(2)))
    if not refs:
        raise SystemExit("no numbered references parsed from %s" % path)
    # The list must stay contiguous from 1; a gap means the manuscript was
    # edited by hand and would silently mis-number the Word file.
    if [int(re.match(r"(\d+)", l).group(1)) for l in
            [r for r in tail.splitlines() if re.match(r"^\s*\d+\.\s", r)]] != \
            list(range(1, len(refs) + 1)):
        raise SystemExit("reference numbering in the manuscript is not 1..n")
    return refs


def render(refs: list[str]) -> str:
    lines = [BEGIN, "REFERENCES = ["]
    for r in refs:
        body = r.replace("\\", "\\\\").replace('"', '\\"')
        lines.append('    "%s",' % body)
    lines.append("]")
    lines.append(END)
    return "\n".join(lines)


def main() -> int:
    refs = read_refs(MANUSCRIPT)
    block = render(refs)

    src = CONTENT.read_text(encoding="utf-8")
    if BEGIN not in src or END not in src:
        raise SystemExit(
            "content.py is missing the %s / %s markers" % (BEGIN, END))

    head, rest = src.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    CONTENT.write_text(head + block + tail, encoding="utf-8")
    print("synced %d references into %s" % (len(refs), CONTENT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
