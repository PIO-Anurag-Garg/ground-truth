# /drift — Spec-Drift Audit

Invokes the **spec-drift** skill against a specification document and a source
root.

## Usage

```
/drift <spec_file> <source_root>
```

## Arguments

| Argument | Description |
|---|---|
| `spec_file` | Path to the specification `.docx` file |
| `source_root` | Path to the root of the codebase to audit |

## Examples

```
/drift docs/specifications/MyProduct_v2.3.docx src/
/drift specs/API_Spec_v1.0.docx .
```

## What It Does

Runs the full nine-step spec-drift audit as defined in the **spec-drift** skill:

1. Identifies the document (title, version, date)
2. Extracts and counts rules — **pauses for your approval**
3. Builds a verification worklist
4. Spawns parallel subagents to verify each rule cluster
5. Merges all verdicts into `out/drift.json`
6. Shows all DRIFTED and UNDOCUMENTED findings — **pauses for your approval**
7. Writes `out/SPEC_CORRECTED.md` and `out/UNDOCUMENTED.md`
8. Renders `out/DRIFT_REPORT.md` and `out/drift.xlsx`
9. Generates test stubs in `out/tests/`

The audit contains two hard-stop gates (steps 2 and 6) that require explicit
approval before proceeding. The audit will never skip a gate.

## Output Files

| File | Contents |
|---|---|
| `out/rules.json` | All extracted rules |
| `out/worklist.json` | Rule clusters with hint files |
| `out/verdicts/<cluster_id>.json` | Per-cluster verdict files |
| `out/drift.json` | Merged audit results |
| `out/SPEC_CORRECTED.md` | Corrected rule text for all DRIFTED rules |
| `out/UNDOCUMENTED.md` | Candidate spec statements for undocumented behaviour |
| `out/DRIFT_REPORT.md` | Full audit report (Markdown) |
| `out/drift.xlsx` | Full audit report (Excel) |
| `out/tests/` | Test stubs for all CONFIRMED rules |
