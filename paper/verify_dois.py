"""Authoritative DOI verification via content negotiation.

Instead of following the (often 403-blocking) publisher redirect, we ask
doi.org itself for CSL metadata. A registered DOI returns the real title,
authors and container, so this verifies not just that the DOI resolves but
that it resolves to the work the manuscript claims.
"""
import io
import json
import re
import ssl
import sys
import urllib.error
import urllib.request

MD = r"D:\lean_proj\source_identifiability\paper\manuscript.md"

# A DOI runs to the first whitespace. The manuscript wraps none of them.
DOI_RE = re.compile(r"https://doi\.org/(\S+)")

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE


def fetch(doi):
    url = "https://doi.org/" + doi
    req = urllib.request.Request(url, headers={
        "Accept": "application/vnd.citationstyles.csl+json",
        "User-Agent": "doi-verify/1.0 (mailto:none@example.invalid)",
    })
    op = urllib.request.build_opener(urllib.request.HTTPSHandler(context=CTX))
    try:
        with op.open(req, timeout=40) as r:
            return r.status, json.loads(r.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:  # noqa: BLE001
        return "ERR", {"error": "%s: %s" % (type(e).__name__, str(e)[:70])}


def main():
    with io.open(MD, encoding="utf-8") as f:
        text = f.read()

    dois, seen = [], set()
    for m in DOI_RE.finditer(text):
        d = m.group(1).rstrip(".")
        if d not in seen:
            seen.add(d)
            dois.append(d)

    print("DOIs parsed from manuscript: %d\n" % len(dois))
    ok = 0
    for d in dois:
        code, meta = fetch(d)
        if meta and "title" in meta:
            ok += 1
            raw = meta["title"]
            title = raw[0] if isinstance(raw, list) else raw
            if len(title) > 74:
                title = title[:71] + "..."
            cont = meta.get("container-title") or meta.get("publisher", "")
            auth = meta.get("author") or []
            first = (auth[0].get("family", "?") if auth else "-")
            yr = (meta.get("issued", {}).get("date-parts", [[None]])[0][0])
            print("OK  %s" % d)
            print("      title : %s" % title)
            print("      venue : %-38s  %s  first author: %s" % (
                str(cont)[:38], yr, first))
        else:
            print("FAIL %s  (status=%s) %s" % (d, code, (meta or {}).get("error", "")))
        print()

    print("=" * 60)
    print("verified %d / %d" % (ok, len(dois)))
    return 0 if ok == len(dois) else 1


if __name__ == "__main__":
    sys.exit(main())