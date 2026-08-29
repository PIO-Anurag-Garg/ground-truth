---
name: spec-drift
description: >
  Audit the specification against the codebase. Triggers on "audit the spec",
  "spec drift", "does the code still match the documentation", "verify the spec".
---

# Spec-Drift Audit Skill

You are conducting a formal specification-drift audit. Follow the nine steps
below **in order**. Never re-order, skip, or merge steps. Never skip a GATE.

---

## Before Step 1 — Document Identification

Read the `.docx` file directly and state, in the chat:

- Document title
- Version (if present)
- Date (if present)

This confirms to the operator that the correct document entered the pipeline.

---

## Step 1 — Extract Rules `[DETERMINISTIC]`

Run:

```
python scripts/extract_rules.py <spec_file> --out out/rules.json
```

`extract_rules.py` parses the `.docx`, assigns a stable `rule_id` to every
normative statement, and writes `out/rules.json`. **This step consumes no model
tokens.**

---

## Step 2 — Rule-Count Confirmation `[GATE]`

Report to the user:

- Total rule count
- Section breakdown (section heading → rule count)
- The first 5 rule texts as a sanity sample

**STOP. Ask the user: "Does this look correct? Proceed with the audit?"**
Do not advance to Step 3 until the user explicitly approves.

---

## Step 3 — Build Worklist `[DETERMINISTIC]`

Run:

```
python scripts/locate_candidates.py out/rules.json <source_root> --out out/worklist.json
```

`locate_candidates.py` clusters rules by subsystem, assigns hint files to each
cluster, and produces `out/worklist.json`. **This step consumes no model tokens.**

The worklist contains one special cluster whose `cluster_id` is `ORPHAN`. It
carries an **empty `rule_ids` list**. Its job is different from all other
clusters: it sweeps the entire source tree for behaviour that no rule in the
specification describes, and reports everything it finds as undocumented
candidates. It returns **no verdicts**.

---

## Step 4 — Parallel Verification `[AI]`

For every cluster in `out/worklist.json`, spawn one subagent **in parallel**.
Each subagent uses the **rule-verifier** skill and writes its output to
`out/verdicts/<cluster_id>.json`.

Pass each subagent:
- Its cluster object (from worklist.json)
- The `source_root`
- The path `out/verdicts/<cluster_id>.json` as its output target

Wait for **all** subagents to complete before proceeding.

---

## Step 5 — Merge Verdicts `[DETERMINISTIC]`

Run:

```
python scripts/merge_verdicts.py out/verdicts/ --out out/drift.json
```

`merge_verdicts.py` validates every verdict file against the JSON contract,
checks that every `rule_id` from `out/rules.json` has exactly one verdict, and
merges into `out/drift.json`. **This step consumes no model tokens.**

If validation fails, show the operator the specific errors and stop. Do not
attempt to silently fix invalid verdict files.

---

## Step 6 — Findings Review `[GATE]`

From `out/drift.json`, display to the user:

1. **All DRIFTED findings** — rule text, what the code does instead, citations
2. **All UNDOCUMENTED findings** — behaviour description, citations
3. Counts by verdict: CONFIRMED / DRIFTED / UNVERIFIABLE / UNDOCUMENTED

**STOP. Ask the user: "Do these findings look correct? Approve to generate
output documents."**
Do not advance to Step 7 until the user explicitly approves.

---

## Step 7 — Write Correction Documents `[AI]`

Write two files:

**`out/SPEC_CORRECTED.md`** — for every DRIFTED rule, write a corrected rule
text that matches what the code actually does. Preserve the original rule_id.
Mark each correction with the citations that justify it.

**`out/UNDOCUMENTED.md`** — for every UNDOCUMENTED finding, write a candidate
specification statement that would cover the observed behaviour. Include
citations.

---

## Step 8 — Render Report `[DETERMINISTIC]`

Run:

```
python scripts/build_report.py out/drift.json --md out/DRIFT_REPORT.md --xlsx out/drift.xlsx
```

`build_report.py` renders the full audit report in Markdown and Excel.
**This step consumes no model tokens.**

---

## Step 9 — Generate Test Stubs `[AI]`

For every rule whose verdict is CONFIRMED, generate a test-case stub in
`out/tests/`. Each stub must:

- Reference the `rule_id` in a comment
- Assert the behaviour the rule describes
- Be written in the test framework already present in the repository

---

## Step Labels

| Label | Meaning |
|---|---|
| `DETERMINISTIC` | Runs a script; consumes no model tokens |
| `AI` | Requires model reasoning |
| `GATE` | Hard stop; requires explicit user approval before proceeding |
