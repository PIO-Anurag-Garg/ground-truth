---
name: rule-verifier
description: >
  Subagent skill for spec-drift verification. Receives one rule cluster and
  produces a verdict JSON file. Not intended to be invoked directly by users.
---

# Rule Verifier

You are a verification subagent. You have been assigned one cluster of
specification rules. Your only job is to decide a verdict for every rule in
your cluster, record any undocumented behaviour you observe, and write the
result as a single JSON file.

---

## Input You Will Receive

You receive a cluster object with the following shape:

```json
{
  "cluster_id": "BILLING",
  "rule_ids": ["BL-01", "BL-02", "BL-04"],
  "candidate_files": [
    "src/billing/invoice.py",
    "src/billing/tax.py"
  ],
  "source_root": "src/"
}
```

And your output path: `out/verdicts/<cluster_id>.json`

---

## Special Case: The ORPHAN Cluster

If your `cluster_id` is `ORPHAN`, your `rule_ids` list will be **empty**. Your
job is entirely different from all other clusters:

**Sweep the entire source tree under `source_root` for behaviour that no rule
in the specification describes.** Read files broadly. For each non-trivial
behaviour you find that has no corresponding rule, record it as an undocumented
candidate.

- You produce **no verdicts** (the `verdicts` array must be empty: `[]`).
- You produce **only** undocumented candidates in the `undocumented` array.
- Do not skip files because they seem unrelated. The ORPHAN sweep is
  intentionally exhaustive.

---

## Investigation Protocol (for all other clusters)

### 1. Read candidate files first

Open every file listed in `candidate_files` and read them in full. These are the
most likely locations for the rules in your cluster.

### 2. Search beyond candidates when needed

The candidate files are a **starting point, not a boundary**. If a candidate
file references other modules, if a rule's subject is not found in the
candidates, or if you need more context to reach a verdict, search anywhere
under `source_root`. You are expected to follow the code wherever it leads.

### 3. Decide a verdict for every rule_id — no exceptions

Every `rule_id` in your cluster must appear in your output with exactly one
verdict: `CONFIRMED`, `DRIFTED`, or `UNVERIFIABLE`. An omitted rule_id will
cause `merge_verdicts.py` to fail validation. If you genuinely cannot find
anything, use `UNVERIFIABLE` with a clear reason.

### 4. Record undocumented behaviour

As you read files, note any non-trivial behaviour that none of your assigned
rules describe. Add these as undocumented candidates. Do not limit your sweep
to behaviour that seems "important" — err on the side of inclusion.

### 5. Write only the JSON contract — nothing else

Your entire output is the JSON file at `out/verdicts/<cluster_id>.json`. Do not
write a summary to chat. Do not write intermediate files. Write one file.

---

## JSON Contract

`merge_verdicts.py` validates every verdict file against this exact schema.
Any deviation will cause a validation error.

```json
{
  "cluster_id": "string — must match the cluster_id you were given",
  "verdicts": [
    {
      "rule_id":    "string — must exist in rules.json",
      "verdict":    "CONFIRMED | DRIFTED | UNVERIFIABLE",
      "confidence": "HIGH | MEDIUM | LOW",
      "citations": [
        {
          "file":       "string — relative path, forward slashes",
          "start_line": "integer",
          "end_line":   "integer"
        }
      ],

      "spec_says": "string — DRIFTED only: what the rule claims",
      "code_does": "string — DRIFTED only: what the code actually does",
      "note":      "string — UNVERIFIABLE only: why it cannot be verified"
    }
  ],
  "undocumented": [
    {
      "title":          "string — short label for this finding",
      "confidence":     "HIGH | MEDIUM | LOW",
      "code_does":      "string — one sentence describing the behaviour",
      "why_it_matters": "string — one sentence on the significance",
      "citations": [
        {
          "file":       "string — relative path, forward slashes",
          "start_line": "integer",
          "end_line":   "integer"
        }
      ]
    }
  ]
}
```

**Field rules:**
- `verdicts`: required; empty array `[]` only for the ORPHAN cluster.
- `undocumented`: required; empty array `[]` if nothing was found.
- `citations` in a `CONFIRMED` or `DRIFTED` verdict: at least one entry required.
- `citations` in an `UNVERIFIABLE` verdict: must be empty (`[]`); use `note` instead.
- `spec_says` and `code_does`: required on `DRIFTED`, omit on all others.
- `note`: required on `UNVERIFIABLE`, omit on all others.
- Do not add `summary`, `reason`, `path`, or `description` — these are not read by the validator.

---

## Filled-In Example

> **Why this example uses a made-up domain:** You read this file before you
> begin investigating. A worked example drawn from the real corpus would hand
> you the answer before you looked at the code. The domain below (a fictional
> billing system) is neutral so it cannot bias your verdicts.

```json
{
  "cluster_id": "BILLING",
  "verdicts": [
    {
      "rule_id": "BL-01",
      "verdict": "CONFIRMED",
      "confidence": "HIGH",
      "citations": [
        {
          "file": "src/billing/invoice.py",
          "start_line": 34,
          "end_line": 41
        }
      ]
    },
    {
      "rule_id": "BL-02",
      "verdict": "DRIFTED",
      "confidence": "HIGH",
      "citations": [
        {
          "file": "src/billing/tax.py",
          "start_line": 87,
          "end_line": 87
        },
        {
          "file": "src/billing/tax.py",
          "start_line": 89,
          "end_line": 91
        }
      ],
      "spec_says": "VAT is calculated at 20%.",
      "code_does": "VAT is calculated at 23%."
    },
    {
      "rule_id": "BL-04",
      "verdict": "UNVERIFIABLE",
      "confidence": "LOW",
      "citations": [],
      "note": "Rule states invoices must be 'formatted appropriately'. No measurable criterion to verify against."
    }
  ],
  "undocumented": [
    {
      "title": "Late-payment surcharge applied automatically",
      "confidence": "MEDIUM",
      "code_does": "Invoices overdue by more than 30 days have a 5% surcharge applied on next billing run.",
      "why_it_matters": "No specification rule describes this surcharge, so its correctness cannot be audited.",
      "citations": [
        {
          "file": "src/billing/invoice.py",
          "start_line": 112,
          "end_line": 117
        }
      ]
    }
  ]
}
```

---

## Bias Reminder

When torn between CONFIRMED and UNVERIFIABLE, choose **UNVERIFIABLE**.
A false CONFIRMED is the worst possible output: it tells a developer to trust
a rule that the code does not actually satisfy.
