#!/usr/bin/env python3
"""
Convert the IELTS vocabulary Excel sheet into the JSON bundle consumed by the app.

Usage:
    python Tools/import_vocabulary.py /path/to/IELTS_Vocabulary_100_Real.xlsx
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    import openpyxl
except ImportError as exc:  # pragma: no cover - import guard
    raise SystemExit(
        "Missing dependency 'openpyxl'. Install it via `python3 -m pip install openpyxl`."
    ) from exc


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export IELTS vocabulary Excel to JSON.")
    parser.add_argument(
        "excel_path",
        type=Path,
        help="Path to the IELTS_Vocabulary_100_Real.xlsx file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Data" / "vocabulary.json",
        help="Destination JSON file. Defaults to the app's Data/vocabulary.json.",
    )
    parser.add_argument(
        "--dataset",
        type=Path,
        default=Path(__file__).resolve().parents[1]
        / "Assets.xcassets"
        / "Vocabulary.dataset"
        / "vocabulary.json",
        help="Optional path to a data asset copy that will be kept in sync.",
    )
    return parser.parse_args()


def sanitize(value: str | None) -> str:
    if value is None:
        return ""
    return value.strip()


def write_json(entries: list[dict[str, str]], destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def convert(excel_path: Path, output_path: Path, dataset_copy: Path | None) -> None:
    workbook = openpyxl.load_workbook(excel_path)
    worksheet = workbook.active

    rows = worksheet.iter_rows(min_row=2, values_only=True)

    entries: list[dict[str, str]] = []
    for row in rows:
        word, level, definition, example, translation = row
        if not word:
            continue
        entries.append(
            {
                "word": sanitize(word),
                "level": sanitize(level),
                "definition": sanitize(definition),
                "example": sanitize(example),
                "translation": sanitize(translation),
            }
        )

    write_json(entries, output_path)
    print(f"Exported {len(entries)} entries to {output_path}")

    if dataset_copy:
        write_json(entries, dataset_copy)
        print(f"Synced dataset asset at {dataset_copy}")


def main() -> None:
    args = parse_arguments()
    convert(args.excel_path, args.output, args.dataset)


if __name__ == "__main__":  # pragma: no branch
    main()
