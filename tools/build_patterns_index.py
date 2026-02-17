#!/usr/bin/env python3
"""Scan contents/patterns/rle and build metadata + runtime JS pattern data."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
PATTERN_ROOT = ROOT / "contents" / "patterns"
RLE_ROOT = PATTERN_ROOT / "rle"
INDEX_PATH = PATTERN_ROOT / "index.json"
PATTERN_DATA_JS_PATH = PATTERN_ROOT / "patternData.js"

HEADER_RE = re.compile(r"x\s*=\s*(\d+)\s*,\s*y\s*=\s*(\d+)(?:\s*,\s*rule\s*=\s*([^\s]+))?", re.IGNORECASE)
PERIOD_RE = re.compile(r"\bperiod\s*(\d+)\b", re.IGNORECASE)
SPEED_RE = re.compile(r"\bc\s*/\s*(\d+)\b", re.IGNORECASE)

CATEGORY_DEFAULT_WEIGHT: Dict[str, float] = {
    "gliders": 1.2,
    "spaceships": 1.0,
    "methuselahs": 0.9,
    "oscillators": 0.8,
    "guns": 0.6,
    "still_lifes": 0.4,
}


def titleize(stem: str) -> str:
    return " ".join(part.upper() if part.isupper() else part.capitalize() for part in stem.replace("_", " ").replace("-", " ").split())


def infer_tags(stem: str, category: str) -> List[str]:
    tags = {category}
    for token in re.split(r"[^a-z0-9]+", stem.lower()):
        if len(token) > 2:
            tags.add(token)
    return sorted(tags)


def parse_rle(path: Path, hard_cell_limit: int = 250_000) -> Dict[str, object]:
    header_x = 0
    header_y = 0
    rule = "B3/S23"
    period = None
    speed = None
    data_lines: List[str] = []

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line:
            continue

        if line.startswith("#"):
            m_period = PERIOD_RE.search(line)
            if m_period:
                period = int(m_period.group(1))
            m_speed = SPEED_RE.search(line)
            if m_speed:
                speed = f"c/{m_speed.group(1)}"
            continue

        m_header = HEADER_RE.search(line)
        if m_header:
            header_x = int(m_header.group(1))
            header_y = int(m_header.group(2))
            if m_header.group(3):
                rule = m_header.group(3)
            continue

        data_lines.append(line)

    encoded = "".join(data_lines)
    cells: List[Dict[str, int]] = []
    x = 0
    y = 0
    run = ""
    max_x = 0
    max_y = 0

    for ch in encoded:
        if "0" <= ch <= "9":
            run += ch
            continue

        count = int(run) if run else 1
        run = ""

        if ch == "b":
            x += count
        elif ch == "o":
            for n in range(count):
                cells.append({"x": x + n, "y": y})
                if len(cells) > hard_cell_limit:
                    raise ValueError(f"pattern too large ({len(cells)} live cells) in {path.name}")
            x += count
            max_x = max(max_x, x)
            max_y = max(max_y, y + 1)
        elif ch == "$":
            y += count
            x = 0
            max_y = max(max_y, y + 1)
        elif ch == "!":
            break

    return {
        "bboxW": max(header_x, max_x),
        "bboxH": max(header_y, max_y),
        "rule": str(rule).upper(),
        "period": period,
        "speed": speed,
        "cells": cells,
    }


def build() -> Tuple[List[Dict[str, object]], Dict[str, Dict[str, object]]]:
    entries: List[Dict[str, object]] = []
    cell_map: Dict[str, Dict[str, object]] = {}

    for rle_file in sorted(RLE_ROOT.rglob("*.rle")):
        rel = rle_file.relative_to(PATTERN_ROOT).as_posix()
        category = rle_file.parent.name
        stem = rle_file.stem

        if stem in cell_map:
            raise ValueError(f"duplicate pattern id '{stem}' from {rle_file}")

        parsed = parse_rle(rle_file)
        entry = {
            "id": stem,
            "name": titleize(stem),
            "category": category,
            "tags": infer_tags(stem, category),
            "period": parsed["period"],
            "speed": parsed["speed"],
            "bboxW": parsed["bboxW"],
            "bboxH": parsed["bboxH"],
            "rule": parsed["rule"],
            "weight": CATEGORY_DEFAULT_WEIGHT.get(category, 1.0),
            "source": f"https://conwaylife.com/patterns/{rle_file.name}",
            "rleFile": rel,
        }
        entries.append(entry)

        cell_map[stem] = {
            "bboxW": parsed["bboxW"],
            "bboxH": parsed["bboxH"],
            "rule": parsed["rule"],
            "cells": parsed["cells"],
        }

    return entries, cell_map


def write_index(entries: List[Dict[str, object]]) -> None:
    payload = {
        "formatVersion": 1,
        "generatedBy": "tools/build_patterns_index.py",
        "patternCount": len(entries),
        "patterns": entries,
    }
    INDEX_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")


def write_pattern_data_js(entries: List[Dict[str, object]], cell_map: Dict[str, Dict[str, object]]) -> None:
    payload = {
        "formatVersion": 1,
        "generatedBy": "tools/build_patterns_index.py",
        "patternCount": len(entries),
        "patterns": entries,
    }

    js = "\n".join(
        [
            "/* Auto-generated by tools/build_patterns_index.py. Do not edit by hand. */",
            ".pragma library",
            "",
            "var patternIndex = " + json.dumps(payload, ensure_ascii=True, separators=(",", ":")) + ";",
            "",
            "var patternCellsById = " + json.dumps(cell_map, ensure_ascii=True, separators=(",", ":")) + ";",
            "",
        ]
    )
    PATTERN_DATA_JS_PATH.write_text(js, encoding="utf-8")


def main() -> None:
    entries, cell_map = build()
    write_index(entries)
    write_pattern_data_js(entries, cell_map)
    print(f"Wrote {INDEX_PATH} with {len(entries)} patterns")
    print(f"Wrote {PATTERN_DATA_JS_PATH} with {len(cell_map)} compiled pattern payloads")


if __name__ == "__main__":
    main()
