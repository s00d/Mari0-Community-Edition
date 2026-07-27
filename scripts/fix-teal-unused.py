#!/usr/bin/env python3
"""Replace Teal [unused] variables/arguments with _ using cyan build output."""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CYAN = ROOT / "scripts" / "cyan"

UNUSED_RE = re.compile(
    r"^\s+\.\.\. (?P<file>[^:]+):(?P<line>\d+):(?P<col>\d+) \[unused\]\s*$"
)
NAME_RE = re.compile(
    r"^\s+\.\.\.(?:\s+│)?\s*unused (?:variable|argument) (?P<name>\S+):"
)


def collect_unused(build_output: str) -> list[tuple[str, int, int, str]]:
    lines = build_output.splitlines()
    items: list[tuple[str, int, int, str]] = []
    i = 0
    while i < len(lines):
        m = UNUSED_RE.match(lines[i])
        if m and i + 3 < len(lines):
            nm = NAME_RE.match(lines[i + 3])
            if nm:
                items.append(
                    (
                        m.group("file"),
                        int(m.group("line")),
                        int(m.group("col")),
                        nm.group("name"),
                    )
                )
        i += 1
    return items


def patch_line(line: str, col: int, name: str) -> str | None:
    # col is 1-based byte offset in Teal diagnostics
    idx = col - 1
    if name == "...":
        if idx < 0 or line[idx : idx + 3] != "...":
            return None
        return line[:idx] + "_" + line[idx + 3 :]
    if idx < 0 or idx + len(name) > len(line):
        return None
    if line[idx : idx + len(name)] != name:
        return None
    replacement = f"_{name}" if name != "..." else "_"
    return line[:idx] + replacement + line[idx + len(name) :]


def main() -> int:
    proc = subprocess.run(
        [str(CYAN), "build", "-u"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    output = proc.stdout + proc.stderr
    items = collect_unused(output)
    if not items:
        print("No [unused] warnings found.")
        return 0

    by_file: dict[str, list[tuple[int, int, str]]] = {}
    for path, line_no, col, name in items:
        by_file.setdefault(path, []).append((line_no, col, name))

    changed = 0
    for rel, patches in by_file.items():
        path = ROOT / rel
        src = path.read_text().splitlines(keepends=True)
        for line_no, col, name in sorted(patches, key=lambda t: (-t[0], -t[1])):
            idx = line_no - 1
            if idx < 0 or idx >= len(src):
                continue
            new_line = patch_line(src[idx].rstrip("\n"), col, name)
            if new_line is None:
                continue
            if new_line != src[idx].rstrip("\n"):
                suffix = "\n" if src[idx].endswith("\n") else ""
                src[idx] = new_line + suffix
                changed += 1
        path.write_text("".join(src))

    print(f"Patched {changed} unused variable sites across {len(by_file)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
