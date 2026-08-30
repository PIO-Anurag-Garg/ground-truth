"""
extract_rules.py  –  Extract BR-nnn business rules from a .docx file.

Usage:
    python scripts/extract_rules.py <spec.docx> <out/rules.json>

Requires: python-docx
"""

import json
import re
import sys
from pathlib import Path

from docx import Document

# Windows consoles default to cp1252 and mangle non-ASCII in the echo.
# Output files are written as UTF-8 regardless.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

RULE_ID_RE = re.compile(r"^BR-(\d{3})\.")


def extract(docx_path: Path, out_path: Path):
    doc = Document(str(docx_path))

    rules        = []
    current_section = "(preamble)"
    seen_ids     = {}   # id -> paragraph_index
    errors       = []

    for idx, para in enumerate(doc.paragraphs):
        text = para.text.strip()
        if not text:
            continue

        # Detect headings by style name
        style_name = para.style.name if para.style else ""
        if style_name.startswith("Heading"):
            # strip leading/trailing whitespace and normalise
            current_section = text
            continue

        # Check for rule identifier at start of text
        m = RULE_ID_RE.match(text)
        if m:
            rule_id = f"BR-{m.group(1)}"

            # Duplicate check
            if rule_id in seen_ids:
                errors.append(
                    f"DUPLICATE rule id {rule_id}: "
                    f"paragraph {seen_ids[rule_id]} and {idx}"
                )
            else:
                seen_ids[rule_id] = idx

            # Strip the "BR-nnn.  " prefix from the text
            rule_text = RULE_ID_RE.sub("", text).strip().lstrip(". ").strip()

            rules.append({
                "id":              rule_id,
                "section":         current_section,
                "text":            rule_text,
                "paragraph_index": idx,
            })

    # ── sequence / gap check ──────────────────────────────────────────────────
    found_nums = sorted(int(r["id"][3:]) for r in rules)
    if found_nums:
        expected = list(range(found_nums[0], found_nums[-1] + 1))
        missing  = sorted(set(expected) - set(found_nums))
        if missing:
            errors.append(
                "GAP in rule sequence – missing ids: "
                + ", ".join(f"BR-{n:03d}" for n in missing)
            )

    # Report all errors, but still write valid output
    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        print(
            f"\nFound {len(rules)} rules; {len(errors)} problem(s) detected.",
            file=sys.stderr,
        )
    else:
        print(f"OK – {len(rules)} rules extracted, no duplicates or gaps.")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    result = {
        "spec_file":   str(docx_path),
        "rule_count":  len(rules),
        "rules":       rules,
    }
    out_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Written: {out_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python scripts/extract_rules.py <spec.docx> <out/rules.json>")
        sys.exit(1)
    extract(Path(sys.argv[1]), Path(sys.argv[2]))
