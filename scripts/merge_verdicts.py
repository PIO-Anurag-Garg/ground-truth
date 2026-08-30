"""
merge_verdicts.py  –  Merge per-cluster verdict files and validate them.

Usage:
    python scripts/merge_verdicts.py <out/verdicts/> <out/rules.json> <out/drift.json>

Requires: standard library only
"""

import json
import sys
from pathlib import Path
from collections import defaultdict

# Windows consoles default to cp1252 and mangle non-ASCII in the echo.
# Output files are written as UTF-8 regardless.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

VALID_VERDICTS    = {"CONFIRMED", "DRIFTED", "UNVERIFIABLE"}
VALID_CONFIDENCES = {"HIGH", "MEDIUM", "LOW"}


def _file_line_count(path_str: str) -> int | None:
    """Return the number of lines in a file, or None if unreadable."""
    try:
        with open(path_str, encoding="utf-8", errors="replace") as fh:
            return sum(1 for _ in fh)
    except OSError:
        return None


def merge(verdicts_dir: Path, rules_path: Path, out_path: Path):
    # ── load rules ────────────────────────────────────────────────────────────
    rules_data  = json.loads(rules_path.read_text(encoding="utf-8"))
    known_ids   = {r["id"]: r for r in rules_data["rules"]}

    verdict_files = sorted(verdicts_dir.glob("*.json"))
    if not verdict_files:
        print("ERROR: no *.json files found in", verdicts_dir, file=sys.stderr)
        sys.exit(1)

    problems: list[str]  = []
    all_verdicts: list[dict] = []
    all_undocumented: list[dict] = []
    seen_rule_verdicts: dict[str, dict] = {}   # rule_id -> first verdict entry

    for vf in verdict_files:
        try:
            cluster_data = json.loads(vf.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            problems.append(f"{vf.name}: invalid JSON – {exc}")
            continue

        cluster_id = cluster_data.get("cluster_id", vf.stem)

        # ── validate verdicts ─────────────────────────────────────────────────
        for entry in cluster_data.get("verdicts", []):
            rule_id    = entry.get("rule_id", "<missing>")
            verdict    = entry.get("verdict")
            confidence = entry.get("confidence")
            citations  = entry.get("citations", [])

            # Unknown verdict value
            if verdict not in VALID_VERDICTS:
                problems.append(
                    f"{vf.name} / {rule_id}: unknown verdict {verdict!r} "
                    f"(expected one of {sorted(VALID_VERDICTS)})"
                )

            # Rule id not in rules.json
            if rule_id not in known_ids:
                problems.append(
                    f"{vf.name}: rule_id {rule_id!r} not present in rules.json"
                )

            # Conflicting verdict for same rule
            if rule_id in seen_rule_verdicts:
                prev = seen_rule_verdicts[rule_id]
                if prev.get("verdict") != verdict:
                    problems.append(
                        f"Conflicting verdicts for {rule_id}: "
                        f"{prev['verdict']!r} (cluster {prev['_cluster_id']}) "
                        f"vs {verdict!r} (cluster {cluster_id})"
                    )
            else:
                seen_rule_verdicts[rule_id] = {**entry, "_cluster_id": cluster_id}

            # DRIFTED must have at least one citation
            if verdict == "DRIFTED" and not citations:
                problems.append(
                    f"{vf.name} / {rule_id}: DRIFTED verdict has no citations"
                )

            # Citation file existence and line bounds
            for cit in citations:
                cit_file  = cit.get("file", "")
                end_line  = cit.get("end_line")
                line_count = _file_line_count(cit_file)
                if line_count is None:
                    problems.append(
                        f"{vf.name} / {rule_id}: citation file not found: {cit_file!r}"
                    )
                elif end_line is not None and end_line > line_count:
                    problems.append(
                        f"{vf.name} / {rule_id}: citation end_line {end_line} "
                        f"exceeds file length {line_count} in {cit_file!r}"
                    )

            stamped = {k: v for k, v in entry.items() if not k.startswith("_")}
            stamped["cluster_id"] = cluster_id
            all_verdicts.append(stamped)

        # ── validate undocumented ─────────────────────────────────────────────
        for entry in cluster_data.get("undocumented", []):
            verdict    = "UNDOCUMENTED"
            citations  = entry.get("citations", [])
            confidence = entry.get("confidence")

            if not citations:
                problems.append(
                    f"{vf.name} / undocumented '{entry.get('title', '?')}': "
                    f"UNDOCUMENTED finding has no citations"
                )

            for cit in citations:
                cit_file  = cit.get("file", "")
                end_line  = cit.get("end_line")
                line_count = _file_line_count(cit_file)
                if line_count is None:
                    problems.append(
                        f"{vf.name} / undocumented: citation file not found: {cit_file!r}"
                    )
                elif end_line is not None and end_line > line_count:
                    problems.append(
                        f"{vf.name} / undocumented: citation end_line {end_line} "
                        f"exceeds file length {line_count} in {cit_file!r}"
                    )

            stamped = {**entry, "cluster_id": cluster_id}
            all_undocumented.append(stamped)

    # ── rules with no verdict → MISSING_VERDICT ───────────────────────────────
    missing: list[dict] = []
    for rule_id, rule in known_ids.items():
        if rule_id not in seen_rule_verdicts:
            missing.append({
                "rule_id":    rule_id,
                "verdict":    "MISSING_VERDICT",
                "section":    rule["section"],
                "text":       rule["text"],
            })

    # -- report problems -------------------------------------------------------
    if problems:
        print(f"\n{'-'*60}")
        print(f"VALIDATION PROBLEMS ({len(problems)}):")
        for p in problems:
            print(f"  * {p}")
        print(f"{'-'*60}\n")
    else:
        print("Validation: OK - no problems found.")

    # ── summary counts ────────────────────────────────────────────────────────
    verdict_counts: dict[str, int] = defaultdict(int)
    confidence_counts: dict[str, int] = defaultdict(int)
    file_counts: dict[str, int] = defaultdict(int)

    for v in all_verdicts:
        verdict_counts[v.get("verdict", "?")] += 1
        confidence_counts[v.get("confidence", "?")] += 1
        for cit in v.get("citations", []):
            file_counts[cit.get("file", "?")] += 1

    verdict_counts["UNDOCUMENTED"]     = len(all_undocumented)
    verdict_counts["MISSING_VERDICT"]  = len(missing)

    summary = {
        "total_rules":         len(known_ids),
        "total_verdicts":      len(all_verdicts),
        "total_undocumented":  len(all_undocumented),
        "total_missing":       len(missing),
        "validation_problems": len(problems),
        "by_verdict":          dict(verdict_counts),
        "by_confidence":       dict(confidence_counts),
        "by_file":             dict(file_counts),
    }

    drift = {
        "summary":       summary,
        "verdicts":      all_verdicts,
        "undocumented":  all_undocumented,
        "missing":       missing,
        "problems":      problems,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(drift, indent=2), encoding="utf-8")
    print(f"Written: {out_path}")
    print(f"Summary: {dict(verdict_counts)}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(
            "Usage: python scripts/merge_verdicts.py "
            "<out/verdicts/> <out/rules.json> <out/drift.json>"
        )
        sys.exit(1)
    merge(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
