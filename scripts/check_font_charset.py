#!/usr/bin/env python3
"""Scan UI Teal sources for glyphs outside Mari0 bitmap font / bad _dirN.

Charset must match src/app/love_load.tl fontglyphs.
Directions sprite only has quads 1..6 (see boot.tl).

Usage: python3 scripts/check_font_charset.py
Exit 1 if any unsupported glyph / _dir is found in UI print paths.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FONTGLYPHS = '0123456789abcdefghijklmnopqrstuvwxyz.:/,"C-_A* !{}\'()+=><#%'
ALLOWED = set(FONTGLYPHS) | {"|"}
DIR_MIN, DIR_MAX = 1, 6

EXTRACTORS = [
    ("footer", re.compile(r'footer\s*=\s*\{[^}]*text\s*=\s*"((?:\\.|[^"\\])*)"', re.S)),
    ("properprint", re.compile(r'properprint\s*\(\s*"((?:\\.|[^"\\])*)"')),
    ("properprintbackground", re.compile(r'properprintbackground\s*\(\s*"((?:\\.|[^"\\])*)"')),
    ("menu_draw_footer", re.compile(r'menu_draw_footer\s*\([^)]*?,\s*"((?:\\.|[^"\\])*)"')),
    ("notice.new", re.compile(r'notice\.new\s*\(\s*"((?:\\.|[^"\\])*)"')),
    ("set_status", re.compile(r'set_status\s*\(\s*"((?:\\.|[^"\\])*)"')),
    (
        "guielement label",
        re.compile(
            r'guielement:new\s*\(\s*"button"\s*,\s*[^,]*\s*,\s*[^,]*\s*,\s*"((?:\\.|[^"\\])*)"'
        ),
    ),
]

SCAN_DIRS = [ROOT / "src" / "ui", ROOT / "src" / "net"]
SCAN_FILES = [
    ROOT / "src" / "app" / "love_load.tl",
]


def scan_string(s: str, where: str) -> list[str]:
    issues: list[str] = []
    i, n = 0, len(s)
    while i < n:
        if s[i : i + 4] == "_dir" and i + 4 < n and s[i + 4].isdigit():
            d = int(s[i + 4])
            if d < DIR_MIN or d > DIR_MAX:
                issues.append(f"{where}: bad _dir{d} in {s!r}")
            i += 5
            continue
        ch = s[i]
        b = ord(ch)
        if b >= 0x80:
            issues.append(f"{where}: non-ASCII U+{b:04X} in {s!r}")
            i += 1
            continue
        if ch not in ALLOWED:
            issues.append(f"{where}: unsupported {ch!r} (U+{b:04X}) in {s!r}")
        i += 1
    return issues


def unescape_tl_string(s: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == "n":
                out.append("\n")
            elif nxt == "t":
                out.append("\t")
            elif nxt == "r":
                out.append("\r")
            else:
                out.append(nxt)
            i += 2
            continue
        out.append(s[i])
        i += 1
    return "".join(out)


def main() -> int:
    files: list[Path] = []
    for d in SCAN_DIRS:
        files.extend(sorted(d.rglob("*.tl")))
    files.extend(p for p in SCAN_FILES if p.is_file())

    issues: list[str] = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(ROOT)
        for kind, cre in EXTRACTORS:
            for m in cre.finditer(text):
                s = unescape_tl_string(m.group(1))
                if kind == "notice.new":
                    s = s.lower()
                issues.extend(scan_string(s, f"{rel} [{kind}]"))

    if issues:
        print(f"FAIL {len(issues)} font-charset issue(s):")
        for msg in issues:
            print(f"  {msg}")
        return 1
    print(f"OK  font charset ({len(files)} files, glyphs+dir1..6)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
