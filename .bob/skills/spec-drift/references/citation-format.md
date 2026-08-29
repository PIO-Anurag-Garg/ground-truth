# Citation Format

Every DRIFTED, CONFIRMED, and UNDOCUMENTED finding **must carry at least one
citation**. UNVERIFIABLE findings carry a reason instead (see below).

---

## What a Citation Is

A citation is a precise pointer to source code that the verifier **actually
read**. It consists of three parts:

```
<relative_path>:<start_line>-<end_line>
```

Examples:
- `src/billing/invoice.py:34-41`
- `src/payments/processor.go:214-230`
- `lib/core/config.ts:12-12`

All three parts are required. A bare filename with no line range is not a valid
citation.

---

## Rules

### 1. Only cite lines you actually read.

Never cite a file or line range you inferred from a name, a directory structure,
or a comment elsewhere. If you have not opened the file and read those specific
lines, you cannot cite them.

### 2. Never paraphrase code in place of a citation.

Describing what code "probably does" or reproducing code from memory is not a
citation. The citation is the pointer; the verdict text explains what those lines
mean.

### 3. If you cannot cite it, the verdict is UNVERIFIABLE.

If you believe a rule is satisfied but cannot find the specific lines that prove
it, you must record the verdict as UNVERIFIABLE, not CONFIRMED. Confidence
without evidence is not a citation.

### 4. Multiple citations are allowed and encouraged.

A single rule may be implemented across several files. List every relevant
citation. There is no upper limit.

### 5. UNVERIFIABLE findings carry a note, not a citation.

When a rule cannot be verified, the `citations` array must be empty (`[]`) and
the `note` field must explain why: vague rule text, subject not found in tree,
etc.

---

## Citation Object (JSON)

In the verdict JSON, a citation is an object:

```json
{
  "file": "src/billing/invoice.py",
  "start_line": 34,
  "end_line": 41
}
```

Exactly three keys: `file`, `start_line`, `end_line`. Do not add any other keys.
`file` must use forward slashes regardless of operating system.

---

## Examples

### CONFIRMED — single citation

```json
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
}
```

### DRIFTED — two citations

```json
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
}
```

### UNVERIFIABLE — no citation

```json
{
  "rule_id": "BL-04",
  "verdict": "UNVERIFIABLE",
  "confidence": "LOW",
  "citations": [],
  "note": "Rule states invoices must be 'formatted appropriately'. No measurable criterion to verify against."
}
```

### UNDOCUMENTED — citation required

```json
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
```
