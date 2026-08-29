"""
locate_candidates.py  --  Build a worklist of spec-section clusters with ranked file hints.

Usage:
    python scripts/locate_candidates.py <out/rules.json> <source-root> <out/worklist.json>

Design:
  1. Cluster by SPECIFICATION SECTION.  Every rule belongs to its section's
     cluster -- nothing can be unassigned.  Sections with more than 10 rules
     are split into consecutive sub-clusters (in rule-id order).

  2. Files are ranked HINTS, never exclusive targets.  For each cluster, every
     source file is scored by two independent signals:
       a. Term score   -- how many of the cluster's extracted terms appear in the
                          file's content.
       b. Affinity score -- concept words in the rule text are mapped to file
                           extensions via a portable, project-agnostic vocabulary.
                           The extension affinity adds weight when file content
                           cannot be matched directly.
     The combined score determines ranking.  The top eight files are kept.

  3. One synthetic ORPHAN cluster is appended whose rule_ids list is empty.
     Its hint_files are every source file not already in any other cluster's
     top-eight.  Its job is to surface behaviour the specification never mentions.

  4. All paths in the output use forward slashes.
  5. A cluster with no hints is a valid, honest outcome.

Output shape  (out/worklist.json):
{
  "source_root": "corpus/app",
  "cluster_count": <int>,
  "unhinted_files": ["<files in no cluster's hints>"],
  "clusters": [
    {
      "cluster_id": "C01",
      "section": "5.4 Validation Rules",
      "rule_ids": ["BR-028", "BR-029"],
      "hint_files": ["corpus/app/qrpglesrc/newemp.pgm.sqlrpgle", "..."],
      "hint_terms": ["cannot be blank", "PHONENO"]
    }
  ]
}

Requires: standard library only
"""

import json
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Term extraction
# ---------------------------------------------------------------------------

# Verbatim error-message phrases after "message:" in spec text.
# These appear literally inside string literals in the source.
MSG_RE   = re.compile(r'message:\s*([A-Z][^.]{4,79})\.', re.I)
# ALLCAPS identifiers -- DB column names / constants (3+ uppercase chars)
UPPER_RE = re.compile(r'\b([A-Z]{3,}[A-Z0-9_]*)\b')
# F-key annotations: F3=Exit, F12=Back, etc.
FKEY_RE  = re.compile(r'\bF\d+=\w+')
# "option N" --> map to quoted digit so it matches code like: When ('5')
OPT_RE   = re.compile(r'\boption\s+(\d)', re.I)

STOP: set[str] = {
    "the", "and", "or", "a", "an", "in", "on", "of", "to", "is", "be",
    "if", "it", "no", "not", "any", "for", "by", "at", "all", "as",
    "shall", "when", "may", "this", "that", "with", "from", "its",
    "are", "was", "has", "had", "have", "been", "will", "would", "should",
    "each", "only", "also", "then", "than", "more", "one", "two", "five",
    "system", "user", "screen", "field", "value", "rule", "record",
    "enter", "press", "display", "show", "open", "new", "list",
    "following", "next", "last", "first", "br", "such", "same",
    "already", "either", "both", "able", "used", "given", "current",
    "upon", "after", "before", "while", "where", "which", "who",
    "result", "cause", "order", "time", "type",
    "left", "right", "above", "below", "within", "without",
}


def _terms(text: str) -> list[str]:
    """
    Extract search terms from a rule's plain-text string (no markdown).
    Priority order:
      1. Verbatim error-message phrases (highest signal)
      2. ALLCAPS identifiers (DB columns, constants)
      3. F-key annotations
      4. Option-digit phrases
    Returns an empty list for rules whose text has no code-searchable signal.
    That is an honest outcome; the affinity heuristic fills the gap.
    """
    seen:  set[str]  = set()
    terms: list[str] = []

    def add(t: str) -> None:
        t = t.strip()
        if t and len(t) >= 3 and t not in seen and t.lower() not in STOP:
            seen.add(t)
            terms.append(t)

    # 1. Verbatim error messages (appear literally in string literals in code)
    for m in MSG_RE.finditer(text):
        phrase = m.group(1).strip()
        if len(phrase) >= 5:
            add(phrase)

    # 2. ALLCAPS identifiers
    for m in UPPER_RE.finditer(text):
        tok = m.group(1)
        if tok.lower() not in STOP:
            add(tok)

    # 3. F-key annotations
    for m in FKEY_RE.finditer(text):
        add(m.group(0))

    # 4. Option-digit phrases
    for m in OPT_RE.finditer(text):
        add(f"'{m.group(1)}'")

    return terms


# ---------------------------------------------------------------------------
# Portable extension-affinity heuristic
#
# Concept words that appear in *any* specification are mapped to the file
# extensions most likely to implement them.  No project-specific identifier
# or file name appears anywhere in this table.
# ---------------------------------------------------------------------------

# Each entry: (word_pattern, frozenset_of_extensions, weight)
# word_pattern is matched case-insensitively against the full cluster rule text.
# weight is added to a file's affinity score when its extension matches AND the
# word is present.

_AFFINITY: list[tuple[re.Pattern, frozenset, int]] = [
    # Screen / display artefacts
    (re.compile(r'\b(screen|display(?:ed)?|column\s+header|cursor|scroll|subfile'
                r'|selection\s+column|function\s+key|labell?ed|row)\b', re.I),
     frozenset({".dspf", ".dds", ".pnlgrp"}), 2),

    # Data-definition / constraint artefacts
    (re.compile(r'\b(table|column|constraint|primary\s+key|mandatory|stored'
                r'|decimal|fixed\s+char|variable\s+char|small\s+int'
                r'|date\b|precision|nullable|references|foreign\s+key)\b', re.I),
     frozenset({".table", ".sql", ".ddl", ".dds"}), 2),

    # Stored-procedure / population artefacts
    (re.compile(r'\b(routine|procedure|proc(?:edure)?|execut(?:ed|es|ion)'
                r'|populat(?:e|ed|ion)|insert(?:ed|s)?|parameter|input\s+param'
                r'|result\s+set|nationality|random(?:ly)?|generat(?:e|ed))\b', re.I),
     frozenset({".sqlprc", ".prc", ".sql", ".proc"}), 2),

    # Program / validation logic
    (re.compile(r'\b(validat(?:e|ed|ion)|error\s+message|blank|reject(?:ed)?'
                r'|calculat(?:e|ed)|assign(?:ed)?|retriev(?:e|ed)|submit(?:ted)?'
                r'|identifier|sequen(?:ce|tial)|zero-pad(?:ded)?|left-pad(?:ded)?'
                r'|navigation|transaction|commit|rollback|insert)\b', re.I),
     frozenset({".rpgle", ".sqlrpgle", ".pgm", ".clle", ".py", ".java",
                ".ts", ".js", ".go", ".c", ".cpp"}), 1),

    # Reference / include / shared definitions
    (re.compile(r'\b(constant|definition|shared|include|prototype|reference)\b', re.I),
     frozenset({".rpgleinc", ".inc", ".h", ".hh", ".d"}), 2),
]


def _affinity_score(text_lower: str, file_ext: str) -> int:
    """
    Sum the weights of every affinity rule whose concept word appears in
    *text_lower* AND whose extension set contains *file_ext*.
    """
    total = 0
    for pattern, exts, weight in _AFFINITY:
        if file_ext in exts and pattern.search(text_lower):
            total += weight
    return total


# ---------------------------------------------------------------------------
# Source-file collection and scoring
# ---------------------------------------------------------------------------

SOURCE_EXTS: set[str] = {
    ".rpgle", ".sqlrpgle", ".rpgleinc", ".dspf",
    ".table", ".sqlprc", ".sql",
    ".py", ".js", ".ts", ".java", ".c", ".cpp", ".h", ".go",
}


def _collect_files(root: Path) -> list[Path]:
    result: list[Path] = []
    for dirpath, _dirs, filenames in os.walk(root):
        for fname in filenames:
            p = Path(dirpath) / fname
            if p.suffix.lower() in SOURCE_EXTS:
                result.append(p)
    return result


def _load_files(paths: list[Path]) -> dict[str, str]:
    """Return {str(path): content} for every readable file."""
    contents: dict[str, str] = {}
    for p in paths:
        try:
            contents[str(p)] = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            pass
    return contents


def _score_file(
    content_lower: str,
    file_ext: str,
    terms: list[str],
    cluster_text_lower: str,
) -> int:
    """
    Combined score for one file against one cluster.
      term_score     -- number of distinct hint terms found in file content
      affinity_score -- extension-affinity bonus based on concept words in rules
    """
    term_score     = sum(1 for t in terms if t.lower() in content_lower)
    affinity       = _affinity_score(cluster_text_lower, file_ext)
    return term_score + affinity


def _fwd(path_str: str) -> str:
    """Convert a path string to forward slashes."""
    return path_str.replace("\\", "/")


def _rel_fwd(path: "Path | str") -> str:
    """Relative-to-cwd path with forward slashes."""
    p = Path(path)
    try:
        return _fwd(str(p.relative_to(Path("."))))
    except ValueError:
        return _fwd(str(p))


# ---------------------------------------------------------------------------
# Clustering  (by section, split at CLUSTER_MAX rules)
# ---------------------------------------------------------------------------

CLUSTER_MAX   = 10
CANDIDATES_MAX = 200   # hard ceiling on candidate_files per cluster


def _rank_files(
    file_contents: dict[str, str],
    hint_terms: list[str],
    cluster_text_lower: str,
) -> tuple[list[str], str, int]:
    """
    Score every source file and return:
      ranked  -- all file paths ordered best-first (up to CANDIDATES_MAX)
      confidence -- "HIGH" if top score >= 2x second, else "LOW"
      dropped -- number of files cut by the CANDIDATES_MAX ceiling
    Files that score 0 are included last (tied at 0), also sorted by path for
    determinism — the full inventory is always present.
    """
    scores: dict[str, int] = {}
    for fpath, content in file_contents.items():
        ext = Path(fpath).suffix.lower()
        scores[fpath] = _score_file(content.lower(), ext, hint_terms, cluster_text_lower)

    # Sort: descending score, then ascending path for ties
    ranked_paths = sorted(scores, key=lambda f: (-scores[f], f))

    # Confidence: compare top two scores
    top_scores = sorted(scores.values(), reverse=True)
    if len(top_scores) >= 2 and top_scores[1] > 0 and top_scores[0] >= 2 * top_scores[1]:
        confidence = "HIGH"
    elif len(top_scores) >= 1 and top_scores[0] > 0 and (len(top_scores) == 1 or top_scores[1] == 0):
        confidence = "HIGH"   # only one file scored at all
    else:
        confidence = "LOW"

    total   = len(ranked_paths)
    dropped = max(0, total - CANDIDATES_MAX)
    return ranked_paths[:CANDIDATES_MAX], confidence, dropped


def _build_clusters(
    rules: list[dict],
    file_contents: dict[str, str],
) -> list[dict]:
    """
    Group rules by section, split at CLUSTER_MAX.
    Every source file is included in candidate_files, ordered best-first by
    the combined term+affinity score.  The full inventory is preserved.
    """
    section_rules: dict[str, list[dict]] = {}
    for rule in rules:
        section_rules.setdefault(rule["section"], []).append(rule)

    clusters:    list[dict] = []
    cluster_idx: int        = 1

    for section, sec_rules in section_rules.items():
        sec_rules_sorted = sorted(sec_rules, key=lambda r: int(r["id"][3:]))

        for chunk_start in range(0, len(sec_rules_sorted), CLUSTER_MAX):
            chunk    = sec_rules_sorted[chunk_start : chunk_start + CLUSTER_MAX]
            rule_ids = [r["id"] for r in chunk]

            # Deduplicated hint terms for this chunk
            seen_t:     set[str]  = set()
            hint_terms: list[str] = []
            for r in chunk:
                for t in _terms(r["text"]):
                    if t not in seen_t:
                        seen_t.add(t)
                        hint_terms.append(t)

            cluster_text_lower = " ".join(r["text"] for r in chunk).lower()

            ranked, confidence, dropped = _rank_files(
                file_contents, hint_terms, cluster_text_lower
            )

            entry: dict = {
                "cluster_id":         f"C{cluster_idx:02d}",
                "section":            section,
                "rule_ids":           rule_ids,
                "candidate_files":    [_rel_fwd(f) for f in ranked],
                "ranking_confidence": confidence,
                "hint_terms":         hint_terms[:8],
            }
            if dropped:
                entry["candidates_truncated"] = dropped
            clusters.append(entry)
            cluster_idx += 1

    return clusters


def _build_orphan(all_files: list[Path]) -> dict:
    """
    The ORPHAN cluster lists every source file (sorted by path) for use
    by the verifying agent when hunting undocumented behaviour.
    """
    return {
        "cluster_id":         "ORPHAN",
        "section":            "(none -- behaviour not described in the specification)",
        "rule_ids":           [],
        "candidate_files":    [_rel_fwd(f) for f in sorted(all_files)],
        "ranking_confidence": "LOW",
        "hint_terms":         [],
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

_NOTE = (
    "candidate_files is a best-effort ordering, not a restriction. "
    "The verifying agent must search the whole source root whenever the "
    "ordering does not lead it to the behaviour a rule describes."
)


def locate(rules_path: Path, source_root: Path, out_path: Path) -> None:
    data  = json.loads(rules_path.read_text(encoding="utf-8"))
    rules = data["rules"]

    source_files  = _collect_files(source_root)
    file_contents = _load_files(source_files)

    print(f"Loaded {len(rules)} rules, {len(source_files)} source files.")

    clusters = _build_clusters(rules, file_contents)
    orphan   = _build_orphan(source_files)
    clusters.append(orphan)

    # ── Verification: every rule_id appears exactly once ─────────────────────
    id_seen: dict[str, str] = {}
    dupes:   list[str]      = []
    for c in clusters:
        for rid in c["rule_ids"]:
            if rid in id_seen:
                dupes.append(f"{rid} in {id_seen[rid]} and {c['cluster_id']}")
            else:
                id_seen[rid] = c["cluster_id"]

    spec_ids    = {r["id"] for r in rules}
    missing_ids = sorted(spec_ids - set(id_seen.keys()), key=lambda r: int(r[3:]))

    if dupes or missing_ids:
        if dupes:
            print(f"ERROR: duplicate rule assignments: {dupes}")
        if missing_ids:
            print(f"ERROR: rules missing from clusters: {missing_ids}")
        sys.exit(1)

    print(f"Verification: all {len(spec_ids)} rule IDs appear exactly once across "
          f"{len(clusters) - 1} section clusters (+ORPHAN).")

    # ── Cluster table ─────────────────────────────────────────────────────────
    non_orphan = [c for c in clusters if c["cluster_id"] != "ORPHAN"]

    print(f"\n{'Cluster':<9} {'#':>3}  {'Conf':<5}  {'Section':<38}  Top candidate file")
    print("-" * 105)
    for c in non_orphan:
        top       = c["candidate_files"][0] if c["candidate_files"] else "(none)"
        top_short = top.split("/")[-1] if "/" in top else top
        conf      = c["ranking_confidence"]
        print(f"{c['cluster_id']:<9} {len(c['rule_ids']):>3}  {conf:<5}  {c['section']:<38}  {top_short}")

    # ── ORPHAN cluster ────────────────────────────────────────────────────────
    print(f"\nORPHAN candidate_files ({len(orphan['candidate_files'])}):")
    for f in orphan["candidate_files"]:
        print(f"  {f}")

    # ── Write JSON ────────────────────────────────────────────────────────────
    result = {
        "note":          _NOTE,
        "source_root":   _fwd(str(source_root)),
        "cluster_count": len(clusters),
        "clusters":      clusters,
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nWritten: {out_path}  ({out_path.stat().st_size:,} bytes)")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(
            "Usage: python scripts/locate_candidates.py "
            "<out/rules.json> <source-root> <out/worklist.json>"
        )
    locate(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
