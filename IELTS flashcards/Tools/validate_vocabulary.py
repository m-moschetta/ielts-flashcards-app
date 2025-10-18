#!/usr/bin/env python3
"""
Validate the vocabulary JSON data used by the IELTS Flashcards app.

Checks performed:
  * All required fields are present and non-empty.
  * Each example sentence includes the target word.
  * Vocabulary entries share a consistent structure between
    Data/vocabulary.json and the asset catalog copy.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "Data" / "vocabulary.json"
ASSET_FILE = (
    ROOT
    / "Assets.xcassets"
    / "Vocabulary.dataset"
    / "vocabulary.json"
)


def load_entries(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Missing vocabulary file: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def validate_entry(entry: dict[str, str]) -> list[str]:
    errors: list[str] = []
    required_fields = ("word", "level", "definition", "example", "translation")

    for field in required_fields:
        value = entry.get(field, "")
        if not isinstance(value, str) or not value.strip():
            errors.append(f"Field '{field}' is empty or missing.")

    word = entry.get("word", "").strip()
    example = entry.get("example", "")
    if word and word.lower() not in example.lower():
        errors.append(
            "Example sentence does not contain the target word."
        )

    return errors


def main() -> int:
    entries = load_entries(DATA_FILE)

    errors: list[str] = []
    seen_words: set[str] = set()

    for index, entry in enumerate(entries, start=1):
        word = entry.get("word", "").strip()
        if word.lower() in seen_words:
            errors.append(f"Duplicate entry for word '{word}' at position {index}.")
        else:
            seen_words.add(word.lower())

        for problem in validate_entry(entry):
            errors.append(f"{word or f'# {index}'}: {problem}")

    asset_entries = load_entries(ASSET_FILE)
    if entries != asset_entries:
        errors.append("Asset catalog copy is out of sync with Data/vocabulary.json.")

    if errors:
        print("Vocabulary validation failed:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(f"Validation successful: {len(entries)} entries checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
