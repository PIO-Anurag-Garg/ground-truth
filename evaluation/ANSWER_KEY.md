# Answer Key

**Do not put this file in the audit's scope.** The audit reads `corpus/app/**` and
`corpus/spec/**` only. This file exists so the audit's output can be scored after
the fact.

The corpus was built in two stages, described in `corpus/README.md`. Stage 2 planted
a deliberate maintenance changeset. Because we know exactly what was planted, the
audit's recall and precision can be measured rather than asserted.

---

## Part A — Planted changes (recall is measured against this list)

Ten findings are expected: eight rules that should come back `DRIFTED`, and two
behaviours the specification never mentions, which should come back `UNDOCUMENTED`.

| # | Change made to the code | Rationale given | Rules affected | Expected verdict |
|---|---|---|---|---|
| P1 | New validation rejects a salary below 30000 with the message `Salary below minimum band` | 2015 HR minimum-band policy | none | `UNDOCUMENTED` |
| P2 | `PHONENO` widened from 4 to 5 characters; check constraint range moved from `0000`–`9998` to `00000`–`99998`; `Phone` input field widened to 5 | Extension length change | BR-001, BR-027, BR-037 | `DRIFTED` ×3 |
| P3 | `F5=Refresh` added to the Employee List screen and its footer | Operator request | BR-018 | `DRIFTED` ×1 + `UNDOCUMENTED` ×1 |
| P4 | Department total changed from `salary + bonus + comm` to `salary` alone | 2019 reporting policy | BR-015, BR-016 | `DRIFTED` ×2 |
| P5 | Blank-check on the `Initial` field removed entirely | 2008 data-quality change | BR-029 | `DRIFTED` ×1 |
| P6 | Default education level written on insert changed from `0` to `12` | Unknown | BR-041 | `DRIFTED` ×1 |

**Planted total: 8 `DRIFTED` + 2 `UNDOCUMENTED` = 10.**

## Part B — Pre-existing defects (not planted, found by manual reading)

These were already in IBM's published sample application before any change was made.
They are not part of the recall denominator. Finding them is credit above the line.

| # | What the code actually does | Rule affected | Expected verdict |
|---|---|---|---|
| E1 | A blank `Job` field returns the message `Phone number cannot be blank` — the wrong field is named | BR-032 | `DRIFTED` |
| E2 | The generation-failure message reads `Unable to automatically generate an new ID.` — the specification quotes `a new ID` | BR-044 | `DRIFTED` |
| E3 | New employee identifiers increment by 100, not by 1 | BR-048 | `DRIFTED` |
| E4 | The insert also writes `BIRTHDATE` as the current system date; the specification's list of written values omits it entirely | BR-041 | `UNDOCUMENTED` |
| E5 | The Employee List screen has an `Opt` column and handles option `5`, which issues a debug display of the employee ID. No rule describes an option column on that screen | none | `UNDOCUMENTED` |
| E6 | `mypgm` exists in the application and is covered by no rule in the specification | none | `UNDOCUMENTED` |

**Pre-existing total: 3 `DRIFTED` + 3 `UNDOCUMENTED` = 6.**

---

## Scoring

- **Recall** = planted findings correctly identified ÷ 10
- **Precision** = correct findings ÷ all findings reported as `DRIFTED` or `UNDOCUMENTED`
- A finding not in Part A or Part B is not automatically a false positive. Check it
  by hand first — the corpus may contain defects neither stage anticipated. Record
  any such finding here before scoring.
