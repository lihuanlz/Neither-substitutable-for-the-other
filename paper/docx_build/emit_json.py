# -*- coding: utf-8 -*-
"""
Normalize the document plan into content.json for the C# generator (backend S).

Resolves figure and equation keys to absolute on-disk paths so the generator
does no path guessing. Also trims the figure captions to the shortened forms.
"""
import io
import json
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import content as C

HERE = os.path.dirname(os.path.abspath(__file__))
EQDIR = os.path.join(HERE, "assets_eq")

out_blocks = []
for b in C.BLOCKS:
    t = b["t"]
    if t == "fig":
        path, width, cap = C.f(b["key"])
        if not os.path.isfile(path):
            raise SystemExit(f"missing figure: {path}")
        out_blocks.append({
            "t": "fig",
            "path": path,
            "widthIn": width,
            "cap": cap,
        })
    elif t == "eq":
        png = os.path.join(EQDIR, f"eq{b['num']:02d}.png")
        if not os.path.isfile(png):
            raise SystemExit(f"missing equation image: {png}")
        out_blocks.append({
            "t": "eq",
            "path": png,
            "num": b["num"],
        })
    else:
        out_blocks.append(b)

doc = {
    "meta": C.META,
    "blocks": out_blocks,
}

dest = os.path.join(HERE, "content.json")
with open(dest, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=1)

body = sum(len(b["text"]) for b in C.BLOCKS if b["t"] == "p")
refs = sum(len(x) for b in C.BLOCKS if b["t"] == "refs" for x in b["items"])
caps = sum(len(b["cap"]) for b in out_blocks if b["t"] == "fig")
figs = sum(1 for b in out_blocks if b["t"] == "fig")
eqs = sum(1 for b in out_blocks if b["t"] == "eq")

print(f"wrote {dest}")
print(f"  blocks     : {len(out_blocks)}")
print(f"  figures    : {figs}   equations: {eqs}")
print(f"  body prose : {body}")
print(f"  references : {refs}")
print(f"  captions   : {caps}")
print(f"  doc total  : {body + refs + caps}")
