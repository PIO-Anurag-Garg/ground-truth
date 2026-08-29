# Gate 6 — the findings review

The audit stops here and will not continue without a human approval. These two
screenshots are that moment, taken live before anything was approved.

| | |
|---|---|
| ![the drifted findings](gate6-findings.png) | The eleven DRIFTED rules as Bob presented them, each with what the specification says, what the code actually does, and a file and line citation. |
| ![the summary and approval](gate6-approval.png) | The verdict summary, the gate question, and the approval that released steps 7 to 9. |

Full transcript: [session 04](04-drift-corpus-spec-functional-spec-docx-corpus-ap.md),
"Step 6 — Findings Review".

## Why these counts differ from the README

The screenshots show the audit's raw output at the moment of the gate. The README
reports the figures after two later steps. Both are correct; neither was adjusted
to look better.

| | At the gate | In the README | What changed |
|---|---|---|---|
| CONFIRMED | 64 | 63 | BR-074 was downgraded |
| UNVERIFIABLE | 0 | 1 | BR-074 became UNVERIFIABLE |
| DRIFTED | 11 | 11 | unchanged |
| UNDOCUMENTED | 125 | 32 | de-duplicated |

**BR-074** moved after the gate because a separate adversarial pass challenged a
seeded random sample of CONFIRMED verdicts and refuted this one. The rule asserts
that no facility exists for modifying or deleting records. A full-corpus search
finds no such code, so the absence appears genuine — but absence cannot be proven
by citation, and a CONFIRMED verdict requires citable evidence. UNVERIFIABLE is
the correct verdict. The reasoning is in [`out/REDTEAM.md`](../out/REDTEAM.md) and
the correction was applied to the source verdict file, then re-merged, so the
report was regenerated rather than hand-edited.

**125 became 32** because 125 is the raw candidate count across all 23 verification
subagents, working independently with clean contexts. Several noticed the same
behaviour, so the same finding was reported more than once. 32 is the count after
de-duplication. Both numbers appear in the README, because publishing only the
smaller one would overstate precision.
