#!/usr/bin/env python3
"""Unit tests for SMB3 BG vs solid classify (no ROM dump required)."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_smb3 import (  # noqa: E402
    classify,
    classify_at,
    is_decorative,
    parse_level_ref,
    powerup_from_block_object,
)


def expect(cond: bool, msg: str) -> None:
    if not cond:
        raise AssertionError(msg)


def test_background_scenery_nonsolid() -> None:
    for name in (
        "Background Hills A",
        "Background Hills B",
        "Background Hills C",
        "Small Background Hills",
        "Background Bushes",
        "Background Clouds",
        "Background like at bottom of hilly level",
        "Palm Tree",
        "Oval Background Cloud",
        "Background Mountain",
    ):
        c = classify(name).get("collision", 0)
        expect(c <= 0, f"{name!r} should be non-solid, got {c}")
        expect(is_decorative(name), f"{name!r} should be decorative")


def test_extend_platform_top_only() -> None:
    name = "Green Block Platform (Extends to ground)"
    top = classify_at(name, 0, 5)
    body = classify_at(name, 2, 5)
    expect(top.get("platform", 0) > 0 and top.get("collision", 0) > 0, "top row platform")
    expect(body.get("collision", 0) <= 0, "body pass-through")


def test_pipe_mouth_foreground() -> None:
    top = classify_at("Downward Pipe (CAN'T go down)", 0, 3)
    body = classify_at("Downward Pipe (CAN'T go down)", 1, 3)
    expect(top.get("foreground", 0) > 0, "pipe top row should be foreground")
    expect(body.get("foreground", 0) <= 0, "pipe body should not be foreground")


def test_real_terrain_solid() -> None:
    for name in (
        "Flat Land - Hilly",
        "Hilly Wall",
        "Upper Left Hill Corner - Hilly",
        "Ground",
        "Brick",
        "?",
        "Cloud Platform",
    ):
        c = classify(name).get("collision", 0)
        expect(c > 0, f"{name!r} should be solid, got {c}")
        expect(not is_decorative(name), f"{name!r} should not be decorative")


def test_parse_level_ref() -> None:
    expect(parse_level_ref("1-3") == (1, 3, 0), "1-3")
    expect(parse_level_ref("1-1_4") == (1, 1, 4), "1-1_4")
    expect(parse_level_ref("weird") is None, "bad")


def test_powerup_from_block_object() -> None:
    # Question blocks:
    expect(powerup_from_block_object("'?' with Leaf") == "leaf", "leaf should map to item 'leaf'")
    expect(powerup_from_block_object("'?' with flower") == "flower", "flower should map to item 'flower'")
    expect(powerup_from_block_object("'?' with star") == "star", "star should map to item 'star'")
    expect(
        powerup_from_block_object("White Mushrooms, Flowers and Stars") == "__wfstar__",
        "composite object should map to special marker",
    )
    # Coin-only variants:
    expect(
        powerup_from_block_object("'?' Blocks with single coins") is None,
        "single coins should not be powerup",
    )
    # Brick variants:
    expect(powerup_from_block_object("Brick with 1-up") == "oneup", "1-up should map to item 'oneup'")


def main() -> int:
    test_background_scenery_nonsolid()
    test_extend_platform_top_only()
    test_pipe_mouth_foreground()
    test_real_terrain_solid()
    test_parse_level_ref()
    test_powerup_from_block_object()
    print("OK test_smb3_classify")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
