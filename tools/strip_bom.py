# -*- coding: utf-8 -*-
"""Remove a UTF-8 BOM from Python sources in the package.

A BOM is tolerated by the import system but not by `ast.parse` on a file read
as plain UTF-8, so it turns every AST-based check into a false failure. This
rewrites the affected files in place and prints what it touched.
"""

import sys
from pathlib import Path

BOM = b"\xef\xbb\xbf"
SKIP = {".git", ".lake", "node_modules", "obj", "bin", "__pycache__"}


def main(root: Path) -> int:
    touched = []
    for p in sorted(root.rglob("*.py")):
        if any(part in SKIP for part in p.parts):
            continue
        data = p.read_bytes()
        if data.startswith(BOM):
            p.write_bytes(data[len(BOM):])
            touched.append(str(p.relative_to(root)))
    for name in touched:
        print("bom stripped:", name)
    print("total_bom_stripped=%d" % len(touched))
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()))
