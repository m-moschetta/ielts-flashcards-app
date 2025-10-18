#!/usr/bin/env python3
"""
Convert an IELTS vocabulary Excel sheet into the JSON bundle consumed by the app.

The script can be run multiple times with different decks. When the output JSON
already exists, entries belonging to the same deck will be replaced.

Usage example:
    python Tools/import_vocabulary.py \
        /path/to/IELTS_Vocabulary_100_Real.xlsx \
        --deck-id core \
        --deck-name "Vocabolario Base" \
        --deck-description "100 parole ad alta frequenza per IELTS"
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
    parser.add_argument(
        "--deck-id",
        default="core",
        help="Identifier of the deck. Existing entries with the same id will be replaced.",
    )
    parser.add_argument(
        "--deck-name",
        default="Vocabolario Base",
        help="Human readable name of the deck.",
    )
    parser.add_argument(
        "--deck-description",
        default="",
        help="Optional description shown in the deck selector.",
    )
    parser.add_argument(
        "--default-level",
        default="Base",
        help="Fallback level when the spreadsheet does not provide the column.",
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


def convert(
    excel_path: Path,
    output_path: Path,
    dataset_copy: Path | None,
    deck_id: str,
    deck_name: str,
    deck_description: str,
    default_level: str,
) -> None:
    workbook = openpyxl.load_workbook(excel_path)
    worksheet = workbook.active

    rows = worksheet.iter_rows(min_row=2, values_only=True)

    existing_entries: list[dict[str, str]] = []
    if output_path.exists():
        existing_entries = json.loads(output_path.read_text(encoding="utf-8"))

    sanitized_deck_id = sanitize(deck_id).lower() or "core"
    sanitized_deck_name = sanitize(deck_name) or "Vocabolario Base"
    sanitized_description = deck_description.strip()
    fallback_level = sanitize(default_level) or "Base"

    filtered_existing = [
        entry for entry in existing_entries if entry.get("deckId", "core") != sanitized_deck_id
    ]

    new_entries: list[dict[str, str]] = []
    for row in rows:
        if not row or all(value is None or str(value).strip() == "" for value in row):
            continue

        word = sanitize(row[0] if len(row) > 0 else "")
        if not word:
            continue

        if len(row) >= 5:
            level = sanitize(row[1])
            definition = sanitize(row[2])
            example = sanitize(row[3])
            translation = sanitize(row[4])
        elif len(row) >= 4:
            level = ""
            definition = sanitize(row[1])
            example = sanitize(row[2])
            translation = sanitize(row[3])
        else:
            raise ValueError(
                "Unexpected row format. Expected 4 or 5 columns: word, (optional level), definition, example, translation."
            )

        level = level or fallback_level
        new_entries.append(
            {
                "deckId": sanitized_deck_id,
                "deckName": sanitized_deck_name,
                "deckDescription": sanitized_description,
                "word": sanitize(word),
                "level": sanitize(level),
                "definition": sanitize(definition),
                "example": sanitize(example),
                "translation": sanitize(translation),
            }
        )

    combined_entries = filtered_existing + new_entries
    combined_entries.sort(key=lambda item: (item.get("deckId", ""), item.get("word", "").lower()))

    write_json(combined_entries, output_path)
    print(
        f"Exported {len(new_entries)} entries for deck '{sanitized_deck_name}' "
        f"({sanitized_deck_id}) to {output_path}"
    )

    if dataset_copy:
        write_json(combined_entries, dataset_copy)
        print(f"Synced dataset asset at {dataset_copy}")


def main() -> None:
    args = parse_arguments()
    convert(
        excel_path=args.excel_path,
        output_path=args.output,
        dataset_copy=args.dataset,
        deck_id=args.deck_id,
        deck_name=args.deck_name,
        deck_description=args.deck_description,
        default_level=args.default_level,
    )


if __name__ == "__main__":  # pragma: no branch
    main()
